//
//  ScanlineAppController.swift
//  scanline
//
//  Created by Scott J. Kleper on 12/2/17.
//

import Foundation
import ImageCaptureCore
import AppKit
import Quartz

class ScanlineAppController: NSObject, ScannerBrowserDelegate, ScannerControllerDelegate {
    let configuration: ScanConfiguration
    let logger: Logger
    let scannerBrowser: ScannerBrowser
    var scannerBrowserTimer: Timer?

    var scannerController: ScannerController?
    
    init(arguments: [String]) {
        configuration = ScanConfiguration(arguments: Array(arguments[1..<arguments.count]))
//        configuration = ScanConfiguration(arguments: ["-flatbed", "house", "-v"])
//        configuration = ScanConfiguration(arguments: ["-scanner", "Dell Color MFP E525w (31:4D:90)", "-exact", "-v"])
//        configuration = ScanConfiguration(arguments: ["-scanner", "epson", "-v", "-resolution", "600"])
//        configuration = ScanConfiguration(arguments: ["-list", "-v"])
//        configuration = ScanConfiguration(arguments: ["-scanner", "epson", "-v", "scanlinetest"])
        logger = Logger(configuration: configuration)
        scannerBrowser = ScannerBrowser(configuration: configuration, logger: logger)
        
        super.init()
        
        scannerBrowser.delegate = self
    }

    func go() {
        scannerBrowser.browse()
        
        let timerExpiration:Double = Double(configuration.config[ScanlineConfigOptionBrowseSecs] as? String ?? "10") ?? 10.0
        scannerBrowserTimer = Timer.scheduledTimer(withTimeInterval: timerExpiration, repeats: false) { _ in
            self.scannerBrowser.stopBrowsing()
        }
        
        logger.verbose("Waiting up to \(timerExpiration) seconds to find scanners")
    }

    func exit() {
        CFRunLoopStop(CFRunLoopGetCurrent())
    }

    func scan(scanner: ICScannerDevice) {
        scannerController = ScannerController(scanner: scanner, configuration: configuration, logger: logger)
        scannerController?.delegate = self
        scannerController?.scan()
    }

    // MARK: - ScannerBrowserDelegate
    
    func scannerBrowser(_ scannerBrowser: ScannerBrowser, didFinishBrowsingWithScanner scanner: ICScannerDevice?) {
        logger.verbose("Found scanner: \(scanner?.name ?? "[nil]")")
        scannerBrowserTimer?.invalidate()
        scannerBrowserTimer = nil
        
        guard configuration.config[ScanlineConfigOptionList] == nil else {
            exit()
            return
        }
        
        guard let scanner = scanner else {
            logger.log("No scanner was found.")
            exit()
            return
        }
        
        scan(scanner: scanner)
    }
    
    // MARK: - ScannerControllerDelegate
    
    func scannerControllerDidFail(_ scannerController: ScannerController) {
        logger.log("Failed to scan document.")
        exit()
    }
    
    func scannerControllerDidSucceed(_ scannerController: ScannerController) {
        exit()
    }

}

protocol ScannerControllerDelegate: class {
    func scannerControllerDidFail(_ scannerController: ScannerController)
    func scannerControllerDidSucceed(_ scannerController: ScannerController)
}

class ScannerController: NSObject, ICScannerDeviceDelegate {
    let scanner: ICScannerDevice
    let configuration: ScanConfiguration
    let logger: Logger
    var scannedURLs = [URL]()
    weak var delegate: ScannerControllerDelegate?
    var desiredFunctionalUnitType: ICScannerFunctionalUnitType {
        return (configuration.config[ScanlineConfigOptionFlatbed] == nil) ?
            ICScannerFunctionalUnitType.documentFeeder :
            ICScannerFunctionalUnitType.flatbed
    }
    
    init(scanner: ICScannerDevice, configuration: ScanConfiguration, logger: Logger) {
        self.scanner = scanner
        self.configuration = configuration
        self.logger = logger
        
        super.init()

        self.scanner.delegate = self
    }
    
    func scan() {
        logger.verbose("Opening session with scanner")
        scanner.requestOpenSession()
    }
    
    // MARK: - ICScannerDeviceDelegate

    func device(_ device: ICDevice, didEncounterError error: Error?) {
        logger.verbose("didEncounterError: \(error?.localizedDescription ?? "[no error]")")
        delegate?.scannerControllerDidFail(self)
    }
    
    func device(_ device: ICDevice, didCloseSessionWithError error: Error?) {
        logger.verbose("didCloseSessionWithError: \(error?.localizedDescription ?? "[no error]")")
        delegate?.scannerControllerDidFail(self)
    }
    
    func device(_ device: ICDevice, didOpenSessionWithError error: Error?) {
        logger.verbose("didOpenSessionWithError: \(error?.localizedDescription ?? "[no error]")")
        
        guard error == nil else {
            logger.log("Error received while attempting to open a session with the scanner.")
            delegate?.scannerControllerDidFail(self)
            return
        }
    }
    
