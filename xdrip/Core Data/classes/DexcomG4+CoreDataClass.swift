import Foundation
import CoreData

class DexcomG4: NSManagedObject {
    
    /// batterylevel, not stored in coreData, will only be available after having received it from the M5Stack
    var batteryLevel: Int = 0
    
    /// create DexcomG4
    /// - parameters:
    init(address: String, name: String, nsManagedObjectContext:NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "DexcomG4", in: nsManagedObjectContext)!
        
        super.init(entity: entity, insertInto: nsManagedObjectContext)
        
        blePeripheral = BLEPeripheral(address: address,
                                      name: name,
                                      bluetoothPeripheralType: .DexcomG4Type,
                                      nsManagedObjectContext: nsManagedObjectContext)
    }
    
    private override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
}
