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
    
    /// Applies the given insets to the rect and returns the new rect
    func insetted(with insets: Insets) -> CGRect {
        return CGRect(x: self.minX + insets.left, y: self.minY + insets.top, width: self.width - insets.left - insets.right, height: self.height - insets.top - insets.bottom)
    }
}
