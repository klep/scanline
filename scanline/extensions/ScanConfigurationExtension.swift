//
//  This code is part of scanline and published under MIT license.
//

import Foundation

extension ScanConfiguration {
    
    private let logger = Logger(configuration: self)
    
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
    
    var scannerName: String? {
        return self.config[ScanlineConfigOptionScanner] as? String
    }
    
    var exactName: Bool {
        return self.config[ScanlineConfigOptionExactName] != nil
    }
    
    var area: (width: CGFloat, height: CGFloat)? {
        if let sizeString = self.config[ScanlineConfigOptionArea] as? String {
            let size = sizeString.components(separatedBy: "x")
            guard (size.count != 2) {
                logger.log("Area $\(sizeString) does not match the expected format. It is expected to be <width>x<height>. You are missing the x separator.")
                return nil
            }
            guard let width = Float(size[0]),
                let height = Float(size[1]) else {
                logger.log("Area $\(sizeString) does not match the expected format. The given width or height is not a valid number.")
                return nil
            }
            if (!self.flatbed) {
                logger.log("The -area option does have no effect. It is only used when specified together with -flatbed.")
            }
            return (width: CGFloat(width), height: CGFloat(height))
        } else {
            return nil
        }
    }
    
    var creationDate: Date? {
        if let dateString = self.config[ScanlineConfigOptionCreationDate] as? String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy:MM:dd"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            return dateFormatter.date(from: dateString)
        } else {
            return nil
        }
    }
    
    var autoTrimEnabled: Bool {
        return self.config[ScanlineConfigOptionAutoTrim] != nil
    }
    
    var insets: Insets? {
        if let insetsSpec = self.config[ScanlineConfigOptionInsets] as? String {
            return Insets(fromString: insetsSpec)
        } else {
            return nil
        }
    }
    
    var quality: Double {
        if let qualityString = self.config[ScanlineConfigOptionQuality] as? String {
            guard let quality = Int(quality) else {
                logger.log("$\(qualityString) is not a valid number!")
                return 90.0
            }
            return Double(quality) / 100.0
        } else {
            return 90.0
        }
    }
}
