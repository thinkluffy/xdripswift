import Foundation
import CoreData
import os

class SnoozeParametersAccessor {
    
    // MARK: - Properties
        
    /// for logging
    private var log = OSLog(subsystem: ConstantsLog.subSystem, category: ConstantsLog.categoryApplicationDataSnoozeParameter)
    
   
    // MARK: Public functions
    
    /// - gets all SnoozeParameters instances from coredata
    /// - if this the first call to this function (ie no SnoozeParameters stored yet in coredata), then they will be created for every AlertKind
    /// - sorts them by AlertKind.rawvalue (from low to high), ie from 0 to (verylow) to 8 (fastrise)
    func getSnoozeParameters() -> [SnoozeParameters] {
        
        // create fetchRequest to get SnoozeParameters's as SnoozeParameters classes
        let snoozeParametersFetchRequest: NSFetchRequest<SnoozeParameters> = SnoozeParameters.fetchRequest()
        
        // sort by alertkind from low to high
        snoozeParametersFetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(SnoozeParameters.alertKind), ascending: true)]
        
        // fetch the SnoozeParameterss
        var snoozeParameterArray = [SnoozeParameters]()
        CoreDataManager.shared.mainManagedObjectContext.performAndWait {
            do {
                // Execute Fetch Request
                snoozeParameterArray = try snoozeParametersFetchRequest.execute()
            } catch {
                let fetchError = error as NSError
                trace("in getSnoozeParameterss, Unable to Execute SnoozeParameterss Fetch Request : %{public}@", log: self.log, category: ConstantsLog.categoryApplicationDataSnoozeParameter, type: .error, fetchError.localizedDescription)
            }
        }
        
        // snoozeParameters are ordered by alertKind so goes from 0 to highest value
        // but maybe some (or all) are missing
        // if some are missing, then it's either because it's the first time this app runs
        // or it's because new alertKind's have been added, in which case it's at the end of the range they are added
        for index in snoozeParameterArray.count ..< AlertKind.allCases.count {
            if let alertKind = AlertKind(rawValue: index) {
                snoozeParameterArray.append(SnoozeParameters(alertKind: alertKind,
                                                             snoozePeriodInMinutes: 0,
                                                             snoozeTimeStamp: nil,
                                                             nsManagedObjectContext: CoreDataManager.shared.mainManagedObjectContext))
                
            }
        }
        return snoozeParameterArray
    }
}
