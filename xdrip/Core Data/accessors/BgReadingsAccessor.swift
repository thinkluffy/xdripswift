import Foundation
import CoreData
import os
import SwiftUI

class BgReadingsAccessor {
        
    /// for logging
    private static let log = Log(type: BgReadingsAccessor.self)
    
    // MARK: - public functions
    
    func get2LatestBgReadings(minimumTimeIntervalInMinutes: Double) -> [BgReading] {
        get2LatestBgReadings(minimumTimeIntervalInSeconds: minimumTimeIntervalInMinutes * 60)
    }
    
    /// - Gives 2 latest readings with calculatedValue != 0, minimum time between the two readings specified by minimumTimeIntervalInMinutes
    ///
    /// - parameters:
    ///     - minimumTimeIntervalInMinutes : minimum time between the two readings in seconds
    /// - returns: 0 1 or 2 readings, minimum time diff between the two readings
    ///     Order by timestamp, descending meaning the reading at index 0 is the youngest
    func get2LatestBgReadings(minimumTimeIntervalInSeconds: Double) -> [BgReading] {
        
        // assuming there will be at most 1 reading per minute stored, feching minimumTimeIntervalInMinutes readings should be enough, adding 5 to be sure we fetch enough readings
        let readingsToFetch = Int(minimumTimeIntervalInSeconds / 60) + 5
        
        // to define the fromDate, assume there's one reading every 5 minutes, and multiple with readingsToFetch
        let fromDate = Date(timeIntervalSinceNow: -(Double(readingsToFetch) * 5.0 * 60.0))
        
        // get latest readings
        let latestReadings = getLatestBgReadings(limit: readingsToFetch, fromDate: fromDate, forSensor: nil, ignoreRawData: true, ignoreCalculatedValue: false)
        
        // if there's no readings, then return empty array
        if latestReadings.count == 0 {return [BgReading]()}
        
        // if there's only one reading, then return it
        if latestReadings.count == 1 {return [latestReadings[0]]}
    
        // there's more than one reading, search the first with time difference >= minimumTimeIntervalInMinutes
        var indexNextReading = 1
        while indexNextReading < latestReadings.count && (abs(latestReadings[indexNextReading].timeStamp.timeIntervalSince(latestReadings[0].timeStamp)) < minimumTimeIntervalInSeconds) {

            indexNextReading = indexNextReading + 1
        }
        
        // if indexNextReading = size of latestReadings, then it means we didn't find a second reading with time difference >= minimumTimeIntervalInMinutes, return only the first
        if indexNextReading == latestReadings.count {
            return [latestReadings[0]]
        }
        
        // return the first, and the one found matching the expected time difference
        return [latestReadings[0], latestReadings[indexNextReading]]
    }
    
    /// Gives readings for which calculatedValue != 0, rawdata != 0, matching sensorid if sensorid not nil, with maximumDays old
    ///
    /// - parameters:
    ///     - limit : maximum amount of readings to return, if nil then no limit in amount
    ///     - howOld : maximum age in days, it will calculate exacte (24 hours) * howOld, if nil then no limit in age
    ///     - forSensor : if not nil, then only readings for the given sensor will be returned - if nil, then sensor is ignored
    ///     - if ignoreRawData = true, then value of rawdata will be ignored
    ///     - if ignoreCalculatedValue = true, then value of calculatedValue will be ignored
    /// - returns: an array with readings, can be empty array.
    ///     Order by timestamp, descending meaning the reading at index 0 is the youngest
    func getLatestBgReadings(limit: Int?, howOld: Int?, forSensor sensor: Sensor?, ignoreRawData: Bool, ignoreCalculatedValue: Bool) -> [BgReading] {
        
        // if maximum age specified then create fromdate
        var fromDate: Date?
        if let howOld = howOld, howOld >= 0 {
            fromDate = Date(timeIntervalSinceNow: -Double(howOld) * Date.dayInSeconds)
        }
        
        return getLatestBgReadings(limit: limit, fromDate: fromDate, forSensor: sensor, ignoreRawData: ignoreRawData, ignoreCalculatedValue: ignoreCalculatedValue)
        
    }
    
