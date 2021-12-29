import Foundation
import CoreData
import UIKit

public class BgReading: NSManagedObject {

    private static let log = Log(type: BgReading.self)
    
    /// creates BgReading with given parameters.
    ///
    /// properties that are not in the parameter list get either value 0 or false (depending on type). id gets new value
    init(
        timeStamp:Date,
        sensor:Sensor?,
        calibration:Calibration?,
        rawData:Double,
        deviceName:String?,
        nsManagedObjectContext:NSManagedObjectContext
    ) {
        let entity = NSEntityDescription.entity(forEntityName: "BgReading", in: nsManagedObjectContext)!
        super.init(entity: entity, insertInto: nsManagedObjectContext)
        self.timeStamp = timeStamp
        self.sensor = sensor
        self.calibration = calibration
        self.rawData = rawData
        self.deviceName = deviceName
        
        ageAdjustedRawValue = 0
        calibrationFlag = false
        calculatedValue = 0
        calculatedValueSlope = 0
        a = 0
        b = 0
        c = 0
        ra = 0
        rb = 0
        rc = 0 
        hideSlope = false
        id = UniqueId.createEventId()
    }

    private override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    /// log the contents to a string
    func print(_ indentation: String) -> String {
        var r:String = "bgreading = "
        r += "\n" + indentation + "timestamp = " + timeStamp.description + "\n"
        r += "\n" + indentation + "uniqueid = " + id
        r += "\n" + indentation + "a = " + a.description
        r += "\n" + indentation + "ageAdjustedRawValue = " + ageAdjustedRawValue.description
        r += "\n" + indentation + "b = " + b.description
        r += "\n" + indentation + "c = " + c.description
        r += "\n" + indentation + "calculatedValue = " + calculatedValue.description
        r += "\n" + indentation + "calculatedValueSlope = " + calculatedValueSlope.description
        if let calibration = calibration {
            r += "\n" + indentation + "calibration = " + calibration.log("      ")
        }
        r += "\n" + indentation + "calibrationFlag = " + calibrationFlag.description
        r += "\n" + indentation + "hideSlope = " + hideSlope.description
        r += "\n" + indentation + "ra = " + ra.description
        r += "\n" + indentation + "rawData = " + rawData.description
        r += "\n" + indentation + "rb = " + rb.description
        r += "\n" + indentation + "rc = " + rc.description
        if let sensor = sensor {
            r += "\n" + indentation + "sensor = " + sensor.log(indentation: "      ")
        }
        return r
    }
    
    var slopArrow: SlopeArrow {
        var arrow: SlopeArrow
        let slopeByMinute = calculatedValueSlope * 60000
        if slopeByMinute <= -3.5 {
            arrow = SlopeArrow.doubleDown
        } else if slopeByMinute <= -2 {
            arrow = SlopeArrow.singleDown
        } else if slopeByMinute <= -1 {
            arrow = SlopeArrow.fortyFiveDown
        } else if slopeByMinute <= 1 {
            arrow = SlopeArrow.flat
        } else if slopeByMinute <= 2 {
            arrow = SlopeArrow.fortyFiveUp
        } else if slopeByMinute <= 3.5 {
            arrow = SlopeArrow.singleUp
        } else {
            arrow = SlopeArrow.doubleUp
        }
        return arrow
    }
    
    func slopeArrow() -> String {
        let slopeByMinute = calculatedValueSlope * 60000
        if (slopeByMinute <= (-3.5)) {
            return "\u{2193}\u{2193}"
        } else if (slopeByMinute <= (-2)) {
            return "\u{2193}"
        } else if (slopeByMinute <= (-1)) {
            return "\u{2198}"
        } else if (slopeByMinute <= (1)) {
            return "\u{2192}"
        } else if (slopeByMinute <= (2)) {
            return "\u{2197}"
        } else if (slopeByMinute <= (3.5)) {
            return "\u{2191}"
        } else {
            return "\u{2191}\u{2191}"
        }
    }
    
