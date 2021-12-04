import Foundation
import CoreData

class Droplet: NSManagedObject {
    
    /// batterylevel, not stored in coreData, will only be available after having received it from the M5Stack
    var batteryLevel: Int = 0
    
    /// create Droplet
    /// - parameters:
    init(address: String, name: String, nsManagedObjectContext:NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entity(forEntityName: "Droplet", in: nsManagedObjectContext)!
        
        super.init(entity: entity, insertInto: nsManagedObjectContext)
        
        blePeripheral = BLEPeripheral(address: address,
                                      name: name,
                                      bluetoothPeripheralType: .DropletType,
                                      nsManagedObjectContext: nsManagedObjectContext)
        
    }
    
    /// create Droplet
    /// - parameters:
    init(address: String, name: String, sensorSerialNumber: String?, webOOPEnabled: Bool, oopWebSite: String?, oopWebToken: String?, nsManagedObjectContext:NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entity(forEntityName: "Droplet", in: nsManagedObjectContext)!
        
        super.init(entity: entity, insertInto: nsManagedObjectContext)
        
        blePeripheral = BLEPeripheral(address: address,
                                      name: name,
                                      bluetoothPeripheralType: .DropletType,
                                      nsManagedObjectContext: nsManagedObjectContext)
        
        blePeripheral.webOOPEnabled = false
    }
    
    private override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
}
