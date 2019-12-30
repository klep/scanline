//
//  IntExtensions.swift
//  scanline
//
//  Created by Florian Dreier on 12/30/19.
//  Copyright © 2019 Scott J. Kleper. All rights reserved.
//

import Foundation

extension Int {
    // format to 2 decimal places
    func f02ld() -> String {
        return String(format: "%02ld", self)
    }
    
    func fld() -> String {
        return String(format: "%ld", self)
    }
}
