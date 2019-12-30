//
//  UIImageExtensions.swift
//  scanline
//
//  Created by Florian Dreier on 12/26/19.
//  Copyright © 2019 Scott J. Kleper. All rights reserved.
//

import Foundation
import Cocoa

extension CGRect {
    
    /// Returns the size of the rect as NSSize
    var size: NSSize {
        return NSSize(width: self.width, height: self.height)
    }
}
