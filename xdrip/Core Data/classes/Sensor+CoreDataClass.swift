import Foundation
import CoreData


public class Sensor: NSManagedObject {

    /// creates Sensor.
    ///
    /// id gets new value - all other optional values will get value nil
    init(startDate: Date, nsManagedObjectContext: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "Sensor", in: nsManagedObjectContext)!
        
        super.init(entity: entity, insertInto: nsManagedObjectContext)

        self.startDate = startDate
        id = UniqueId.createEventId()
    }
    
    private override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }

    /// log the contents to a string
    public func log(indentation: String) -> String {
        var r: String = "Sensor = "
        r += "\n" + indentation + "Uniqueid = " + id
        r += "\n" + indentation + "StartedAt = " + startDate.description
        if let endDate = endDate {
            r += "\n" + indentation + "StoppedAt = " + endDate.description
        }
        r += "\n"
        return r;
    }
}