    /// Gives readings for which calculatedValue != 0, rawdata != 0, matching sensorid if sensorid not nil, with timestamp higher than fromDate
    ///
    /// - parameters:
    ///     - limit : maximum amount of readings to return, if nil then no limit in amount
    ///     - fromDate : reading must have date > fromDate
    ///     - forSensor : if not nil, then only readings for the given sensor will be returned - if nil, then sensor is ignored
    ///     - if ignoreRawData = true, then value of rawdata will be ignored
    ///     - if ignoreCalculatedValue = true, then value of calculatedValue will be ignored
    /// - returns: an array with readings, can be empty array.
    ///     Order by timestamp, descending meaning the reading at index 0 is the youngest
   func getLatestBgReadings(limit: Int?, fromDate: Date?, forSensor sensor: Sensor?, ignoreRawData: Bool, ignoreCalculatedValue: Bool) -> [BgReading] {
        
        var returnValue:[BgReading] = []
        
        let ignoreSensorId = sensor == nil ? true:false
        
        let bgReadings = fetchBgReadings(limit: limit, fromDate: fromDate)
        
        loop: for bgReading in bgReadings {
            if ignoreSensorId {
                if (bgReading.calculatedValue != 0.0 || ignoreCalculatedValue) && (bgReading.rawData != 0.0 || ignoreRawData) {
                    returnValue.append(bgReading)
                }
                
            } else {
                if let readingsensor = bgReading.sensor {
                    if readingsensor.id == sensor!.id {
                        if (bgReading.calculatedValue != 0.0 || ignoreCalculatedValue) && (bgReading.rawData != 0.0 || ignoreRawData) {
                            returnValue.append(bgReading)
                        }
                    }
                }
            }
            
            if let limit = limit {
                if returnValue.count == limit {
                    break loop
                }
            }
        }
        return returnValue
    }
    
    /// gets last reading, ignores rawData and calculatedValue
    /// - parameters:
    ///     - sensor: sensor for which reading is asked, if nil then sensor value is ignored
    func last(forSensor sensor:Sensor?) -> BgReading? {
        let readings = getLatestBgReadings(limit: 1, howOld: nil, forSensor: sensor, ignoreRawData: true, ignoreCalculatedValue: true)
        if readings.count > 0 {
            return readings.last
            
        } else {
            return nil
        }
    }
    
