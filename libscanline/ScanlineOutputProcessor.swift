//
//  ScanlineOutputProcessor.swift
//  libscanline
//
//  Created by Scott J. Kleper on 5/13/21.
//  Copyright © 2021 Scott J. Kleper. All rights reserved.
//

import Foundation
import AppKit
import Quartz
import Vision
import Carbon
import CoreImage

public class ScanlineOutputProcessor {
    let logger: Logger
    let configuration: ScanConfiguration
    let urls: [URL]
    
    public init(urls: [URL], configuration: ScanConfiguration, logger: Logger) {
        self.urls = urls
        self.configuration = configuration
        self.logger = logger
    }
    
    private func extractText(fromImageAt imageURL: URL) {
        let request = VNRecognizeTextRequest { (request, error) in
            let observations = request.results as? [VNRecognizedTextObservation] ?? []
            let strings: [String] = observations.map { $0.topCandidates(1).first?.string ?? ""}
            
            // Print directly to stdout
            print("\(strings.joined(separator: "\n"))")
        }
        
        request.recognitionLevel = .accurate
        request.revision = VNRecognizeTextRequestRevision3
        request.recognitionLanguages = ["en"]
        
        let requestHandler = VNImageRequestHandler(url: imageURL)
        do {
            try requestHandler.perform([request])
        } catch {
            logger.log("Error while performing text recognition")
        }
    }
    
    private func rotate(imageAt url: URL, byDegrees rotationDegrees: Int) -> Bool {
        guard let dataProvider = CGDataProvider(filename: url.path),
              let cgImage = CGImage(jpegDataProviderSource: dataProvider, decode: nil, shouldInterpolate: false, intent: .defaultIntent) else {
            return false
        }
        
        let ciImage = CIImage(cgImage: cgImage)
        
        let radians = CGFloat(rotationDegrees) / 180.0 * CGFloat(CGFloat.pi)
        let rotate = CGAffineTransform(rotationAngle: CGFloat(radians))
        let rotatedImage = ciImage.transformed(by: rotate)
        let context = CIContext(options: nil)
        
        guard let cgImage = context.createCGImage(rotatedImage, from: rotatedImage.extent),
              let mutableData = CFDataCreateMutable(nil, 0),
              let destination = CGImageDestinationCreateWithData(mutableData, UTType.jpeg.identifier as CFString, 1, nil) else { return false }
        
        CGImageDestinationAddImage(destination, cgImage, nil)
        if !CGImageDestinationFinalize(destination) {
            return false
        }
        do {
            try (mutableData as NSData).write(to: url)
        } catch {
            return false
        }

        return true
    }
    
    public func process() -> Bool {
        let wantsOCR = configuration.config[ScanlineConfigOptionOCR] != nil
        if wantsOCR {
            for url in urls {
                extractText(fromImageAt: url)
            }
        }
        
        if let rotationDegrees = Int(configuration.config[ScanlineConfigOptionRotate] as? String ?? "0"), rotationDegrees != 0 {
            logger.log("Rotating by \(rotationDegrees) degrees")
            for url in urls {
                if !rotate(imageAt: url, byDegrees: rotationDegrees) {
                    logger.log("Error while rotating image")
                }
            }
        }
        
        let wantsPDF = configuration.config[ScanlineConfigOptionJPEG] == nil && configuration.config[ScanlineConfigOptionTIFF] == nil
        if !wantsPDF {
            for url in urls {
                outputAndTag(url: url)
            }
        } else {
            // Combine into a single PDF
            if let combinedURL = combine(urls: urls) {
                outputAndTag(url: combinedURL)
            } else {
                logger.log("Error while creating PDF")
                return false
            }
        }
        
        return true
    }
    
