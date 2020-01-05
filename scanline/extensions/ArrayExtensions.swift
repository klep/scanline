//
//  This code is part of scanline and published under MIT license.
//

import Foundation

extension Array {
    subscript(safe range: Range<Index>) -> ArraySlice<Element> {
        return self[Swift.min(range.startIndex, self.endIndex)..<Swift.min(range.endIndex, self.endIndex)]
    }
}
