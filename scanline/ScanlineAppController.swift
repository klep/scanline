//
//  ScanlineAppController.swift
//  scanline
//
//  Created by Scott J. Kleper on 12/2/17.
//

import Foundation
import ImageCaptureCore

class ScanlineAppController: NSObject, ScannerBrowserDelegate, ScannerControllerDelegate {
    let configuration: ScanConfiguration
    let logger: Logger
    let scannerBrowser: ScannerBrowser
    var scannerBrowserTimer: Timer?

    var scannerController: ScannerController?
    
    init(arguments: [String]) {
//        configuration = ScanConfiguration(arguments: arguments)
//        configuration = ScanConfiguration(arguments: ["-name", "Dell Color MFP E525w (31:4D:90)", "-exact", "-v"])
        configuration = ScanConfiguration(arguments: ["-name", "epson", "-v", "-resolution", "600"])
//        configuration = ScanConfiguration(arguments: ["-list", "-v"])
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

}

protocol ScannerControllerDelegate: class {
    func scannerControllerDidFail(_ scannerController: ScannerController)
}

class ScannerController: NSObject, ICScannerDeviceDelegate {
    let scanner: ICScannerDevice
    let configuration: ScanConfiguration
    let logger: Logger
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
        
        if functionalUnit.type == self.desiredFunctionalUnitType {
            configureScanner()
            logger.log("Starting scan...")
            scanner.requestScan()
        }
    }

    func scannerDevice(_ scanner: ICScannerDevice, didScanTo url: URL) {
        logger.verbose("didScanTo \(url)")
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
        scanner.documentUTI = kUTTypeJPEG as String
    }

    fileprivate func configureDocumentFeeder() {
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
//        guard let functionalUnit = scanner.selectedFunctionalUnit as? ICScannerFunctionalUnitFlatbed else { return }
//
//        functionalUnit.measurementUnit = .inches
//
    }
}
