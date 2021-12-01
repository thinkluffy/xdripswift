//
//  StatisticsView.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/11/25.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import UIKit
import PieCharts

class StatisticsView: UIView {
    
    @IBOutlet weak var pieChartOutlet: PieChart!
    @IBOutlet weak var lowStatisticLabelOutlet: UILabel!
    @IBOutlet weak var inRangeStatisticLabelOutlet: UILabel!
    @IBOutlet weak var highStatisticLabelOutlet: UILabel!
    @IBOutlet weak var averageStatisticLabelOutlet: UILabel!
    @IBOutlet weak var a1CStatisticLabelOutlet: UILabel!
    @IBOutlet weak var cVStatisticLabelOutlet: UILabel!
    @IBOutlet weak var lowTitleLabelOutlet: UILabel!
    @IBOutlet weak var inRangeTitleLabelOutlet: UILabel!
    @IBOutlet weak var highTitleLabelOutlet: UILabel!
    @IBOutlet weak var averageTitleLabelOutlet: UILabel!
    @IBOutlet weak var a1cTitleLabelOutlet: UILabel!
    @IBOutlet weak var cvTitleLabelOutlet: UILabel!
    @IBOutlet weak var lowLabelOutlet: UILabel!
    @IBOutlet weak var highLabelOutlet: UILabel!
    @IBOutlet weak var timePeriodLabelOutlet: UILabel!
    @IBOutlet weak var bgReadingsCountTitleLabelOutlet: UILabel!
    @IBOutlet weak var bgReadingsCountStatisticLabelOutlet: UILabel!
    @IBOutlet weak var stdDeviationTitleLabelOutlet: UILabel!
    @IBOutlet weak var stdDeviationStatisticLabelOutlet: UILabel!
    @IBOutlet weak var gviLabel: UILabel!
    @IBOutlet weak var pgsLabel: UILabel!

    private var contentView: UIView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    private func initialize() {
        contentView = loadXib()
        addSubview(contentView)
        
        pieChartOutlet.outerRadius = 40
        pieChartOutlet.innerRadius = 15
        
        // set the title labels to their correct localization
        self.lowTitleLabelOutlet.text = Texts_Common.lowStatistics
        self.inRangeTitleLabelOutlet.text = Texts_Common.inRangeStatistics
        self.highTitleLabelOutlet.text = Texts_Common.highStatistics
        self.averageTitleLabelOutlet.text = Texts_Common.averageStatistics
        self.a1cTitleLabelOutlet.text = Texts_Common.a1cStatistics
        self.cvTitleLabelOutlet.text = Texts_Common.cvStatistics
        self.bgReadingsCountTitleLabelOutlet.text = R.string.common.common_statistics_bgReadingsCount()
        self.stdDeviationTitleLabelOutlet.text = R.string.common.common_statistics_stdDeviation()
    }
    