    func didRemove(_ device: ICDevice) {
    }
    
    func deviceDidBecomeReady(_ device: ICDevice) {
        logger.verbose("deviceDidBecomeReady")
        selectFunctionalUnit()
    }
    
    func scannerDevice(_ scanner: ICScannerDevice, didSelect functionalUnit: ICScannerFunctionalUnit, error: Error?) {
        logger.verbose("didSelectFunctionalUnit: \(functionalUnit) error: \(error?.localizedDescription ?? "[no error]")")
        
        // NOTE: Despite the fact that `functionalUnit` is not an optional, it still sometimes comes in as `nil` even when `error` is `nil`
        if functionalUnit != nil && functionalUnit.type == self.desiredFunctionalUnitType {
            configureScanner()
            logger.log("Starting scan...")
            scanner.requestScan()
        }
    }

    func scannerDevice(_ scanner: ICScannerDevice, didScanTo url: URL) {
        logger.verbose("didScanTo \(url)")
        
        scannedURLs.append(url)
    }
    
    func scannerDevice(_ scanner: ICScannerDevice, didCompleteScanWithError error: Error?) {
        logger.verbose("didCompleteScanWithError \(error?.localizedDescription ?? "[no error]")")
        
        guard error == nil else {
            logger.log("ERROR: \(error!.localizedDescription)")
            delegate?.scannerControllerDidFail(self)
            return
        }

        if self.configuration.config[ScanlineConfigOptionBatch] != nil {
            logger.log("Press RETURN to scan next page or S to stop")
            let userInput = String(format: "%c", getchar())
            if !"sS".contains(userInput) {
                logger.verbose("Continuing scan")
                scanner.requestScan()
                return
            }
        }

        let outputProcessor = ScanlineOutputProcessor(urls: self.scannedURLs, configuration: configuration, logger: logger)
        if outputProcessor.process() {
            delegate?.scannerControllerDidSucceed(self)
        } else {
            delegate?.scannerControllerDidFail(self)
        }
    }
    
    // MARK: Private Methods
    
    fileprivate func selectFunctionalUnit() {
        scanner.requestSelect(self.desiredFunctionalUnitType)
    }
    
    fileprivate func configureScanner() {
        logger.verbose("Configuring scanner")
        
        let functionalUnit = scanner.selectedFunctionalUnit
        
        if functionalUnit.type == .documentFeeder {
            configureDocumentFeeder()
        } else {
            configureFlatbed()
        }
        
        let desiredResolution = Int(configuration.config[ScanlineConfigOptionResolution] as? String ?? "150") ?? 150
        if let resolutionIndex = functionalUnit.supportedResolutions.integerGreaterThanOrEqualTo(desiredResolution) {
            functionalUnit.resolution = resolutionIndex
        }

        if configuration.config[ScanlineConfigOptionMono] != nil {
            functionalUnit.pixelDataType = .BW
            functionalUnit.bitDepth = .depth1Bit
        } else {
            functionalUnit.pixelDataType = .RGB
            functionalUnit.bitDepth = .depth8Bits
        }

        scanner.transferMode = .fileBased
        scanner.downloadsDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
        scanner.documentName = "Scan"
        
        if configuration.config[ScanlineConfigOptionTIFF] != nil {
            scanner.documentUTI = kUTTypeTIFF as String
        } else {
            scanner.documentUTI = kUTTypeJPEG as String
        }
    }

    fileprivate func configureDocumentFeeder() {
        logger.verbose("Configuring Document Feeder")

        guard let functionalUnit = scanner.selectedFunctionalUnit as? ICScannerFunctionalUnitDocumentFeeder else { return }
        
        functionalUnit.documentType = { () -> ICScannerDocumentType in
            if configuration.config[ScanlineConfigOptionLegal] != nil {
                return .typeUSLegal
            }
            if configuration.config[ScanlineConfigOptionA4] != nil {
                return .typeA4
            }
            return .typeUSLetter
        }()
        
        functionalUnit.duplexScanningEnabled = (configuration.config[ScanlineConfigOptionDuplex] != nil)
    }
    
    fileprivate func configureFlatbed() {
        logger.verbose("Configuring Flatbed")
        
        guard let functionalUnit = scanner.selectedFunctionalUnit as? ICScannerFunctionalUnitFlatbed else { return }

        functionalUnit.measurementUnit = .inches
        let physicalSize = functionalUnit.physicalSize
        functionalUnit.scanArea = NSMakeRect(0, 0, physicalSize.width, physicalSize.height)
    }
}

extension Int {
    // format to 2 decimal places
    func f02ld() -> String {
        return String(format: "%02ld", self)
    }
    
    func fld() -> String {
        return String(format: "%ld", self)
    }
}
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
    
    func combine(urls: [URL]) -> URL? {
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

    func outputAndTag(url: URL) {
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
            NSWorkspace.shared.openFile(destinationFilePath)
        }
    }
}
