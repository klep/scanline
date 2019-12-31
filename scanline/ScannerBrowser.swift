//
//  ScannerBrowser.swift
//  scanline
//
//  Created by Scott J. Kleper on 12/2/17.
//  Copyright © 2017 Scott J. Kleper. All rights reserved.
//

import Foundation
import ImageCaptureCore

protocol ScannerBrowserDelegate: class {
    func scannerBrowser(_ scannerBrowser: ScannerBrowser, didFinishBrowsingWithScanner scanner: ICScannerDevice?)
}

class ScannerBrowser: NSObject, ICDeviceBrowserDelegate {
    let logger: Logger
    let deviceBrowser = ICDeviceBrowser()
    var selectedScanner: ICScannerDevice?
    let configuration: ScanConfiguration
    var searching: Bool
    
    weak var delegate: ScannerBrowserDelegate?
    
    init(configuration: ScanConfiguration, logger: Logger) {
        self.configuration = configuration
        self.logger = logger
        self.searching = false
        
        super.init()
        
        deviceBrowser.delegate = self
        let mask = ICDeviceTypeMask(rawValue:
            ICDeviceTypeMask.scanner.rawValue |
                ICDeviceLocationTypeMask.local.rawValue |
                ICDeviceLocationTypeMask.bonjour.rawValue |
                ICDeviceLocationTypeMask.shared.rawValue)
        deviceBrowser.browsedDeviceTypeMask = mask!
    }
    
    func browse() {
        logger.verbose("Searching for available scanners")
        searching = true

        if configuration.list {
            logger.log("Available scanners:")
        }
        deviceBrowser.start()
    }
    
    func stopBrowsing() {
        guard searching else { return }
        
        delegate?.scannerBrowser(self, didFinishBrowsingWithScanner: selectedScanner)
        searching = false
    }
    
    func deviceMatchesSpecified(device: ICScannerDevice) -> Bool {
        // If no name was specified, this is perforce an exact match
        guard let desiredName = configuration.scannerName else { return !configuration.list }
        guard let deviceName = device.name else { return false }
        
        // "Fuzzy" match -- case-free compare of prefix
        if !configuration.exactName &&
            deviceName.lowercased().starts(with: desiredName.lowercased()) {
            return true
        }
        
        if desiredName == deviceName {
            return true
        }
        
        return false
    }
    
    func deviceBrowser(_ browser: ICDeviceBrowser, didAdd device: ICDevice, moreComing: Bool) {
        if configuration.list {
            logger.log("* \(device.name ?? "[Nameless Device]")")
        }
        
        guard let scannerDevice = device as? ICScannerDevice else { return }
        
        if deviceMatchesSpecified(device: scannerDevice) {
            selectedScanner = scannerDevice
            stopBrowsing()
        }
    }
    
    func deviceBrowser(_ browser: ICDeviceBrowser, didRemove device: ICDevice, moreGoing: Bool) {
    }
}

