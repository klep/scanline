//
//  This code is part of scanline and published under MIT license.
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
