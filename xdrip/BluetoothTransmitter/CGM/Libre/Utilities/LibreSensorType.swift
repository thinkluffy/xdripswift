import Foundation
import os

// sourcre https://github.com/gui-dos/DiaBLE

public enum LibreSensorType: String {
    
    // Libre 1
    case libre1    = "DF"
    
    case libre1A2 =  "A2"
    
    case libre2    = "9D"
    
    case libreUS   = "E5"
   
    case libreProH = "70"
    
    var description: String {
        
        switch self {
            
        case .libre1:
            return "Libre 1"
            
        case .libre1A2:
            return "Libre 1 A2"
            
        case .libre2:
            return "Libre 2"
            
        case .libreUS:
            return "Libre US"
            
        case .libreProH:
            return "Libre PRO H"

        }
    }

    /// - reads the first byte in patchInfo and dependent on that value, returns type of sensor
    /// - if patchInfo = nil, then returnvalue is Libre1
    /// - if first byte is unknown, then returns nil
    static func type(patchInfo: String?) -> LibreSensorType? {
        
        guard let patchInfo = patchInfo else {return .libre1}
        
        guard patchInfo.count > 1 else {return nil}
        
        let firstTwoChars = patchInfo[0..<2].uppercased()
        
        switch firstTwoChars {
            
        case "DF":
            return .libre1
            
        case "A2":
            return .libre1A2
            
        case "9D":
            return .libre2
            
        case "E5":
            return .libreUS
            
        case "70":
            return .libreProH
            
        default:
            return nil
        }
    }
    
    /// maximum sensor age in seconds, nil if no maximum
    func maxSensorAgeInSeconds() -> Int? {
        switch self {
        case .libre1, .libre1A2, .libre2:
            // official 14 days plus 12 hours of "overtime" (e.g Libre sensors have an extra 12 hours before the stop working)
            return Int(14.5 * Date.dayInSeconds)
            
        case .libreUS:
            return nil

        case .libreProH:
            return nil
        }
    }
}