    func slopeOrdinal() -> Int {
        let slopeByMinute = calculatedValueSlope * 60000
        var ordinal = 0
        if(!hideSlope) {
            if (slopeByMinute <= (-3.5)) {
                ordinal = 7
            } else if (slopeByMinute <= (-2)) {
                ordinal = 6
            } else if (slopeByMinute <= (-1)) {
                ordinal = 5
            } else if (slopeByMinute <= (1)) {
                ordinal = 4
            } else if (slopeByMinute <= (2)) {
                ordinal = 3
            } else if (slopeByMinute <= (3.5)) {
                ordinal = 2
            } else {
                ordinal = 1
            }
        }
        return ordinal
    }
    
    static func isNormalValue(_ valueInMg: Double) -> Bool {
        return valueInMg < 400 && valueInMg >= 40
    }
    
    /// creates string with bg value in correct unit or "HIGH" or "LOW", or other like ???
    static func unitizedString(calculatedValue: Double, unitIsMgDl:Bool) -> String {
        var returnValue: String
        if calculatedValue >= 400 {
            returnValue = Texts_Common.HIGH
            
        } else if calculatedValue >= 40 {
            returnValue = calculatedValue.mgdlToMmolAndToString(mgdl: unitIsMgDl)
            
        } else if calculatedValue > 12 {
            returnValue = Texts_Common.LOW
            
        } else {
            switch calculatedValue  {
            case 0:
                returnValue = "??0"
                break
            case 1:
                returnValue = "?SN"
                break
            case 2:
                returnValue = "??2"
                break
            case 3:
                returnValue = "?NA"
                break
            case 5:
                returnValue = "?NC"
                break
            case 6:
                returnValue = "?CD"
                break
            case 9:
                returnValue = "?AD"
                break
            case 12:
                returnValue = "?RF"
                break
            default:
                returnValue = "???"
                break
            }
        }
        return returnValue
    }
    
    /// creates string with difference from previous reading and also unit
    func unitizedDeltaString(previousBgReading: BgReading?, showUnit: Bool, mgdl: Bool) -> String {
        guard let previousBgReading = previousBgReading else {
            return "???"
        }
        
        if timeStamp.timeIntervalSince(previousBgReading.timeStamp) > Double(ConstantsBGGraphBuilder.maxSlopeInMinutes * 60) {
            // don't show delta if there are not enough values or the values are more than 20 mintes apart
            return "???";
        }
        
        // delta value recalculated aligned with time difference between previous and this reading
        let value = currentSlope(previousBgReading: previousBgReading) * timeStamp.timeIntervalSince(previousBgReading.timeStamp) * 1000

        if abs(value) > 100 {
            // a delta > 100 will not happen with real BG values -> problematic sensor data
            return "ERR";
        }
        
        let valueAsString = value.mgdlToMmolAndToString(mgdl: mgdl)
        
        var deltaSign: String = ""
        if value > 0 {
            deltaSign = "+"
        }
        
        // quickly check "value" and prevent "-0mg/dL" or "-0.0mmol/L" being displayed
        if mgdl {
            if value > -1 && value < 1 {
                return "0" + (showUnit ? (" " + Constants.bgUnitMgDl) : "")
                
            } else {
                return deltaSign + valueAsString + (showUnit ? (" " + Constants.bgUnitMgDl) : "")
            }
            
        } else {
            if value > -0.1 && value < 0.1 {
                return "0.0" + (showUnit ? (" " + Constants.bgUnitMmol) : "")
                
            } else {
                return deltaSign + valueAsString + (showUnit ? (" " + Constants.bgUnitMmol) : "")
            }
        }
    }
    
    func unitizedDeltaStringPerMin(withSlope slope: Double, showUnit: Bool, mgdl: Bool) -> String {
        let changePerMinMg = slope * 1000 * Date.minuteInSeconds
        BgReading.log.d("changePerMinMg: \(String(format: "%.2f mg/dL/min", changePerMinMg))")

        if abs(changePerMinMg) > 100 {
            // a delta > 100 will not happen with real BG values -> problematic sensor data
            return "ERR";
        }
        
        let valueAsString: String
        if mgdl {
            valueAsString = String(format: "%.1f", changePerMinMg)
            
        } else {
            valueAsString = String(format: "%.2f", changePerMinMg.mgdlToMmol())
        }
        
        // - will be included in the value itself
        var deltaSign: String = ""
        if changePerMinMg > 0 {
            deltaSign = "+"
        }
        
        if mgdl {
            if changePerMinMg > -0.1 && changePerMinMg < 0.1 {
                return "0" + (showUnit ? (" " + Constants.bgUnitMgDl) : "") + "/m"
                
            } else {
                return deltaSign + valueAsString + (showUnit ? (" " + Constants.bgUnitMgDl) : "") + "/m"
            }
            
        } else {
            if changePerMinMg > -0.01 && changePerMinMg < 0.01 {
                return "0.0" + (showUnit ? (" " + Constants.bgUnitMmol) : "") + "/m"
                
            } else {
                return deltaSign + valueAsString + (showUnit ? (" " + Constants.bgUnitMmol) : "") + "/m"
            }
        }
    }
    
