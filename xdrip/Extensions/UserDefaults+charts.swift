import Foundation

extension UserDefaults {
    
    /// keys for settings and user defaults. For reading and writing settings, the keys should not be used, the specific functions kan be used.
    private enum KeysCharts: String {
        
        /// chart width in hours
        case chartWidthInHours = "chartWidthInHours"
        
        /// timeformat for labels in chart, time axis
        case chartTimeAxisLabelFormat = "chartTimeAxisLabelFormat"
        
    }
    
    /// chart width in hours
    @objc dynamic var chartWidthInHours: Int {
        get {
            var ret = integer(forKey: KeysCharts.chartWidthInHours.rawValue)
            // if 0 set to defaultvalue
            if ret == 0 {
                ret = ConstantsGlucoseChart.defaultChartWidthInHours
            }
            return ret
        }
        set {
            set(newValue, forKey: KeysCharts.chartWidthInHours.rawValue)
        }
    }

    /// timeformat for labels in chart, time axis
    @objc dynamic var chartTimeAxisLabelFormat: String {
        get {
            if let returnValue = string(forKey: KeysCharts.chartTimeAxisLabelFormat.rawValue) {
                return returnValue
            } else {
                return ConstantsGlucoseChart.defaultTimeAxisLabelFormat
            }
        }
        set {
            set(newValue, forKey: KeysCharts.chartTimeAxisLabelFormat.rawValue)
        }
    }
}
