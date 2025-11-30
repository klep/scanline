//
//  ScanlineAppController.swift
//  scanline
//
//  Created by Scott J. Kleper on 12/2/17.
//

import Foundation
import ImageCaptureCore
import Darwin

enum ExitCode: Int32 {
    case success = 0
    case failure = 1
}

class ScanlineAppController: NSObject {
    let configuration: ScanConfiguration
    let logger: Logger
    let scannerBrowser: ScannerBrowser
    var scannerBrowserTimer: Timer?

    var scannerController: ScannerController?
    
    init(arguments: [String]) {
        configuration = ScanConfiguration(arguments: Array(arguments[1..<arguments.count]))
//        configuration = ScanConfiguration(arguments: ["-flatbed", "-summarize", "-verbose", "-autoname", "ubs", "investments", "retirement", "kids"])
//        configuration = ScanConfiguration(arguments: ["-flatbed", "-rotate", "180", "-verbose"])
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

    func exit(with code: ExitCode = .success) {
        logger.log("Done")
        DispatchQueue.main.async {
            CFRunLoopStop(CFRunLoopGetCurrent())
            Darwin.exit(code.rawValue)
        }
    }

    func scan(scanner: ICScannerDevice) {
        scannerController = ScannerController(scanner: scanner, configuration: configuration, logger: logger)
        scannerController?.delegate = self
        scannerController?.scan()
    }
}

extension ScanlineAppController: ScannerBrowserDelegate {
    func scannerBrowser(_ scannerBrowser: ScannerBrowser, didFinishBrowsingWithScanner scanner: ICScannerDevice?) {
        logger.verbose("Found scanner: \(scanner?.name ?? "[nil]")")
        scannerBrowserTimer?.invalidate()
        scannerBrowserTimer = nil
        
        guard configuration.config[ScanlineConfigOptionList] == nil else {
            exit(with: .success)
            return
        }
        
        guard let scanner = scanner else {
            logger.log("No scanner was found.")
            exit(with: .failure)
            return
        }
        
        scan(scanner: scanner)
    }
    
    func scannerBrowser(_ scannerBrowser: ScannerBrowser, didUpdateAvailableScanners availableScanners: [String]) {
        // No-op
    }
}

extension ScanlineAppController: ScannerControllerDelegate {
    func scannerController(_ scannerController: ScannerController, didObtainResolutions resolutions: IndexSet) {
        // No-op
    }

    func scannerControllerDidFail(_ scannerController: ScannerController) {
        logger.log("Failed to scan document.")
        exit(with: .failure)
    }
    
    func scannerControllerDidSucceed(_ scannerController: ScannerController) {
        exit(with: .success)
    }
}