    public func combine(urls: [URL]) -> URL? {
        let document = PDFDocument()
        
        for url in urls {
            if let page = PDFPage(image: NSImage(byReferencing: url)) {
                document.insert(page, at: document.pageCount)
            }
        }
        
        let tempFilePath = "\(NSTemporaryDirectory())/scan.pdf"
        document.write(toFile: tempFilePath)
        
        return URL(fileURLWithPath: tempFilePath)
    }
    
    public func outputAndTag(url: URL) {
        let gregorian = NSCalendar(calendarIdentifier: .gregorian)!
        let dateComponents = gregorian.components([.year, .hour, .minute, .second], from: Date())
        
        let outputRootDirectory = configuration.config[ScanlineConfigOptionDir] as! String
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
            return
        }
        
        let destinationFileExtension: String
        if configuration.config[ScanlineConfigOptionTIFF] != nil {
            destinationFileExtension = "tif"
        } else if configuration.config[ScanlineConfigOptionJPEG] != nil {
            destinationFileExtension = "jpg"
        } else {
            destinationFileExtension = "pdf"
        }
        
        let destinationFileRoot: String = { () -> String in
            if let fileName = self.configuration.config[ScanlineConfigOptionName] {
                return "\(path)/\(fileName)"
            }
            return "\(path)/scan_\(dateComponents.hour!.f02ld())\(dateComponents.minute!.f02ld())\(dateComponents.second!.f02ld())"
        }()
        
        var destinationFilePath = "\(destinationFileRoot).\(destinationFileExtension)"
        var i = 0
        while FileManager.default.fileExists(atPath: destinationFilePath) {
            destinationFilePath = "\(destinationFileRoot).\(i).\(destinationFileExtension)"
            i += 1
        }
        
        logger.verbose("About to copy \(url.absoluteString) to \(destinationFilePath)")
        
        let destinationURL = URL(fileURLWithPath: destinationFilePath)
        do {
            try FileManager.default.copyItem(at: url, to: destinationURL)
        } catch {
            logger.log("Error while copying file to \(destinationURL.absoluteString)")
            return
        }
        
        // Alias to all other tag locations
        // todo: this is super repetitive with above...
        if configuration.tags.count > 1 {
            for tag in configuration.tags.subarray(with: NSMakeRange(1, configuration.tags.count - 1)) {
                logger.verbose("Aliasing to tag \(tag)")
                let aliasDirPath = "\(outputRootDirectory)/\(tag)/\(dateComponents.year!.fld())"
                do {
                    try FileManager.default.createDirectory(atPath: aliasDirPath, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    logger.log("Error while creating directory \(aliasDirPath)")
                    return
                }
                let aliasFileRoot = { () -> String in
                    if let name = configuration.config[ScanlineConfigOptionName] {
                        return "\(aliasDirPath)/\(name)"
                    }
                    return "\(aliasDirPath)/scan_\(dateComponents.hour!.f02ld())\(dateComponents.minute!.f02ld())\(dateComponents.second!.f02ld())"
                }()
                var aliasFilePath = "\(aliasFileRoot).\(destinationFileExtension)"
                var i = 0
                while FileManager.default.fileExists(atPath: aliasFilePath) {
                    aliasFilePath = "\(aliasFileRoot).\(i).\(destinationFileExtension)"
                    i += 1
                }
                logger.verbose("Aliasing to \(aliasFilePath)")
                do {
                    try FileManager.default.createSymbolicLink(atPath: aliasFilePath, withDestinationPath: destinationFilePath)
                } catch {
                    logger.log("Error while creating alias at \(aliasFilePath)")
                    return
                }
            }
        }
        
        if configuration.config[ScanlineConfigOptionOpen] != nil {
            logger.verbose("Opening file at \(destinationFilePath)")
            NSWorkspace.shared.open(URL(fileURLWithPath: destinationFilePath))
        }
    }
}

fileprivate extension Int {
    // format to 2 decimal places
    func f02ld() -> String {
        return String(format: "%02ld", self)
    }
    
    func fld() -> String {
        return String(format: "%ld", self)
    }
}
