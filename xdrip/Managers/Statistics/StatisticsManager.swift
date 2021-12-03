//
//  StatisticsManager.swift
//  xdrip
//
//  Created by Paul Plant on 26/04/21.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import Foundation
import CoreData

public final class StatisticsManager {
    
    // MARK: - private properties
    
    /// BgReadingsAccessor instance
    private var bgReadingsAccessor:BgReadingsAccessor
    
    /// used for calculating statistics on a background thread
    private let operationQueue: OperationQueue
        
    // MARK: - intializer
    
    init() {
        bgReadingsAccessor = BgReadingsAccessor()

        // initialize operationQueue
        operationQueue = OperationQueue()
        
        // operationQueue will be queue of blocks that gets readings and updates glucoseChartPoints, startDate and endDate. To avoid race condition, the operations should be one after the other
        operationQueue.maxConcurrentOperationCount = 1
        
    }
    
    // MARK: - public functions
    
    /// calculates statistics, will execute in background.
    /// - parameters:
    ///     - callback : will be called with result of calculations in UI thread
    func calculateStatistics(fromDate: Date, toDate: Date? = Date(), callback: @escaping (Statistics) -> Void) {
        
        // create a new operation
        let operation = BlockOperation(block: {
            
            // if there's more than one operation waiting for execution, it makes no sense to execute this one
            guard self.operationQueue.operations.count <= 1 else {
                return
            }
            
            // declare variables/constants
            let isMgDl: Bool = UserDefaults.standard.bloodGlucoseUnitIsMgDl
            var glucoseValues: [Double] = []
            
            // declare return variables
            var lowStatisticValue: Double = 0
            var highStatisticValue: Double = 0
            var inRangeStatisticValue: Double?
            var averageStatisticValue: Double?
            var a1CStatisticValue: Double?
            var cVStatisticValue: Double?
            var lowLimitForTIR: Double = 0
            var highLimitForTIR: Double = 0
            var numberOfDaysUsed: Int?
            var readingsCount: Int?
            var stdDeviation: Double?
			var gviStatisticValue: Double?
			var pgsStatisticValue: Double?

            CoreDataManager.shared.privateManagedObjectContext.performAndWait {

                // lets get the readings from the bgReadingsAccessor
                let readings = self.bgReadingsAccessor.getBgReadings(from: fromDate, to: toDate, on:  CoreDataManager.shared.privateManagedObjectContext)
                
                //if there are no available readings, return without doing anything
                if readings.count == 0 {
                    return
                }
                
                readingsCount = readings.count
                
                // let's calculate the actual first day of readings in bgReadings. Although the user wants to use 60 days to calculate, maybe we only have 4 days of data. This will be returned from the method and used in the UI. To ensure we calculate the whole days used, we should subtract 5 minutes from the fromDate
                numberOfDaysUsed = Calendar.current.dateComponents([.day], from: readings.first!.timeStamp - 5 * 60, to: Date()).day!
                
                // get the minimum time between readings (convert to seconds). This is to avoid getting too many extra 60-second readings from the Libre 2 Direct - they will take up a lot more processing time and don't add anything to the accuracy of the results so we'll just filter them out if they exist.
                let minimumSecondsBetweenReadings: Double = ConstantsStatistics.minimumFilterTimeBetweenReadings * 60
                
                // get the timestamp of the first reading
                let firstValueTimeStamp = readings.first?.timeStamp
                var previousValueTimeStamp = firstValueTimeStamp
                
                // add filter values to ensure that any clearly invalid glucose data is not included into the array and used in the calculations
                let minValidReading: Double = ConstantsGlucoseChart.absoluteMinimumChartValueInMgdl
                let maxValidReading: Double = 450
                
                // step though all values, check them for validity, convert if necessary and append them to the glucoseValues array
                for reading in readings {
                    
                    // declare and initialise the date variables needed
                    var calculatedValue = reading.calculatedValue
                    let currentTimeStamp = reading.timeStamp
                    
                    if (calculatedValue != 0.0) && (calculatedValue >= minValidReading) && (calculatedValue <= maxValidReading) {
                        
                        // get the difference between the previous value's timestamp and the new one
                        let secondsDifference = Calendar.current.dateComponents([.second], from: previousValueTimeStamp!, to: currentTimeStamp)
                        
                        //if the current values timestamp is more than the minimum filter time, then add it to the glucoseValues array. Include a check to ensure that the first reading is added despite there not being any difference to itself
                        if (Double(secondsDifference.second!) >= minimumSecondsBetweenReadings) || (previousValueTimeStamp == firstValueTimeStamp) {
                            
                            if !isMgDl {
                                calculatedValue = calculatedValue * ConstantsBloodGlucose.mgDlToMmoll
                            }
                            
                            glucoseValues.append(calculatedValue)
                            
                            // update the timestamp for the next loop
                            previousValueTimeStamp = currentTimeStamp
                            
                        }
                        
                    }
                }
                
                
                // let's set up the which values will finally be used to calculate TIR. It can be either user-specified or the standardised values
                if UserDefaults.standard.useStandardStatisticsRange {
                    if isMgDl {
                        lowLimitForTIR = ConstantsStatistics.standardisedLowValueForTIRInMgDl
                        highLimitForTIR = ConstantsStatistics.standardisedHighValueForTIRInMgDl
                    } else {
                        lowLimitForTIR = ConstantsStatistics.standardisedLowValueForTIRInMmol
                        highLimitForTIR = ConstantsStatistics.standardisedHighValueForTIRInMmol
                    }
                } else {
                    lowLimitForTIR = UserDefaults.standard.lowMarkValueInUserChosenUnit
                    highLimitForTIR = UserDefaults.standard.highMarkValueInUserChosenUnit
                }
                
                // make sure that there exist elements in the glucoseValue array before trying to process statistics calculations or we could get a fatal divide by zero error/crash
                if glucoseValues.count > 0 {
                    
                    // calculate low %
                    lowStatisticValue = Double((glucoseValues.lazy.filter { $0 < lowLimitForTIR }.count * 200) / (glucoseValues.count * 2))
                
                
                    // calculate high %
                    highStatisticValue = Double((glucoseValues.lazy.filter { $0 > highLimitForTIR }.count * 200) / (glucoseValues.count * 2))
                    
                    
                    // calculate TIR % (let's be lazy and just subtract the other two values from 100)
                    inRangeStatisticValue = 100 - lowStatisticValue - highStatisticValue
                    
                    
                    // calculate average glucose value
                    averageStatisticValue = Double(glucoseValues.reduce(0, +)) / Double(glucoseValues.count)
                
                    
                    // calculate an estimated HbA1C value using either IFCC (e.g 49 mmol/mol) or NGSP (e.g 5.8%) methods: http://www.ngsp.org/ifccngsp.asp
                    if UserDefaults.standard.useIFCCA1C {
                        a1CStatisticValue = (((46.7 + Double(isMgDl ? averageStatisticValue! : (averageStatisticValue! / ConstantsBloodGlucose.mgDlToMmoll))) / 28.7) - 2.152) / 0.09148
                    } else {
                        a1CStatisticValue = (46.7 + Double(isMgDl ? averageStatisticValue! : (averageStatisticValue! / ConstantsBloodGlucose.mgDlToMmoll))) / 28.7
                    }
                    
                    
                    // calculate standard deviation
                    var sum: Double = 0;
                    
                    for glucoseValue in glucoseValues {
                        sum += (Double(glucoseValue.value) - averageStatisticValue!) * (Double(glucoseValue.value) - averageStatisticValue!)
                    }
                    
                    stdDeviation = sqrt(sum / Double(glucoseValues.count))
                    
                    
                    // calculate Coeffecient of Variation
                    cVStatisticValue = ((stdDeviation!) / averageStatisticValue!) * 100
                
					// https://web.archive.org/web/20160523152519/http://www.healthline.com/diabetesmine/a-new-view-of-glycemic-variability-how-long-is-your-line#2
					// x轴单位为分钟，y轴单位为mg/dL
					func gvi(data: [BgReading]) -> Double {
						guard data.count > 1 else {
							return Double(data.count)
						}
                        
						var L: Double = 0
						let L0: Double = abs(data.first!.timeStamp.timeIntervalSince(data.last!.timeStamp)/60)
						
						var lastItem = data.first!
						for i in 1 ..< data.count {
							let current = data[i]
							let timeInterval = current.timeStamp.timeIntervalSince(lastItem.timeStamp)
                            
                            // filter readings having 5 miniuts interval
                            if abs(timeInterval) >= (4.5 * Date.minuteInSeconds) {
								let dx = timeInterval / 60 // 单位分钟
								let dy = current.calculatedValue - lastItem.calculatedValue
								L +=  sqrt(pow(dx, 2) + pow(dy, 2))
								lastItem = current
							}
						}
						return L / L0
					}
					gviStatisticValue = gvi(data: readings)
					if inRangeStatisticValue == 100 {
						pgsStatisticValue = 0
                        
					} else {
						pgsStatisticValue = gviStatisticValue! * averageStatisticValue! * (isMgDl ? 1 : ConstantsBloodGlucose.mmollToMgdl ) * (1 - inRangeStatisticValue!/100)
					}
                }
            }
            
            // call callback in main thread, this callback will only update the UI when the user hasn't requested more statistics updates in the meantime (this will only apply if they are reaaaallly quick at tapping the segmented control)
            if self.operationQueue.operations.count <= 1 {
                DispatchQueue.main.async {
                    callback(Statistics(lowStatisticValue: lowStatisticValue,
                                        highStatisticValue: highStatisticValue,
                                        inRangeStatisticValue: inRangeStatisticValue,
                                        averageStatisticValue: averageStatisticValue,
                                        a1CStatisticValue: a1CStatisticValue,
                                        cVStatisticValue: cVStatisticValue,
                                        lowLimitForTIR: lowLimitForTIR,
                                        highLimitForTIR: highLimitForTIR,
                                        numberOfDaysUsed: numberOfDaysUsed,
                                        readingsCount: readingsCount,
                                        stdDeviation: stdDeviation,
										gviStatisticValue: gviStatisticValue,
										pgsStatisticValue: pgsStatisticValue))
                }
            }
        })
        
        // add the operation to the queue and start it. As maxConcurrentOperationCount = 1, it may be kept until a previous operation has finished
        operationQueue.addOperation {
            operation.start()
        }
    }
    
    /// can store rresult off calculations in calculateStatistics,  to be used in UI
    struct Statistics {
        
        var lowStatisticValue: Double?
        var highStatisticValue: Double?
        var inRangeStatisticValue: Double?
        var averageStatisticValue: Double?
        var a1CStatisticValue: Double?
        var cVStatisticValue: Double?
        var lowLimitForTIR: Double?
        var highLimitForTIR: Double?
        var numberOfDaysUsed: Int?
        var readingsCount: Int?
        var stdDeviation: Double?
		var gviStatisticValue: Double?
		var pgsStatisticValue: Double?
    }
     
}

