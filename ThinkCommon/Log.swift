//
//  Log.swift
//  Unarchiver
//
//  Created by liujiaqi on 2019/8/16.
//  Copyright © 2019 liujiaqi. All rights reserved.
//

import CocoaLumberjack

public class Log {
    
    public enum Level: Int {
        case verbose = 0
        case debug = 1
        case info = 2
        case warning = 3
        case error = 4
        case off = 5
    }
    
    public static var level = Level.warning
    
    public let tag: String
    
    init(tag: String) {
        self.tag = tag
    }
    
    convenience init<Subject>(type: Subject) {
        self.init(tag: String(describing: type))
    }
    
    public static func setup(level: Level = .warning) {
        DDLog.add(DDOSLogger.sharedInstance) // Uses os_log
        DDOSLogger.sharedInstance.logFormatter = ClearLogFormatter()
        Log.level = level
        
        let manager = FileManager.default
        let urlForDocument = manager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let logFileManger = DDLogFileManagerDefault(logsDirectory: urlForDocument.relativePath)
        
        let fileLogger: DDFileLogger = DDFileLogger(logFileManager: logFileManger)
        fileLogger.rollingFrequency = TimeInterval(60 * 60 * 24)  // 24 hours
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
        DDLog.add(fileLogger)
    }
    
    public func v(_ msg: String, file: StaticString = #file, line: UInt = #line) {
        guard Log.level.rawValue <= Level.verbose.rawValue else {
            return
        }
        DDLogVerbose("[\(tag)] \(msg)", file: file, line: line)
    }
    
    public func d(_ msg: String, file: StaticString = #file, line: UInt = #line) {
        guard Log.level.rawValue <= Level.debug.rawValue else {
            return
        }
        DDLogDebug("[\(tag)] \(msg)", file: file, line: line)
    }
    
    @inlinable
    public func i(_ msg: String, file: StaticString = #file, line: UInt = #line) {
        guard Log.level.rawValue <= Level.info.rawValue else {
            return
        }
        DDLogInfo("[\(tag)] \(msg)", file: file, line: line)
    }
    
    public func w(_ msg: String, file: StaticString = #file, line: UInt = #line) {
        guard Log.level.rawValue <= Level.warning.rawValue else {
            return
        }
        DDLogWarn("[\(tag)] \(msg)", file: file, line: line)
    }
    
    public func e(_ msg: String, file: StaticString = #file, line: UInt = #line) {
        guard Log.level.rawValue <= Level.error.rawValue else {
            return
        }
        DDLogError("[\(tag)] \(msg)", file: file, line: line)
    }
    
    private class ClearLogFormatter: NSObject, DDLogFormatter {
        
        func format(message logMessage: DDLogMessage) -> String? {
            var levelTag: String?
            switch logMessage.flag {
            case DDLogFlag.debug:
                levelTag = "D"
            case DDLogFlag.info:
                levelTag = "I"
            case DDLogFlag.warning:
                levelTag = "W"
            case DDLogFlag.error:
                levelTag = "E"
            case DDLogFlag.verbose:
                levelTag = "V"
            default:
                levelTag = "U"
            }
            return "[\(levelTag!)] \(logMessage.message) (\(logMessage.fileName):\(logMessage.line))"
        }
    }
}

