//
//  This code is part of scanline and published under MIT license.
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
        
        let timerExpiration = configuration.waitSeconds
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
        
        guard !configuration.list else {
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
