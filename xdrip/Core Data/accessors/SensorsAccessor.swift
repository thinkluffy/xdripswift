import Foundation
import os
import CoreData

class SensorsAccessor {
        
    /// for logging
    private static let log = Log(type: SensorsAccessor.self)
            
    /// will get sensor with enddate nil (ie not stopped) and highest startDate,
    /// otherwise returns nil
    ///
    ///
    func fetchActiveSensor() -> Sensor? {
        // create fetchRequest
        let fetchRequest: NSFetchRequest<Sensor> = Sensor.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Sensor.startDate), ascending: false)]
        fetchRequest.fetchLimit = 1
        
        // only sensors with endDate nil, ie not started, should be only one in the end
        let predicate = NSPredicate(format: "endDate == nil")
        fetchRequest.predicate = predicate

        // define returnvalue
        var returnValue: Sensor?
        
        CoreDataManager.shared.mainManagedObjectContext.performAndWait {
            do {
                // Execute Fetch Request
                let sensors = try fetchRequest.execute()
                
                if sensors.count > 0 {
                    if sensors[0].endDate == nil {
                        returnValue = sensors[0]
                    }
                }
            } catch {
                let fetchError = error as NSError
                SensorsAccessor.log.e("Unable to Execute Sensor Fetch Request: \(fetchError.localizedDescription)")
            }
        }
        
        return returnValue
    }
    
    func listSensors(on context: NSManagedObjectContext) {
        // create fetchRequest
        let fetchRequest: NSFetchRequest<Sensor> = Sensor.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Sensor.startDate), ascending: false)]
        
        context.performAndWait {
            do {
                // Execute Fetch Request
                let sensors = try fetchRequest.execute()
                SensorsAccessor.log.d("TotalSensors: \(sensors.count)")
                
                if sensors.count > 0 {
                    for (i, sensor) in sensors.enumerated() {
                        SensorsAccessor.log.d(sensor.log(indentation: "[\(i)]"))
                    }
                }
                
            } catch {
                let fetchError = error as NSError
                SensorsAccessor.log.e("Unable to Execute Sensor Fetch Request: \(fetchError.localizedDescription)")
            }
        }
    }
}
