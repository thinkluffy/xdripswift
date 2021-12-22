//
//  Note+CoreDataClass.swift
//  
//
//  Created by Yuanbin Cai on 2021/12/20.
//
//

import Foundation
import CoreData


public class Note: NSManagedObject {

    init(
        timeStamp: Date,
        noteType: NoteManager.NoteType,
        bg: Double?,
        slopeArrow: BgReading.SlopeArrow?,
        noteContent: String?,
        nsManagedObjectContext: NSManagedObjectContext
    ) {
        let entity = NSEntityDescription.entity(forEntityName: "Note", in: nsManagedObjectContext)!
        super.init(entity: entity, insertInto: nsManagedObjectContext)
        
        self.timeStamp = timeStamp
        self.noteType = Int16(noteType.rawValue)
        self.bg = bg ?? -1
        self.slopeArrow = Int16(slopeArrow?.rawValue ?? -1)
        self.noteContent = noteContent
    }
    
    private override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
}
