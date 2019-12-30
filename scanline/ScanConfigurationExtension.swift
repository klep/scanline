//
//  File.swift
//  scanline
//
//  Created by Florian Dreier on 12/30/19.
//  Copyright © 2019 Scott J. Kleper. All rights reserved.
//

import Foundation

extension ScanConfiguration {
    
    var resolution: Int {
        return Int(self.config[ScanlineConfigOptionResolution] as? String ?? "150") ?? 150
    }
    
    var duplex: Bool {
        return self.config[ScanlineConfigOptionDuplex] != nil
    }
    
    var isA4: Bool {
        return self.config[ScanlineConfigOptionA4] != nil
    }
    
    var isLegal: Bool {
        return self.config[ScanlineConfigOptionLegal] != nil
    }
    
    var batchScan: Bool {
        return self.config[ScanlineConfigOptionBatch] != nil
    }
    
    var flatbed: Bool {
        return self.config[ScanlineConfigOptionFlatbed] != nil
    }
    
    var mono: Bool {
        return self.config[ScanlineConfigOptionMono] != nil
    }
    
    var jpegOutput: Bool {
        return self.config[ScanlineConfigOptionJPEG] != nil
    }
    
    var outputFileName: String? {
        return self.config[ScanlineConfigOptionName] as? String
    }
    
    var outputRootDir: String {
        return self.config[ScanlineConfigOptionDir] as! String
    }
    
    var shouldOpenAfterScan: Bool {
        return self.config[ScanlineConfigOptionOpen] != nil
    }
    
    var waitSeconds: Double {
        return Double(self.config[ScanlineConfigOptionBrowseSecs] as? String ?? "10") ?? 10.0
    }
    
    var list: Bool {
        return self.config[ScanlineConfigOptionList] != nil
    }
    
    var area: (width: CGFloat, height: CGFloat)? {
        if let sizeString = self.config[ScanlineConfigOptionArea] as? String {
            let size = sizeString.components(separatedBy: "x")
            return (width: CGFloat(Float(size[0])!), height: CGFloat(Float(size[1])!))
        } else {
            return nil
        }
    }
}
