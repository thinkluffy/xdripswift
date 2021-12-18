//
//  NotesContract.swift
//  xdrip
//
//  Created by Yuanbin Cai on 2021/12/18.
//  Copyright © 2021 Johan Degraeve. All rights reserved.
//

import Foundation

protocol NotesV: MVPV {
    
}

protocol NotesP: MVPP {
    
    func loadData(date: Date)
    
}
