import Foundation
import CoreData

class BlueReader: NSManagedObject {
    
    /// create BlueReader
    /// - parameters:
    init(address: String, name: String, nsManagedObjectContext:NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "BlueReader", in: nsManagedObjectContext)!
        
        super.init(entity: entity, insertInto: nsManagedObjectContext)
        
        blePeripheral = BLEPeripheral(address: address,
                                      name: name,
                                      bluetoothPeripheralType: .BlueReaderType,
                                      nsManagedObjectContext: nsManagedObjectContext)
        
        blePeripheral.webOOPEnabled = false
    }
    
    private override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
}
