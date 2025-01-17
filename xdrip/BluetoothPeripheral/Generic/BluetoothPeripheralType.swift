import Foundation
import CoreData

/// defines the types of bluetooth peripherals
/// - bubble, dexcom G5, dexcom G4, ... which are all of category CGM
/// - M5Stack, M5StickC which are both of category M5Stack
/// - possibily more in the future, like watlaa
enum BluetoothPeripheralType: String, CaseIterable {

    /// Libre 2
    case Libre2Type = "Libre 2 Direct"
    
    /// MiaoMiao
    case MiaoMiaoType = "MiaoMiao"
    
    /// bubble
    case BubbleType = "Bubble / Bubble Mini"
    
    /// DexcomG6
    case DexcomG6Type = "Dexcom G6"
    
    /// DexcomG5
    case DexcomG5Type = "Dexcom G5"
    
    /// Blucon
    case BluconType = "Blucon"
    
    /// BlueReader
    case BlueReaderType = "BlueReader"
    
    /// Droplet
    case DropletType = "Droplet"
    
    /// GNSentry
    case GNSentryType = "GNSentry"
      
    /// watlaa master
    case WatlaaType = "Watlaa"
    
    /// Atom
    case AtomType = "Atom"

    /// - returns: the BluetoothPeripheralViewModel. If nil then there's no specific settings for the tpe of bluetoothPeripheral
    func viewModel() -> BluetoothPeripheralViewModel? {
        switch self {
            
        case .WatlaaType:
            return WatlaaBluetoothPeripheralViewModel()
            
        case .DexcomG5Type:
            return DexcomG5BluetoothPeripheralViewModel()
            
        case .BubbleType:
            return BubbleBluetoothPeripheralViewModel()
            
        case .MiaoMiaoType:
            return MiaoMiaoBluetoothPeripheralViewModel()
            
        case .BluconType:
            return BluconBluetoothPeripheralViewModel()
            
        case .GNSentryType:
            return GNSEntryBluetoothPeripheralViewModel()
         
        case .BlueReaderType:
            return nil
            
        case .DropletType:
            return DropletBluetoothPeripheralViewModel()
            
        case .DexcomG6Type:
            return DexcomG6BluetoothPeripheralViewModel()
            
        case .Libre2Type:
            return Libre2BluetoothPeripheralViewModel()
            
        case .AtomType:
            return AtomBluetoothPeripheralViewModel()
            
        }
    }
    
    func createNewBluetoothPeripheral(withAddress address: String, withName name: String, nsManagedObjectContext: NSManagedObjectContext) -> BluetoothPeripheral {
    
        switch self {
            
        case .WatlaaType:
            return Watlaa(address: address, name: name, nsManagedObjectContext: nsManagedObjectContext)
            
        case .DexcomG5Type:
            return DexcomG5(address: address, name: name, nsManagedObjectContext: nsManagedObjectContext)
            
        case .DexcomG6Type:
            // DexcomG6 is a DexcomG5 with isDexcomG6 set to true
            let dexcomG6 = DexcomG5(address: address, name: name, nsManagedObjectContext: nsManagedObjectContext)
            dexcomG6.isDexcomG6 = true
            
            return dexcomG6
            
        case .BubbleType:
            return Bubble(address: address, name: name, nsManagedObjectContext: nsManagedObjectContext)
            
        case .MiaoMiaoType:
            return MiaoMiao(address: address, name: name, nsManagedObjectContext: nsManagedObjectContext)
            
        case .BluconType:
            return Blucon(address: address, name: name, nsManagedObjectContext: nsManagedObjectContext)
            
        case .GNSentryType:
            return GNSEntry(address: address, name: name, nsManagedObjectContext: nsManagedObjectContext)
  
        case .BlueReaderType:
            return BlueReader(address: address, name: name, nsManagedObjectContext: nsManagedObjectContext)
            
        case .DropletType:
            return Droplet(address: address, name: name, nsManagedObjectContext: nsManagedObjectContext)
            
        case .Libre2Type:
            return Libre2(address: address, name: name, nsManagedObjectContext: nsManagedObjectContext)
            
        case .AtomType:
            return Atom(address: address, name: name, nsManagedObjectContext: nsManagedObjectContext)
        }
        
    }

