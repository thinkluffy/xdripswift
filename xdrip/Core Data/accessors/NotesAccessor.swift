//
//  NotesAccessor.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/12/20.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import Foundation
import os
import CoreData

class NotesAccessor {
    
    private static let log = Log(type: NotesAccessor.self)

    func getNotesAsync(from: Date?, to: Date?, completion: @escaping ([Note]?) -> Void) {
        
        let fetchRequest: NSFetchRequest<Note> = Note.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Note.timeStamp), ascending: false)]

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
                let notes = try fetchRequest.execute()
                
                DispatchQueue.main.async {
                    var ret = [Note]()
                    let mmoc = CoreDataManager.shared.mainManagedObjectContext
                    notes.forEach { reading in
                        if let copy = mmoc.object(with: reading.objectID) as? Note {
                            ret.append(copy)
                        }
                    }
                    completion(ret)
                }

            } catch {
                let fetchError = error as NSError
                NotesAccessor.log.e("Unable to Execute Note Fetch Request: \(fetchError.localizedDescription)")
            }
        }
    }
    
    func getNotes(from: Date?, to: Date?, on managedObjectContext: NSManagedObjectContext) -> [Note] {
        
        let fetchRequest: NSFetchRequest<Note> = Note.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Note.timeStamp), ascending: false)]
        
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
        
        var notes = [Note]()
        
        managedObjectContext.performAndWait {
            do {
                // Execute Fetch Request
                notes = try fetchRequest.execute()
                
            } catch {
                let fetchError = error as NSError
                NotesAccessor.log.e("Unable to Execute Note Fetch Request: \(fetchError.localizedDescription)")
            }
        }
        
        return notes
    }
    
    func delete(note: Note, on managedObjectContext: NSManagedObjectContext) {
        managedObjectContext.performAndWait {
            managedObjectContext.delete(note)
            
            do {
                try managedObjectContext.save()
                
            } catch {
                NotesAccessor.log.e("Unable to Save Changes, error: \(error.localizedDescription)")
            }
        }
    }
    
    func deleteMissedReadsing(on managedObjectContext: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Note> = Note.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Note.timeStamp), ascending: false)]
        
        let predicate = NSPredicate(format: "noteType = %d", NoteManager.NoteType.missedReading.rawValue)
        fetchRequest.predicate = predicate
        
        var notes = [Note]()
        
        managedObjectContext.performAndWait {
            do {
                // Execute Fetch Request
                notes = try fetchRequest.execute()
                
                notes.forEach { note in
                    managedObjectContext.delete(note)
                }
                try managedObjectContext.save()
                
            } catch {
                let fetchError = error as NSError
                NotesAccessor.log.e("Unable to Execute Note Fetch Request: \(fetchError.localizedDescription)")
            }
        }
    }
}
