//
//  Note+CoreDataProperties.swift
//  
//
//  Created by Yuanbin Cai on 2021/12/20.
//
//

import Foundation
import CoreData


extension Note {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Note> {
        return NSFetchRequest<Note>(entityName: "Note")
    }

    @NSManaged public var timeStamp: Date
    @NSManaged public var noteType: Int16
    @NSManaged public var bg: Double
    @NSManaged public var slopeArrow: Int16
    @NSManaged public var hideSlope: Bool
    @NSManaged public var noteContent: String?

}
