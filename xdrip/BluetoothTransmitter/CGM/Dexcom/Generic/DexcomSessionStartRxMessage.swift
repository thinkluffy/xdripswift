//
//  DexcomG6SessionStartRxMessage.swift
//  xDrip
//
//  Created by Dmitry on 08.01.2021.
//  Copyright © 2021 Faifly. All rights reserved.
//
// adapted by Johan Degraeve

import Foundation

struct DexcomSessionStartRxMessage {
    
    let status: UInt8
    
    let sessionStartResponse: DexcomSessionStartResponse
    
    let requestedStartTime: Double
    
    let sessionStartTime: Double
    
    let transmitterTime: Double
    
    let transmitterStartDate: Date
    
    let sessionStartDate: Date
    
    let requestedStartDate: Date
    
    init?(data: Data) {
        //27 00 06 ca452400 04bc2300 42462400 e9eb
        guard data.count >= 15 else { return nil }
        
        guard data.starts(with: .sessionStartRx) else {return nil}

        status = data[1]

        guard let sessionStartResponseReceived = DexcomSessionStartResponse(rawValue: data[2]) else {return nil}
        
        sessionStartResponse = sessionStartResponseReceived

        requestedStartTime = Double(Data(data[3..<7]).to(UInt32.self))
        
        sessionStartTime = Double(Data(data[7..<11]).to(UInt32.self))
        
        transmitterTime = Double(Data(data[11..<15]).to(UInt32.self))
        
        transmitterStartDate = Date(timeIntervalSinceNow: -transmitterTime)
        
        sessionStartDate = transmitterStartDate.addingTimeInterval(sessionStartTime)
        
        requestedStartDate = transmitterStartDate.addingTimeInterval(requestedStartTime)
        
    }
}
