import Foundation
import UIKit

extension Date {
    
    //source https://freakycoder.com/ios-notes-22-how-to-get-current-time-as-timestamp-fa8a0d422879
    /// extension to Date class
    /// - returns:
    ///     time since 1 Jan 1970 in ms, can be negative if Date is before 1 Jan 1970
    func toMillisecondsAsDouble() -> Double {
        return Double(self.timeIntervalSince1970 * 1000)
    }
    
    /// returns Date in milliseconds as Int64, since 1.1.1970
    func toMillisecondsAsInt64() -> Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
    
    /// returns Date in seconds as Int64, since 1.1.1970
    func toSecondsAsInt64() -> Int64 {
        return Int64((self.timeIntervalSince1970).rounded())
    }
    
    /// gives number of minutes since 00:00 local time
    func minutesSinceMidNightLocalTime() -> Int {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: self)
        let minute = calendar.component(.minute, from: self)
        return Int(hour * 60 + minute)
    }
    
    /// changes the date to 00:00 the same day, local time, and returns the result as a new Date object
    func toMidnight() -> Date {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: self)
        let minute = calendar.component(.minute, from: self)
        let seconds = calendar.component(.second, from: self)
        let timeInterval = TimeInterval(-Double(hour * 3600 + minute * 60 + seconds))
        return Date(timeInterval: timeInterval, since: self)
    }
    
    func ISOStringFromDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        
        return dateFormatter.string(from: self).appending("Z")
    }
    
    /// date to string, with date and time as specified by one of the values in DateFormatter.Style
    func toString(timeStyle: DateFormatter.Style, dateStyle: DateFormatter.Style) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = timeStyle
        dateFormatter.dateStyle = dateStyle
        return dateFormatter.string(from: self)
    }
    
    /// returns seconds since 1.1.1970 local time for current timezone
    func toSecondsAsInt64Local() -> Int64 {
        let calendar = Calendar.current
        return (Date().toSecondsAsInt64() + Int64(calendar.timeZone.secondsFromGMT()))
    }
    
    /// creates a new date, rounded to lower hour, eg if date = 26 10 2019 23:23:35, returnvalue is date 26 10 2019 23:00:00
    func toLowerHour() -> Date {
        return Date(timeIntervalSinceReferenceDate:
            (timeIntervalSinceReferenceDate / 3600.0).rounded(.down) * 3600.0)
    }
    
    func toHumanFirendlyTime(showSeconds: Bool = false) -> String {
        let dateFormatter = DateFormatter()
        if showSeconds {
            dateFormatter.dateFormat = "HH:mm:ss"
            
        } else {
            dateFormatter.dateFormat = "HH:mm"
        }
        
        if Calendar.current.isDateInToday(self) {
            return R.string.common.today() + " " + dateFormatter.string(from: self)

        } else if Calendar.current.isDateInYesterday(self) {
            return R.string.common.yesterday() + " " + dateFormatter.string(from: self)

        } else {
            dateFormatter.dateFormat = "yyyy-MM-dd " + dateFormatter.dateFormat
            return dateFormatter.string(from: self)
        }
    }
}