    /// to which category of bluetoothperipherals does this type belong (M5Stack, CGM, ...)
    func category() -> BluetoothPeripheralCategory {
        
        switch self {
        case .DexcomG5Type, .BubbleType, .MiaoMiaoType, .BluconType, .GNSentryType, .BlueReaderType, .DropletType, .DexcomG6Type, .WatlaaType, .Libre2Type, .AtomType:
            return .CGM
        }
        
    }
    
    /// does the device need a transmitterID (currently only Dexcom and Blucon)
    func needsTransmitterId() -> Bool {
        
        switch self {
            
        case .WatlaaType, .BubbleType, .MiaoMiaoType, .GNSentryType, .BlueReaderType, .DropletType, .Libre2Type, .AtomType:
            return false
            
        case .DexcomG5Type, .BluconType, .DexcomG6Type:
            return true

        }
        
    }
    
    /// - returns nil if id to validate has expected length and type of characters etc.
    /// - returns error text if transmitterId is not ok
    func validateTransmitterId(transmitterId: String) -> String? {
        
        switch self {
            
        case .DexcomG5Type, .DexcomG6Type:
            
            // length for G5 and G6 is 6
            if transmitterId.count != 6 {
                return Texts_ErrorMessages.TransmitterIDShouldHaveLength6
            }
            
            //verify allowed chars
            let regex = try! NSRegularExpression(pattern: "[a-zA-Z0-9]", options: .caseInsensitive)
            if !transmitterId.validate(withRegex: regex) {
                return Texts_ErrorMessages.DexcomTransmitterIDInvalidCharacters
            }
            
            // reject transmitters with id in range 8G or higher. These are Firefly's
            // convert to upper
            let transmitterIdUpper = transmitterId.uppercased()
            if transmitterIdUpper.compare("8G") == .orderedDescending {
                return Texts_SettingsView.transmitterId8OrHigherNotSupported
            }

            // validation successful
            return nil
            
        case .WatlaaType, .BubbleType, .MiaoMiaoType, .GNSentryType, .BlueReaderType, .DropletType, .Libre2Type, .AtomType:
            // no transmitter id means no validation to do
            return nil
            
        case .BluconType:
            
            let regex = try! NSRegularExpression(pattern: "^[0-9]{1,5}$", options: .caseInsensitive)
            if !transmitterId.validate(withRegex: regex) {
                return Texts_ErrorMessages.TransmitterIdBluCon
            }
            
            if transmitterId.count != 5 {
                return Texts_ErrorMessages.TransmitterIdBluCon
            }
            return nil
            
        }
        
    }
    
    /// is it web oop supported or not.
    func canWebOOP() -> Bool {
        switch self {
            
        case .WatlaaType, .DexcomG5Type, .DexcomG6Type, .BluconType, .BlueReaderType, .DropletType , .GNSentryType:
            return false
            
        case .BubbleType, .MiaoMiaoType, .AtomType:
            return true
            
        case .Libre2Type:
            // oop web can still be used for Libre2 because in the end the data received is Libre 1 format, we can use oop web to get slope parameters
            return true
        }
    }
    
    /// can use non fixed slopes or not
    func canUseNonFixedSlope() -> Bool {
       switch self {
           
       case .DexcomG5Type, .DexcomG6Type:
           return false
           
       case .BubbleType, .MiaoMiaoType, .WatlaaType, .BluconType, .BlueReaderType, .DropletType , .GNSentryType, .AtomType:
           return true
        
       case .Libre2Type:
            return true
       }
    }
    
    func onlyForFullFeatureMode() -> Bool {
        switch self {
        case .Libre2Type, .DexcomG5Type, .DexcomG6Type:
            return true
            
        default:
            return false
        }
    }
}
