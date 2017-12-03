//
//  ScanlineAppController.swift
//  scanline
//
//  Created by Scott J. Kleper on 12/2/17.
//

import Foundation
import ImageCaptureCore

class ScanlineAppController: NSObject, ScannerBrowserDelegate {
    let configuration: ScanConfiguration
    let scannerBrowser: ScannerBrowser
    var scannerBrowserTimer: Timer?

    init(arguments: [String]) {
//        configuration = ScanConfiguration(arguments: arguments)
        configuration = ScanConfiguration(arguments: ["-name", "Dell Color MFP E525w (31:4D:90)", "-exact"])
        scannerBrowser = ScannerBrowser(configuration: configuration)
        
        super.init()
        
        scannerBrowser.delegate = self
    }

    func go() {
        scannerBrowser.browse()
        
        let timerExpiration:Double = Double(configuration.config[ScanlineConfigOptionBrowseSecs] as? String ?? "10") ?? 10.0
        scannerBrowserTimer = Timer.scheduledTimer(withTimeInterval: timerExpiration, repeats: false) { _ in
            self.scannerBrowser.stopBrowsing()
        }
    }
    
    func scannerBrowser(_ scannerBrowser: ScannerBrowser, didFinishBrowsingWithScanner scanner: ICScannerDevice?) {
        print("Finished browsing and got: \(scanner?.name ?? "[nil]")")
        scannerBrowserTimer?.invalidate()
        scannerBrowserTimer = nil
    }
}
