import Foundation
import CoreData

class Atom: NSManagedObject {
    
    /// batterylevel, not stored in coreData, will only be available after having received it from the M5Stack
    var batteryLevel: Int = 0
    
    // sensorState
    var sensorState: LibreSensorState = .unknown
    
    /// create Atom
    /// - parameters:
    init(address: String, name: String, nsManagedObjectContext:NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entity(forEntityName: "Atom", in: nsManagedObjectContext)!
        
        super.init(entity: entity, insertInto: nsManagedObjectContext)
        
        blePeripheral = BLEPeripheral(address: address,
                                      name: name,
                                      bluetoothPeripheralType: .AtomType,
                                      nsManagedObjectContext: nsManagedObjectContext)
        
    }
    
    private override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
}
