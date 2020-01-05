//
//  This code is part of scanline and published under MIT license.
//

import Foundation

/// Describes insets that can be applied to a rectangle.
struct Insets {
    
    let left: CGFloat
    let right: CGFloat
    let top: CGFloat
    let bottom: CGFloat
    
    init(left: Double, top: Double, right: Double, bottom: Double) {
        self.left = CGFloat(left)
        self.top = CGFloat(top)
        self.right = CGFloat(right)
        self.bottom = CGFloat(bottom)
    }
    
    init(fromString insets: String) {
        let insetValues = insets.split(separator: ":")
        self.init(left: Double(insetValues[0])!, top: Double(insetValues[1])!, right: Double(insetValues[2])!, bottom: Double(insetValues[1])!)
    }
}
