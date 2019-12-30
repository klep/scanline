//
//  ArrayExtensions.swift
//  scanline
//
//  Created by Florian Dreier on 12/30/19.
//  Copyright © 2019 Scott J. Kleper. All rights reserved.
//

import Foundation

extension Array where Iterator.Element == Int {
    
    func doesValueAroundIndexPassFivePercent(index: Int, total: Int) -> Bool {
        let threshold = Int(Double(total) * 0.05)
        let lowIndex = Swift.max(Int(Double(index) - Double(total) * 0.01), 0)
        return areAllValuesInRangeAbove(range: lowIndex ... index, threshold: threshold)
    }
    
    func areAllValuesInRangeAbove(range: ClosedRange<Int>, threshold: Int) -> Bool {
        return range.allSatisfy({self[$0] > threshold})
    }
}
