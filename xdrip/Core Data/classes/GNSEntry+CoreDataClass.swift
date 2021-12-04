import Foundation
import CoreData

class GNSEntry: NSManagedObject {
    
    /// batterylevel, not stored in coreData, will only be available after having received it from the M5Stack
    var batteryLevel: Int = 0
    
    /// create GNSEntry
    /// - parameters:
    init(address: String, name: String, nsManagedObjectContext: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entity(forEntityName: "GNSEntry", in: nsManagedObjectContext)!
        
        super.init(entity: entity, insertInto: nsManagedObjectContext)
        
        blePeripheral = BLEPeripheral(address: address, name: name, bluetoothPeripheralType: .GNSentryType, nsManagedObjectContext: nsManagedObjectContext)

        blePeripheral.webOOPEnabled = false

    }
    
    private override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
}
