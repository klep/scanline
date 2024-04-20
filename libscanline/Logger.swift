//
//  Logger.swift
//  scanline
//
//  Created by Scott J. Kleper on 12/2/17.
//  Copyright © 2017 Scott J. Kleper. All rights reserved.
//

import Foundation

public class Logger: NSObject {
    let configuration: ScanConfiguration
    
    public init(configuration: ScanConfiguration) {
        self.configuration = configuration
        super.init()
    }
    
    public func verbose(_ message: String) {
        guard configuration.config[ScanlineConfigOptionVerbose] != nil else { return }
        print(message)
    }
    
    public func log(_ message: String) {
        if configuration.config[ScanlineConfigOptionOCR] != nil {
            // If we're outputting the scanned text to stdout, we should log all other messages to stderr
            fputs("\(message)\n", stderr)
        } else {
            print(message)
        }
    }
}
