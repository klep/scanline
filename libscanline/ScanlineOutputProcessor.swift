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
import FoundationModels

public class ScanlineOutputProcessor {
    let logger: Logger
    let configuration: ScanConfiguration
    let urls: [URL]
    var summaries: [URL: String] = [:]
    
    public init(urls: [URL], configuration: ScanConfiguration, logger: Logger) {
        self.urls = urls
        self.configuration = configuration
        self.logger = logger
    }
    
    private func autoName(for text: String, tags: [String]) async -> String {
        if #available(macOS 26.0, *) {
            guard SystemLanguageModel.default.availability == .available else {
                logger.log("Unable to autoname because language model is not available")
                return ""
            }
            
            let session = LanguageModelSession()
            let prompt = """
                The following document was scanned by a user who would like you to generate an appropriate name for the scanned file based on its content.
                The user has assigned the following tags to the document, which might be helpful in naming: \(tags.joined(separator: ","))
                
                Please respond with a filename that meets the following criteria:
                - It has no special characters or spaces (use dashes instead). It must be a valid macOS filename.
                - It captures what the document is about (e.g. "mortgage-statement-2025-07", "legal-settlement", "jenny-divorce-final")
                - If an appropriate name cannot be determined, return "scan"
                - If you can identify the organization it's from (e.g. Fidelity, DMV, IRS, etc.), put that in the filename
                - Keep names short. Prefer "Fidelity" over "Fidelity Investments"
                - Don't over-index on the tags - they should only inform your name, not dictate it
                - Do not include a date in the filename
                - Do not append a file type suffix
                - Do not return any other commentary or context -- only reply with the filename itself
                
                The user's document follows: 
                \(text)
                """.prefix(10000) // Should keep us well below the token window limit
            
            do {
                let response = try await session.respond(to: String(prompt))
                let proposedFilename = response.content
                if proposedFilename == "scan" {
                    return defaultFilename
                }
                if isValidMacOSFilename(proposedFilename) {
                    return proposedFilename
                }
                
            } catch {
                logger.log("Error while auto naming: \(error)")
            }
        } else {
            logger.log("Unable to auto name because this version of macOS does not have Apple Intelligence")
        }
        