    private func loadXib() -> UIView {
        let className =  type(of: self)
        let bundle = Bundle(for: className)
        let name = NSStringFromClass(className).components(separatedBy: ".").last
        let nib = UINib(nibName: name!, bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as! UIView
    }
    
    func show(statistics: StatisticsManager.Statistics, daysToUseStatistics: Int, animatePieChart: Bool = false) {
        let isMgDl = UserDefaults.standard.bloodGlucoseUnitIsMgDl
        
        // set the low/high "label" labels with the low/high user values that the user has chosen to use
        lowLabelOutlet.text = "(<" + (isMgDl ? Int(statistics.lowLimitForTIR).description : statistics.lowLimitForTIR.round(toDecimalPlaces: 1).description) + ")"
        highLabelOutlet.text = "(>" + (isMgDl ? Int(statistics.highLimitForTIR).description : statistics.highLimitForTIR.round(toDecimalPlaces: 1).description) + ")"
        
        // set all label outlets with the correctly formatted calculated values
        lowStatisticLabelOutlet.textColor = ConstantsStatistics.labelLowColor
        lowStatisticLabelOutlet.text = Int(statistics.lowStatisticValue.round(toDecimalPlaces: 0)).description + "%"
        
        inRangeStatisticLabelOutlet.textColor = ConstantsStatistics.labelInRangeColor
        inRangeStatisticLabelOutlet.text = Int(statistics.inRangeStatisticValue.round(toDecimalPlaces: 0)).description + "%"
        
        highStatisticLabelOutlet.textColor = ConstantsStatistics.labelHighColor
        highStatisticLabelOutlet.text = Int(statistics.highStatisticValue.round(toDecimalPlaces: 0)).description + "%"
        
        if statistics.readingsCount > 0 {
            bgReadingsCountStatisticLabelOutlet.text = "\(statistics.readingsCount)"
        }
        
        if statistics.stdDeviation > 0 {
            if isMgDl {
                self.stdDeviationStatisticLabelOutlet.text = Int(statistics.stdDeviation.round(toDecimalPlaces: 0)).description + " mg/dL"
                
            } else {
                self.stdDeviationStatisticLabelOutlet.text = statistics.stdDeviation.round(toDecimalPlaces: 1).description + " mmol/L"
            }
        }
        
        // if there are no values returned (new sensor?) then just leave the default "-" showing
        if statistics.averageStatisticValue.value > 0 {
            averageStatisticLabelOutlet.text = (isMgDl ? Int(statistics.averageStatisticValue.round(toDecimalPlaces: 0)).description : statistics.averageStatisticValue.round(toDecimalPlaces: 1).description) + (isMgDl ? " mg/dL" : " mmol/L")
        }
        
        // if there are no values returned (new sensor?) then just leave the default "-" showing
        if statistics.a1CStatisticValue.value > 0 {
            if UserDefaults.standard.useIFCCA1C {
                a1CStatisticLabelOutlet.text = Int(statistics.a1CStatisticValue.round(toDecimalPlaces: 0)).description + " mmol"
            
            } else {
                a1CStatisticLabelOutlet.text = statistics.a1CStatisticValue.round(toDecimalPlaces: 1).description + "%"
            }
        }
        
        // if there are no values returned (new sensor?) then just leave the default "-" showing
        if statistics.cVStatisticValue > 0 {
            cVStatisticLabelOutlet.text = Int(statistics.cVStatisticValue.round(toDecimalPlaces: 0)).description + "%"
        }
        
        if statistics.gviStatisticValue > 0 {
            gviLabel.text = String(format: "%.1f", statistics.gviStatisticValue)
        }
        
		if statistics.pgsStatisticValue > 0 {
			pgsLabel.text = String(format: "%.0f", statistics.pgsStatisticValue)
		}
        // show number of days calculated under the pie chart
        switch daysToUseStatistics {
        case 0:
            timePeriodLabelOutlet.text = Texts_Common.today
            
        case 1:
            timePeriodLabelOutlet.text = "24 " + Texts_Common.hours
            
        default:
            timePeriodLabelOutlet.text = statistics.numberOfDaysUsed.description + " " + Texts_Common.days
        }
        
        // disable the chart animation if it's just a normal update, enable it if the call comes from didAppear()
        if animatePieChart {
            pieChartOutlet.animDuration = ConstantsStatistics.pieChartAnimationSpeed
            
        } else {
            pieChartOutlet.animDuration = 0
        }
        
        // cleart first, or the changed models have no effect
        pieChartOutlet.clear()
        
        if statistics.inRangeStatisticValue < 100 {
            pieChartOutlet.models = [
                PieSliceModel(value: Double(statistics.lowStatisticValue),
                              color: ConstantsStatistics.pieChartLowSliceColor),
                PieSliceModel(value: Double(statistics.inRangeStatisticValue),
                              color: ConstantsStatistics.pieChartInRangeSliceColor),
                PieSliceModel(value: Double(statistics.highStatisticValue),
                              color: ConstantsStatistics.pieChartHighSliceColor)
            ]
            
        } else {
            // show a green circle at 100%
            pieChartOutlet.models = [
                PieSliceModel(value: 1, color: ConstantsStatistics.pieChartInRangeSliceColor)
            ]
        }
    }
}