    /// gets bgReadings, synchronously, in the managedObjectContext's thread
    /// - returns:
    ///        readings sorted by timestamp, ascending (ie first is oldest)
    /// - parameters:
    ///     - to : if specified, only return readings with timestamp  smaller than fromDate (not equal to)
    ///     - from : if specified, only return readings with timestamp greater than fromDate (not equal to)
    ///     - managedObjectContext : the ManagedObjectContext to use
    func getBgReadings(from: Date?, to: Date?, on managedObjectContext: NSManagedObjectContext) -> [BgReading] {
        
        let fetchRequest: NSFetchRequest<BgReading> = BgReading.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(BgReading.timeStamp), ascending: true)]
        
        // create predicate
        if let from = from, to == nil {
            let predicate = NSPredicate(format: "timeStamp > %@", NSDate(timeIntervalSince1970: from.timeIntervalSince1970))
            fetchRequest.predicate = predicate
            
        } else if let to = to, from == nil {
            let predicate = NSPredicate(format: "timeStamp < %@", NSDate(timeIntervalSince1970: to.timeIntervalSince1970))
            fetchRequest.predicate = predicate
            
        } else if let to = to, let from = from {
            let predicate = NSPredicate(format: "timeStamp < %@ AND timeStamp > %@", NSDate(timeIntervalSince1970: to.timeIntervalSince1970), NSDate(timeIntervalSince1970: from.timeIntervalSince1970))
            fetchRequest.predicate = predicate
        }
        
        var bgReadings = [BgReading]()
                
        managedObjectContext.performAndWait {
            do {
                // Execute Fetch Request
                bgReadings = try fetchRequest.execute()
                
            } catch {
                let fetchError = error as NSError
                BgReadingsAccessor.log.e("in getBgReadings, Unable to Execute BgReading Fetch Request: \(fetchError.localizedDescription)")
            }
        }
        
        return bgReadings
    }
    
    /// gets bgReadings, asynchronously, from main thread
    /// - parameters:
    ///     - to : if specified, only return readings with timestamp  smaller than fromDate (not equal to)
    ///     - from : if specified, only return readings with timestamp greater than fromDate (not equal to)
    func getBgReadingsAsync(from: Date?, to: Date?, completion: @escaping ([BgReading]?) -> Void) {
        
        let fetchRequest: NSFetchRequest<BgReading> = BgReading.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(BgReading.timeStamp), ascending: true)]

        // create predicate
        if let from = from, to == nil {
            let predicate = NSPredicate(format: "timeStamp > %@", NSDate(timeIntervalSince1970: from.timeIntervalSince1970))
            fetchRequest.predicate = predicate

        } else if let to = to, from == nil {
            let predicate = NSPredicate(format: "timeStamp < %@", NSDate(timeIntervalSince1970: to.timeIntervalSince1970))
            fetchRequest.predicate = predicate

        } else if let to = to, let from = from {
            let predicate = NSPredicate(format: "timeStamp < %@ AND timeStamp > %@", NSDate(timeIntervalSince1970: to.timeIntervalSince1970), NSDate(timeIntervalSince1970: from.timeIntervalSince1970))
            fetchRequest.predicate = predicate
        }
        
        let moc = CoreDataManager.shared.privateChildManagedObjectContext()
        moc.perform {
            do {
                let bgReadings = try fetchRequest.execute()
                
                DispatchQueue.main.async {
                    var ret = [BgReading]()
                    let mmoc = CoreDataManager.shared.mainManagedObjectContext
                    bgReadings.forEach { reading in
                        if let copy = mmoc.object(with: reading.objectID) as? BgReading {
                            ret.append(copy)
                        }
                    }
                    completion(ret)
                }

            } catch {
                let fetchError = error as NSError
                BgReadingsAccessor.log.e("in getBgReadings, Unable to Execute BgReading Fetch Request: \(fetchError.localizedDescription)")
            }
        }
    }
    
    /// deletes bgReading, synchronously, in the managedObjectContext's thread
    ///     - bgReading : bgReading to delete
    ///     - managedObjectContext : the ManagedObjectContext to use
    func delete(bgReading: BgReading, on managedObjectContext: NSManagedObjectContext) {
        managedObjectContext.performAndWait {
            managedObjectContext.delete(bgReading)
            
            // save changes to coredata
            do {
                try managedObjectContext.save()
                
            } catch {
                BgReadingsAccessor.log.e("in delete bgReading,  Unable to Save Changes, error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - private helper functions
    
    /// returnvalue can be empty array
    /// - parameters:
    ///     - limit: maximum amount of readings to fetch, if 0 then no limit
    ///     - fromDate : if specified, only return readings with timestamp > fromDate
    /// - returns:
    ///     List of readings, descending, ie first is youngest
    private func fetchBgReadings(limit: Int?, fromDate: Date?) -> [BgReading] {
        let fetchRequest: NSFetchRequest<BgReading> = BgReading.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(BgReading.timeStamp), ascending: false)]
        
        // if fromDate specified then create predicate
        if let fromDate = fromDate {
            let predicate = NSPredicate(format: "timeStamp > %@", NSDate(timeIntervalSince1970: fromDate.timeIntervalSince1970))
            fetchRequest.predicate = predicate
        }
        
        // set fetchLimit
        if let limit = limit, limit >= 0 {
            fetchRequest.fetchLimit = limit
        }
        
        var bgReadings = [BgReading]()
        
        CoreDataManager.shared.mainManagedObjectContext.performAndWait {
            do {
                // Execute Fetch Request
                bgReadings = try fetchRequest.execute()
                
            } catch {
                let fetchError = error as NSError
                BgReadingsAccessor.log.e("in fetchBgReadings, Unable to Execute BgReading Fetch Request : \(fetchError.localizedDescription)")
            }
        }
        
        return bgReadings
    }
}
