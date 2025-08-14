//
//  ScannerController.swift
//  libscanline
//
//  Created by Scott J. Kleper on 5/13/21.
//  Copyright © 2021 Scott J. Kleper. All rights reserved.
//

import Foundation
import ImageCaptureCore
import Quartz

public protocol ScannerControllerDelegate: AnyObject {
    func scannerControllerDidFail(_ scannerController: ScannerController)
    func scannerControllerDidSucceed(_ scannerController: ScannerController)
    func scannerController(_ scannerController: ScannerController, didObtainResolutions resolutions: IndexSet)
}

public class ScannerController: NSObject, ICScannerDeviceDelegate {
    let scanner: ICScannerDevice
    let configuration: ScanConfiguration
    let logger: Logger
    var scannedURLs = [URL]()
    public weak var delegate: ScannerControllerDelegate?
    var desiredFunctionalUnitType: ICScannerFunctionalUnitType {
        return (configuration.config[ScanlineConfigOptionFlatbed] == nil) ?
            ICScannerFunctionalUnitType.documentFeeder :
            ICScannerFunctionalUnitType.flatbed
    }
    
    public init(scanner: ICScannerDevice, configuration: ScanConfiguration, logger: Logger) {
        self.scanner = scanner
        self.configuration = configuration
        self.logger = logger
        
        super.init()

        self.scanner.delegate = self
    }
    
    public func getSupportedResolutions() {
        guard scanner.hasOpenSession else {
            scanner.requestOpenSession()
            return
        }
        
        obtainResolutions()
    }
    
    public func scan() {
        logger.verbose("Opening session with scanner")
        scanner.requestOpenSession()
    }
    
    // MARK: - ICScannerDeviceDelegate

    public func device(_ device: ICDevice, didEncounterError error: Error?) {
        logger.verbose("didEncounterError: \(error?.localizedDescription ?? "[no error]")")
        delegate?.scannerControllerDidFail(self)
    }
    
    public func device(_ device: ICDevice, didCloseSessionWithError error: Error?) {
        logger.verbose("didCloseSessionWithError: \(error?.localizedDescription ?? "[no error]")")
        delegate?.scannerControllerDidFail(self)
    }
    
    public func device(_ device: ICDevice, didOpenSessionWithError error: Error?) {
        logger.verbose("didOpenSessionWithError: \(error?.localizedDescription ?? "[no error]")")
        
        guard error == nil else {
            logger.log("Error received while attempting to open a session with the scanner.")
            delegate?.scannerControllerDidFail(self)
            return
        }
    }
    
    public func didRemove(_ device: ICDevice) {
    }
    
    public func deviceDidBecomeReady(_ device: ICDevice) {
        logger.verbose("deviceDidBecomeReady")
        
        switch pendingAction {
        case .none:
            break
        case .obtainResolutions:
            obtainResolutions()
        case .scan:
            selectFunctionalUnit()
        }
    }
    
    public func scannerDevice(_ scanner: ICScannerDevice, didSelect functionalUnit: ICScannerFunctionalUnit, error: Error?) {
        logger.verbose("didSelectFunctionalUnit: \(functionalUnit) error: \(error?.localizedDescription ?? "[no error]")")
        
        // NOTE: Despite the fact that `functionalUnit` is not an optional, it still sometimes comes in as `nil` even when `error` is `nil`
        // Oddly, in debug builds, you can check non-optionals for `nil`, but in release builds, that always returns `false`, so we check
        // its address instead.
        let address = unsafeBitCast(functionalUnit, to: Int.self)
        if address != 0x0 && functionalUnit.type == self.desiredFunctionalUnitType {
            configureScanner()
            logger.log("Starting scan...")
            scanner.requestScan()
        }
    }

    public func scannerDevice(_ scanner: ICScannerDevice, didScanTo url: URL) {
        logger.verbose("didScanTo \(url)")
        
        scannedURLs.append(url)
    }
    
    public func scannerDevice(_ scanner: ICScannerDevice, didCompleteScanWithError error: Error?) {
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
    
    enum PendingAction {
        case none, obtainResolutions, scan
    }
    
    private var pendingAction: PendingAction = .scan
    
    func obtainResolutions() {
        delegate?.scannerController(self, didObtainResolutions: scanner.selectedFunctionalUnit.supportedResolutions)
    }
    
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
            scanner.documentUTI = UTType.tiff.identifier
        } else {
            scanner.documentUTI = UTType.jpeg.identifier
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
