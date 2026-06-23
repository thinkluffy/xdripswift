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
        
        var snoozeParametersByAlertKind = [Int16: SnoozeParameters]()
        for snoozeParameter in snoozeParameterArray where snoozeParametersByAlertKind[snoozeParameter.alertKind] == nil {
            snoozeParametersByAlertKind[snoozeParameter.alertKind] = snoozeParameter
        }

        return AlertKind.allCases.map { alertKind in
            let alertKindRawValue = Int16(alertKind.rawValue)
            if let snoozeParameter = snoozeParametersByAlertKind[alertKindRawValue] {
                return snoozeParameter
            }

            return SnoozeParameters(alertKind: alertKind,
                                    snoozePeriodInMinutes: 0,
                                    snoozeTimeStamp: nil,
                                    nsManagedObjectContext: CoreDataManager.shared.mainManagedObjectContext)
        }
    }
}
