import Foundation
import CoreData
import os

class BLEPeripheralAccessor {
        
    /// for logging
    private var log = OSLog(subsystem: ConstantsLog.subSystem, category: ConstantsLog.categoryApplicationDataBLEPeripheral)
    
    // MARK: Public functions
    
    /// gets all BLEPeripheral instances from coredata
    func getBLEPeripherals() -> [BLEPeripheral] {
        
        // create fetchRequest to get BLEPeripheral's as BLEPeripheral classes
        let blePeripheralFetchRequest: NSFetchRequest<BLEPeripheral> = BLEPeripheral.fetchRequest()
        
        // fetch the BLEPeripherals
        var blePeripheralArray = [BLEPeripheral]()
        CoreDataManager.shared.mainManagedObjectContext.performAndWait {
            do {
                // Execute Fetch Request
                blePeripheralArray = try blePeripheralFetchRequest.execute()
            } catch {
                let fetchError = error as NSError
                trace("in getBLEPeripherals, Unable to Execute BLEPeripherals Fetch Request : %{public}@", log: self.log, category: ConstantsLog.categoryApplicationDataBLEPeripheral, type: .error, fetchError.localizedDescription)
            }
        }
        
        return blePeripheralArray
        
    }
    
}
