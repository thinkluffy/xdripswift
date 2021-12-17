//
//  ConstantsStatistics.swift
//  xdrip
//
//  Created by Paul Plant on 25/04/21.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import Foundation
import UIKit

/// constants for statistics view
enum ConstantsStatistics {
    
    /// animation speed when drawing the pie chart
    static let pieChartAnimationSpeed = 0.3
    
    /// label colors for the statistics
    static let labelLowColor = ConstantsUI.alertColor
    static let labelInRangeColor = ConstantsUI.normalColor
    static let labelHighColor = ConstantsUI.warningColor
    
    /// pie slice color for low
    static let pieChartLowSliceColor = labelLowColor
    
    /// pie slice color for in range
    static let pieChartInRangeSliceColor = labelInRangeColor
    
    /// pie slice color for high
    static let pieChartHighSliceColor = labelHighColor
    
    // contstants to define the standardised TIR values in case the user prefers to use them
    // published values from here: https://care.diabetesjournals.org/content/42/8/1593
    static let standardisedLowValueForTIRInMgDl = 70.0
    static let standardisedHighValueForTIRInMgDl = 180.0
    static let standardisedLowValueForTIRInMmol = 3.9
    static let standardisedHighValueForTIRInMmol = 10.0
    
    // minimum filter time in minutes (used for Libre 2 readings)
    static let minimumFilterTimeBetweenReadings: Double = 4.5
}

