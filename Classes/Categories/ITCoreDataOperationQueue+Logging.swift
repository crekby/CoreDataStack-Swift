//
//  ITCoreDataOperationQueue+Logging.swift
//  CoreDataStack-Swift
//
//  Created by Aliaksandr Skulin on 1/12/16.
//  Copyright © 2016 Aliaksandr Skulin. All rights reserved.
//

import UIKit

extension ITCoreDataOperationQueue {
    
    public struct ITLogLevel : OptionSetType {
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        static let None         = ITLogLevel(rawValue: 0)
        static let Messages     = ITLogLevel(rawValue: 1 << 0)
        static let Warnings     = ITLogLevel(rawValue: 1 << 1)
        static let Errors       = ITLogLevel(rawValue: 1 << 2)
        static let All          = ITLogLevel(rawValue: 7)
    }
    
    public func setLogLevel(logLevel: ITLogLevel) {
        if (logLevel != self.loggingLevel) {
            self.loggingLevel = logLevel
        }
    }

    func logMessage(message: String) {
        if (self.loggingLevel.contains(.Messages)) {
            self.log(message)
        }
    }
    
    func logWarning(warning: String) {
        if (self.loggingLevel.contains(.Warnings)) {
            self.log(warning)
        }
    }
    
    func logError(error: NSError?) {
        if (error == nil) {
            return
        }
        if (self.loggingLevel.contains(.Errors)) {
            self.log("\(error!)")
        }
    }
    
    //MARK: - Private
    
    private func log(string: String) {
        print("[ITCoreDataOperationQueue]: \(string)")
    }
}
