//
//  Logger.swift
//  core-ios-sdk
//
//  Created by Atul Manwar on 31/05/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation

public protocol AbstractLogger: class {
    func logDebug(_ message: String, context: Int, file: StaticString, function: StaticString, line: UInt)
    func logInfo(_ message: String, context: Int, file: StaticString, function: StaticString, line: UInt)
    func logWarning(_ message: String, context: Int, file: StaticString, function: StaticString, line: UInt)
    func logError(_ message: String, context: Int, file: StaticString, function: StaticString, line: UInt)
    func log(_ message: String, context: Int, level: LogLevel, file: StaticString, function: StaticString, line: UInt)
    func retrieveLogs() -> [Data]
}

extension AbstractLogger {
    public func logDebug(_ message: String, context: Int, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
        logDebug(message, context: context, file: file, function: function, line: line)
    }
    
    public func logInfo(_ message: String, context: Int, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
        logInfo(message, context: context, file: file, function: function, line: line)
    }
    
    public func logWarning(_ message: String, context: Int, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
        logWarning(message, context: context, file: file, function: function, line: line)
    }
    
    public func logError(_ message: String, context: Int, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
        logError(message, context: context, file: file, function: function, line: line)
    }
    
    public func log(_ message: String, context: Int, level: LogLevel, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
        log(message, context: context, level: level, file: file, function: function, line: line)
    }
}

public enum LogLevel: Int {
    case debug
    case info
    case warning
    case error
}

public final class LoggerWrapper {
    internal (set) lazy var lumberJack: LumberJackLogger = {
        return LumberJackLogger()
    }()
}


public final class LumberJackLogger {
    internal let logger: DDFileLogger
    
    public init() {
        logger = DDFileLogger()
        logger.rollingFrequency = TimeInterval(60*60*24)
        logger.logFileManager.maximumNumberOfLogFiles = 7
        logger.logFormatter = LogFormatter()
        DDLog.add(logger)
    }
}

extension LumberJackLogger: AbstractLogger {
    public func logDebug(_ message: String, context: Int, file: StaticString, function: StaticString, line: UInt) {
        DDLogDebug(message, context: context, file: file, function: function, line: line)
    }
    
    public func logInfo(_ message: String, context: Int, file: StaticString, function: StaticString, line: UInt) {
        DDLogInfo(message, context: context, file: file, function: function, line: line)
    }
    
    public func logWarning(_ message: String, context: Int, file: StaticString, function: StaticString, line: UInt) {
        DDLogWarn(message, context: context, file: file, function: function, line: line)
    }
    
    public func logError(_ message: String, context: Int, file: StaticString, function: StaticString, line: UInt) {
        DDLogError(message, context: context, file: file, function: function, line: line)
    }

    public func log(_ message: String, context: Int, level: LogLevel, file: StaticString, function: StaticString, line: UInt) {
        switch level {
        case .debug:
            DDLogDebug(message, context: context, file: file, function: function, line: line)
        case .info:
            DDLogInfo(message, context: context, file: file, function: function, line: line)
        case .warning:
            DDLogWarn(message, context: context, file: file, function: function, line: line)
        case .error:
            DDLogError(message, context: context, file: file, function: function, line: line)
        }
        //TODO: Remove this
//        debugPrint(message)
    }
    
    public func retrieveLogs() -> [Data] {
        guard let paths = logger.logFileManager.sortedLogFilePaths else { return [] }
        return paths.compactMap({ try? Data(contentsOf: URL(fileURLWithPath: $0)) })
    }
}

class LogFormatter: NSObject, DDLogFormatter {
    let separator = " | "
    
    override init() {
        super.init()
    }
    
    func format(message logMessage: DDLogMessage) -> String? {
        return [DateFormatter.iso8601Full.string(from: logMessage.timestamp), logMessage.level.description, logMessage.fileName, "\(logMessage.line)", logMessage.function ?? "", logMessage.message].joined(separator: separator)
    }
}

extension DDLogLevel {
    var description: String {
        switch self {
        case .all:
            return "ALL"
        case .debug:
            return "DEBUG"
        case .error:
            return "ERROR"
        case .info:
            return "INFO"
        case .off:
            return "OFF"
        case .verbose:
            return "VERBOSE"
        case .warning:
            return "WARNING"
        }
    }
}
