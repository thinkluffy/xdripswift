import Foundation

enum ConstantsSpeakReading {
    
    /// if the time between the last and last but one reading is less than minimumTimeBetweenTwoReadingsInMinutes, then the reading will not be spoken - except if there's been a disconnect in between these two readings
    ///
    /// UserDefaults.standard.speakInterval overrules this value
    static let minimumTimeBetweenTwoReadingsInMinutes = 4.75
    
}
