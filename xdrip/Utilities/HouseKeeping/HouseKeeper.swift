import Foundation
import os
import CoreData

/// housekeeping like remove old readings from coredata
class HouseKeeper {
    
    // MARK: - private properties
    
    /// for logging
    private var log = OSLog(subsystem: ConstantsLog.subSystem, category: ConstantsLog.categoryHouseKeeper)
    
    /// BgReadingsAccessor instance
    private var bgReadingsAccessor: BgReadingsAccessor
    
    /// CalibrationsAccessor instance
    private var calibrationsAccessor: CalibrationsAccessor
    
    private var notesAccessor: NotesAccessor

    // up to which date shall we delete old calibrations
    private var toDate: Date

    // MARK: - intializer
    
    init() {
        bgReadingsAccessor = BgReadingsAccessor()
        calibrationsAccessor = CalibrationsAccessor()
        notesAccessor = NotesAccessor()
        
        toDate = Date(timeIntervalSinceNow: -ConstantsHousekeeping.retentionPeriodBgReadingsAndCalibrationsInDays * 24 * 3600)
    }
    
    // MARK: - public functions
    
    /// - housekeeping activities to be done only once per app start up like delete old readings and calibrations in CoreData
    /// - cleanups are done asynchronously (ie function returns without waiting for the actual deletions
    public func doAppStartUpHouseKeeping() {
        // create private managed object context
        let moc = CoreDataManager.shared.privateChildManagedObjectContext()

        // delete old readings on the private managedObjectContext, asynchronously
        moc.perform {
            // delete old readings
            self.deleteOldReadings(on: moc)
        }
        
        // delete old calibrations on the private managedObjectContext, asynchronously
        moc.perform {
            // delete old calibrations
            self.deleteOldCalibrations(on: moc)
        }
        
        // delete old notes on the private managedObjectContext, asynchronously
        moc.perform {
            // delete old notes
            self.deleteOldNotes(on: moc)
        }
    }
    
    // MARK: - private functions
    
    /// deletes old readings. Readings older than ConstantsHousekeeping.retentionPeriodBgReadingsInDays will be deleted
    ///     - managedObjectContext : the ManagedObjectContext to use
    private func deleteOldReadings(on managedObjectContext: NSManagedObjectContext) {
        
        // get old readings to delete
        let oldReadings = self.bgReadingsAccessor.getBgReadings(from: nil, to: self.toDate, on: managedObjectContext)
        
        if oldReadings.count > 0 {
            
            trace("in deleteOldReadings, number of bg readings to delete : %{public}@, to date = %{public}@", log: self.log, category: ConstantsLog.categoryHouseKeeper, type: .info, oldReadings.count.description, self.toDate.description(with: .current))
            
        }
        
        // delete them
        for oldReading in oldReadings {
            bgReadingsAccessor.delete(bgReading: oldReading, on: managedObjectContext)
            CoreDataManager.shared.saveChanges()
        }
    }
    
    /// deletes old calibrations. Readings older than ConstantsHousekeeping.retentionPeriodBgReadingsInDays will be deleted
    private func deleteOldCalibrations(on managedObjectContext: NSManagedObjectContext) {
        // get old calibrations to delete
        let oldCalibrations = self.calibrationsAccessor.getCalibrations(from: nil, to: self.toDate, on: managedObjectContext)
        
        if oldCalibrations.count > 0 {
            trace("in deleteOldCalibrations, number of calibrations candidate for deletion : %{public}@, to date = %{public}@", log: self.log, category: ConstantsLog.categoryHouseKeeper, type: .info, oldCalibrations.count.description, self.toDate.description(with: .current))
        }
        
        // for each calibration that doesn't have any bg readings anymore, delete it
        for oldCalibration in oldCalibrations {
            if (oldCalibration.bgreadings.count > 0 ) {
                trace("in deleteOldCalibrations, calibration with date %{public}@ will not be deleted beause there's still %{public}@ bgreadings", log: self.log, category: ConstantsLog.categoryHouseKeeper, type: .info, oldCalibration.timeStamp.description(with: .current), oldCalibration.bgreadings.count.description)

            } else {
                calibrationsAccessor.delete(calibration: oldCalibration, on: managedObjectContext)
                CoreDataManager.shared.saveChanges()
            }
        }
    }
    
    /// deletes old notes. Notes older than ConstantsHousekeeping.retentionPeriodBgReadingsInDays will be deleted
    private func deleteOldNotes(on managedObjectContext: NSManagedObjectContext) {
        // get old notes to delete
        let oldNotes = self.notesAccessor.getNotes(from: nil, to: self.toDate, on: managedObjectContext)
        
        if oldNotes.count > 0 {
            trace("in deleteOldNotes, number of notes candidate for deletion : %{public}@, to date = %{public}@", log: self.log, category: ConstantsLog.categoryHouseKeeper, type: .info, oldNotes.count.description, self.toDate.description(with: .current))
        }
        
        // delete them
        for oldNote in oldNotes {
            notesAccessor.delete(note: oldNote, on: managedObjectContext)
            CoreDataManager.shared.saveChanges()
        }
    }
}
