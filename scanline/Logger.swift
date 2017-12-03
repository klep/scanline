//
//  Logger.swift
//  scanline
//
//  Created by Scott J. Kleper on 12/2/17.
//  Copyright © 2017 Scott J. Kleper. All rights reserved.
//

import Foundation

class Logger: NSObject {
    let configuration: ScanConfiguration
    
    init(configuration: ScanConfiguration) {
        self.configuration = configuration
        super.init()
    }
    
    func verbose(_ message: String) {
        guard configuration.config[ScanlineConfigOptionVerbose] != nil else { return }
        print(message)
    }
    
    func log(_ message: String) {
        print(message)
    }
}
