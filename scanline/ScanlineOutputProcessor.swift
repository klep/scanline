//
//  This code is part of scanline and published under MIT license.
//

import Foundation
import ImageCaptureCore
import AppKit
import Quartz

class ScanlineOutputProcessor {
    let logger: Logger
    let configuration: ScanConfiguration
    let urls: [URL]
    
    init(urls: [URL], configuration: ScanConfiguration, logger: Logger) {
        self.urls = urls
        self.configuration = configuration
        self.logger = logger
    }
    
    func process() -> Bool {
        var outputUrls = [URL]()
        if configuration.jpegOutput {
            for url in urls {
                guard updateImage(at: url),
                    let outputUrl = outputAndTag(url: url) else {
                    logger.log("Error while creating image")
                    return false
                }
                outputUrls.append(outputUrl)
            }
        } else {
            // Combine into a single PDF
            guard let combinedURL = combineToPdf(urls: urls),
                let outputUrl = outputAndTag(url: combinedURL) else {
                logger.log("Error while creating PDF")
                return false
            }
            outputUrls.append(outputUrl)
        }
                
        if configuration.shouldOpenAfterScan {
            logger.verbose("Opening file(s) at \(outputUrls)")
            NSWorkspace.shared.open(outputUrls, withAppBundleIdentifier: nil, options: NSWorkspace.LaunchOptions.default, additionalEventParamDescriptor: nil, launchIdentifiers: nil)
        }
        
        return true
    }
    
    func updateImage(at url: URL) -> Bool {
        guard var image = NSImage(contentsOf: url) else {
            logger.log("Failed to read temporary image from $\(url)!")
            return false
        }
        if configuration.autoTrimEnabled {
            image = image.trimmed(withInsets: configuration.insets)
        }
        let data = image.jpgRepresentation(withCreationDate: configuration.creationDate, quality: configuration.quality)
        do {
            try data?.write(to: url, options: .atomicWrite)
        } catch {
            logger.log("Failed to write jpg")
            return false
        }
        return true
    }
    
    func combineToPdf(urls: [URL]) -> URL? {
        let document = PDFDocument()
        
        for url in urls {
            var page: NSImage = NSImage(byReferencing: url)
            if configuration.autoTrimEnabled {
                page = page.trimmed(withInsets: configuration.insets)
            }
            if let page = PDFPage(image: page) {
                document.insert(page, at: document.pageCount)
            }
        }
        
        let tempFilePath = "\(NSTemporaryDirectory())/scan.pdf"
        document.write(toFile: tempFilePath)
        
        return URL(fileURLWithPath: tempFilePath)
    }

    func outputAndTag(url: URL) -> URL? {
        let gregorian = NSCalendar(calendarIdentifier: .gregorian)!
        let dateComponents = gregorian.components([.year, .hour, .minute, .second], from: Date())
        
        let outputRootDirectory = configuration.outputRootDir
        var path = outputRootDirectory
        
        // If there's a tag, move the file to the first tag location
        if configuration.tags.count > 0 {
            path = "\(path)/\(configuration.tags[0])/\(dateComponents.year!.fld())"
        }
        
        logger.verbose("Output path: \(path)")

        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        } catch {
            logger.log("Error while creating directory \(path)")
            return nil
        }
        let destinationFileExtension = (configuration.jpegOutput ? "jpg" : "pdf")
        
        let basename = configuration.outputFileName ??  "scan_\(dateComponents.hour!.f02ld())\(dateComponents.minute!.f02ld())\(dateComponents.second!.f02ld())"
        
        let destinationFilePath = findOutputFilePath(in: path, withBasename: basename, withExtension: destinationFileExtension)
        
        logger.verbose("About to copy \(url.absoluteString) to \(destinationFilePath)")

        let destinationURL = URL(fileURLWithPath: destinationFilePath)
        do {
            try FileManager.default.copyItem(at: url, to: destinationURL)
        } catch {
            logger.log("Error while copying file to \(destinationURL.absoluteString)")
            return nil
        }

        // Alias to all other tag locations
        if configuration.tags.count > 1 {
            for tag in configuration.tags.subarray(with: NSMakeRange(1, configuration.tags.count - 1)) {
                logger.verbose("Aliasing to tag \(tag)")
                let aliasDirPath = "\(outputRootDirectory)/\(tag)/\(dateComponents.year!.fld())"
                do {
                    try FileManager.default.createDirectory(atPath: aliasDirPath, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    logger.log("Error while creating directory \(aliasDirPath)")
                    return nil
                }
                
                let aliasFilePath = findOutputFilePath(in: aliasDirPath, withBasename: basename, withExtension: destinationFileExtension)
                logger.verbose("Aliasing to \(aliasFilePath)")
                do {
                    try FileManager.default.createSymbolicLink(atPath: aliasFilePath, withDestinationPath: destinationFilePath)
                } catch {
                    logger.log("Error while creating alias at \(aliasFilePath)")
                    return nil
                }
            }
        }
        
        return destinationURL
    }
    
    func findOutputFilePath(in dir: String, withBasename basename: String, withExtension fileExtension: String) -> String {
        let destinationFileRoot = "\(dir)/\(basename)"
        
        var destinationFilePath = "\(destinationFileRoot).\(fileExtension)"
        var i = 0
        while FileManager.default.fileExists(atPath: destinationFilePath) {
            destinationFilePath = "\(destinationFileRoot).\(i).\(fileExtension)"
            i += 1
        }
        return destinationFilePath
    }
}