        return defaultFilename
    }

    private func summarize(_ text: String) async -> String? {
        if #available(macOS 26.0, *) {
            guard SystemLanguageModel.default.availability == .available else {
                logger.log("Unable to summarize because language model is not available")
                return ""
            }
            
            let session = LanguageModelSession()
            let prompt = """
                The following document was scanned by a user who would now like a summary. 
                Please respond with a summary of the document and no other content. 
                Do not prefix with "Document Summary" or "This document" or anything like that. Just give the summary itself with no intro.
                Your summary should make it clear what this document is, any key details, and any key terms (names, places, companies) that might be useful in search.
                Try to avoid including sensitive content in your summary (e.g. SSN, phone numbers, etc.)
                
                The user's document follows: 
                \(text)
                """.prefix(10000) // Should keep us well below the token window limit
            
            do {
                let response = try await session.respond(to: String(prompt))
                return response.content
            } catch {
                logger.log("Error while summarizing: \(error)")
            }
        } else {
            logger.log("Unable to summarize because this version of macOS does not have Apple Intelligence")
        }
        
        return nil
    }
    
    private func extractText(fromImageAt imageURL: URL) async -> String {
        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate

        do {
            let observations = try await request.perform(on: imageURL)
            let strings = observations.map { $0.topCandidates(1).first?.string ?? "" }
            return strings.joined(separator: "\n")
        } catch {
            logger.log("Error while performing text recognition")
            return ""
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
    
    private func handleAI(for url: URL, withFullText fullText: String) async {
        let wantsSummary = configuration.config[ScanlineConfigOptionSummarize] != nil
        let wantsAutoname = configuration.config[ScanlineConfigOptionAutoname] != nil
        
        if wantsSummary {
            if let summaryText = await summarize(fullText) {
                logger.verbose("Summary: \(summaryText)")
                summaries[url] = summaryText
            }
        }
        
        if wantsAutoname && configuration.config[ScanlineConfigOptionName] == nil {
            let filename = await autoName(for: fullText, tags: configuration.tagStrings)
            logger.verbose("Autonaming to \(filename)")
            configuration.config[ScanlineConfigOptionName] = filename
        }
    }

    public func process() async -> Bool {
        let wantsOCROutput = configuration.config[ScanlineConfigOptionOCR] != nil
        let wantsSummary = configuration.config[ScanlineConfigOptionSummarize] != nil
        let wantsAutoname = configuration.config[ScanlineConfigOptionAutoname] != nil
        
        let needsOCR = wantsOCROutput || wantsSummary || wantsAutoname
        var fullText = ""
        if needsOCR {
            for url in urls {
                let pageText = await extractText(fromImageAt: url)
                if wantsOCROutput {
                    print(pageText)
                }
                fullText += pageText
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
        
        let wantsPDF = configuration.config[ScanlineConfigOptionJPEG] == nil && configuration.config[ScanlineConfigOptionTIFF] == nil && configuration.config[ScanlineConfigOptionPNG] == nil
        if !wantsPDF {
            for url in urls {
                await handleAI(for: url, withFullText: fullText)
                outputAndTag(url: url)
            }
        } else {
            // Combine into a single PDF
            if let combinedURL = combine(urls: urls) {
                await handleAI(for: combinedURL, withFullText: fullText)
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
    
    private var defaultFilename: String {
        let gregorian = NSCalendar(calendarIdentifier: .gregorian)!
        let dateComponents = gregorian.components([.year, .hour, .minute, .second], from: Date())
        
        return "scan_\(dateComponents.hour!.f02ld())\(dateComponents.minute!.f02ld())\(dateComponents.second!.f02ld())"
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
        if configuration.config[ScanlineConfigOptionPNG] != nil {
            destinationFileExtension = "png"
        } else if configuration.config[ScanlineConfigOptionTIFF] != nil {
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
            return "\(path)/\(defaultFilename)"
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
                    return "\(aliasDirPath)/\(defaultFilename)"
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
        
        let wantsSummary = configuration.config[ScanlineConfigOptionSummarize] != nil
        if wantsSummary, let summaryText = summaries[url] {
            var summaryFilePath = "\(destinationFileRoot).summary.txt"
            var i = 0
            while FileManager.default.fileExists(atPath: summaryFilePath) {
                summaryFilePath = "\(destinationFileRoot).\(i).summary.txt"
                i += 1
            }
            
            logger.verbose("About to write summary to \(summaryFilePath)")
            
            do {
                try summaryText.write(toFile: summaryFilePath, atomically: true, encoding: .utf8)
            } catch {
                logger.log("Error while writing summary \(summaryFilePath)")
            }
        }
        
        if configuration.config[ScanlineConfigOptionOpen] != nil {
            logger.verbose("Opening file at \(destinationFilePath)")
            NSWorkspace.shared.open(URL(fileURLWithPath: destinationFilePath))
        }
    }
    
    /// Returns true if the given string is a valid filename for macOS file systems.
    private func isValidMacOSFilename(_ filename: String) -> Bool {
        // Cannot be empty
        guard !filename.isEmpty else { return false }
        // Cannot be "." or ".."
        guard filename != "." && filename != ".." else { return false }
        // Cannot contain colon (:) or null character
        if filename.contains(":") || filename.contains("\u{0000}") {
            return false
        }
        // Must not exceed 255 bytes in UTF-8
        if filename.lengthOfBytes(using: .utf8) > 255 {
            return false
        }
        return true
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

fileprivate extension ScanConfiguration {
    var tagStrings: [String] {
        tags.compactMap { tag in
            if let tagName = tag as? String {
                return tagName
            }
            return nil
        }
    }
}