    /// creates string with difference from previous reading and also unit
    func unitizedDeltaStringPerMin(previousBgReading: BgReading?, showUnit: Bool, mgdl: Bool) -> String {
        guard let previousBgReading = previousBgReading else {
            return "???"
        }
        
        if timeStamp.timeIntervalSince(previousBgReading.timeStamp) > Double(ConstantsBGGraphBuilder.maxSlopeInMinutes * 60) {
            // don't show delta if there are not enough values or the values are more than 20 mintes apart
            return "???";
        }
        
        return unitizedDeltaStringPerMin(withSlope: currentSlope(previousBgReading: previousBgReading), showUnit: showUnit, mgdl: mgdl)
    }
    
    func currentSlope(previousBgReading: BgReading?) -> Double {
        if let previousBgReading = previousBgReading {
            let (slope, _) = calculateSlope(with: previousBgReading)
            return slope
            
        } else {
            return 0.0
        }
    }
    
    /// taken over form xdripplus
    ///
    /// - parameters:
    ///     - currentBgReading : reading for which slope is calculated
    ///     - lastBgReading : last reading result of call to BgReadings.getLatestBgReadings(1, sensor) sensor the current sensor and ignore calculatedValue and ignoreRawData both set to false
    /// - returns:
    ///     - calculated slope (the delta of milliseconds) and hideSlope
    func calculateSlope(with comparedReading: BgReading) -> (Double, Bool) {
        if timeStamp == comparedReading.timeStamp ||
            timeStamp.toMillisecondsAsDouble() - comparedReading.timeStamp.toMillisecondsAsDouble() > Double(ConstantsBGGraphBuilder.maxSlopeInMinutes * 60 * 1000) {
            return (0, true)
        }
        
        return ((comparedReading.calculatedValue - calculatedValue) / (comparedReading.timeStamp.toMillisecondsAsDouble() - timeStamp.toMillisecondsAsDouble()), false)
    }
    
    /// slopeName for upload to NightScout
    public var slopeName: String {
        let slope_by_minute:Double = calculatedValueSlope * 60000
        var arrow = "NONE"
        if (slope_by_minute <= (-3.5)) {
            arrow = "DoubleDown"
        } else if (slope_by_minute <= (-2)) {
            arrow = "SingleDown"
        } else if (slope_by_minute <= (-1)) {
            arrow = "FortyFiveDown"
        } else if (slope_by_minute <= (1)) {
            arrow = "Flat"
        } else if (slope_by_minute <= (2)) {
            arrow = "FortyFiveUp"
        } else if (slope_by_minute <= (3.5)) {
            arrow = "SingleUp"
        } else if (slope_by_minute <= (40)) {
            arrow = "DoubleUp"
        }
        
        if(hideSlope) {
            arrow = "NOT COMPUTABLE"
        }
        return arrow
    }

    enum SlopeArrow: Int, CustomStringConvertible {
        
        case doubleDown = 1
        case singleDown = 2
        case fortyFiveDown = 3
        case flat = 4
        case fortyFiveUp = 5
        case singleUp = 6
        case doubleUp = 7
        
        var description: String {
            let str: String
            switch self {
            case .doubleDown:
                str = "\u{2193}\u{2193}"
            case .singleDown:
                str =  "\u{2193}"
            case .fortyFiveDown:
                str = "\u{2198}"
            case .flat:
                str = "\u{2192}"
            case .fortyFiveUp:
                str =  "\u{2197}"
            case .singleUp:
                str = "\u{2191}"
            case .doubleUp:
                str = "\u{2191}\u{2191}"
            }
            return str
        }
    }
}
