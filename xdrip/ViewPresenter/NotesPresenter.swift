//
//  NotesPresenter.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/12/18.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import Foundation
import SwiftEventBus

class NotesPresenter: NotesP {
  
    private static let log = Log(type: NotesPresenter.self)

    private weak var view: NotesV?
    
    private let notesAccessor = NotesAccessor()
    
    init(view: NotesV) {
        self.view = view
    }
    
    func onViewDidAppear() {
        SwiftEventBus.onMainThread(self, name: EventBusEvents.newNote) { [weak self] result in
            guard let view = self?.view else {
                return
            }
            
            if view.isShowingNotesOfToday {
                self?.loadData(date: Date())
            }
        }
    }
    
    func onViewWillDisappear() {
        SwiftEventBus.unregister(self)
    }
    
    func loadData(date: Date) {
        let fromDate = Calendar.current.startOfDay(for: date)
        let toDate = Date(timeInterval: Date.dayInSeconds, since: fromDate)
        
        notesAccessor.getNotesAsync(from: fromDate, to: toDate) {
            [weak self] (notes: [Note]?) in
            self?.view?.show(notes: notes, from: fromDate, to: toDate)
        }
    }
}
