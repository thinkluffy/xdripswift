//
//  NoteManager.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/12/20.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import Foundation


class NoteManager {
    
    enum NoteType: Int {
        case urgentLow = 0
        case low = 1
        case high = 2
        case urgentHigh = 3
        case fastDrop = 4
        case fastRise = 5
        case userInputText = 6
        
        func toString() -> String {
            switch self {
            case .urgentLow:
                return "Urgent Low"
            case .low:
                return "Low"
            case .high:
                return "High"
            case .urgentHigh:
                return "Urgent High"
            case .fastDrop:
                return "Drop Fast"
            case .fastRise:
                return "Rise Fast"
            case .userInputText:
                return "Input Text"
            }
        }
    }
    
    private static let log = Log(type: NoteManager.self)
    
    static let shared = NoteManager()
    
    private static func alertKindToNoteType(alertKind: AlertKind) -> NoteType? {
        switch alertKind {
        case .verylow:
            return .urgentLow
        case .low:
            return .low
        case .high:
            return .high
        case .veryhigh:
            return .urgentHigh
        case .fastrise:
            return .fastRise
        case .fastdrop:
            return .fastDrop
        default:
            return nil
        }
    }
    
    func saveAlertNoteIfNeeded(alertKind: AlertKind, bgReading: BgReading?) {
        
        guard let noteType = NoteManager.alertKindToNoteType(alertKind: alertKind) else {
            NoteManager.log.i("Not an interest alert kind")
            return
        }
        
        _ = Note(
            timeStamp: Date(),
            noteType: noteType,
            bg: bgReading?.calculatedValue ?? 0,
            slopeArrow: bgReading?.slopArrow,
            noteContent: nil,
            nsManagedObjectContext: CoreDataManager.shared.mainManagedObjectContext
        )
        
        do {
            try CoreDataManager.shared.mainManagedObjectContext.save()
            
        } catch let error {
            NoteManager.log.e("Fail to save Note, \(error.localizedDescription)")
        }
    }
    
    func saveUserInputNote(inputText: String, bgReading: BgReading?) {
        
        _ = Note(
            timeStamp: Date(),
            noteType: .userInputText,
            bg: bgReading?.calculatedValue ?? 0,
            slopeArrow: bgReading?.slopArrow,
            noteContent: inputText,
            nsManagedObjectContext: CoreDataManager.shared.mainManagedObjectContext
        )
        
        do {
            try CoreDataManager.shared.mainManagedObjectContext.save()
            
        } catch let error {
            NoteManager.log.e("Fail to save Note, \(error.localizedDescription)")
        }
    }
}
