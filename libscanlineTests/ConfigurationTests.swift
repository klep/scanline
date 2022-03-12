//
//  ConfigurationTests.swift
//  ConfigurationTests
//
//  Created by Scott J. Kleper on 5/9/21.
//  Copyright © 2021 Scott J. Kleper. All rights reserved.
//

import XCTest
@testable import libscanline

class ConfigurationTests: XCTestCase {
    private lazy var testConfigPath = Bundle(for: ConfigurationTests.self).path(forResource: "config_test", ofType: "conf") ?? ""
        
    func testLoadConfigurationFromFile() {
        let testConfig = ScanConfiguration(arguments: [], configFilePath: testConfigPath)
        
        XCTAssertTrue(testConfig.config[ScanlineConfigOptionDuplex] as? Bool == true)
        XCTAssertFalse(testConfig.config[ScanlineConfigOptionBatch] as? Bool == true)
        XCTAssertFalse(testConfig.config[ScanlineConfigOptionFlatbed] as? Bool == true)
        XCTAssertEqual(testConfig.config[ScanlineConfigOptionName] as? String, "the_name")
    }
    
    func testLoadConfigurationFromFileWithArgumentOverride() {
        let testConfig = ScanConfiguration(arguments: ["-flatbed"], configFilePath: testConfigPath)
        
        XCTAssertTrue(testConfig.config[ScanlineConfigOptionDuplex] as? Bool == true)
        XCTAssertFalse(testConfig.config[ScanlineConfigOptionBatch] as? Bool == true)
        XCTAssertTrue(testConfig.config[ScanlineConfigOptionFlatbed] as? Bool == true)
        XCTAssertEqual(testConfig.config[ScanlineConfigOptionName] as? String, "the_name")
    }
    
    func testGettingTagsFromCommandLine() {
        let testConfig = ScanConfiguration(arguments: ["taxes-2013"], configFilePath: testConfigPath)
        
        XCTAssertEqual(testConfig.tags.firstObject as? String, "taxes-2013")
    }

    func testJpegOption() {
        let testConfig = ScanConfiguration(arguments: ["-jpeg"])
        
        XCTAssertTrue(testConfig.config[ScanlineConfigOptionJPEG] as? Bool == true)
    }

    func testJpegOptionWithJpg() {
        let testConfig = ScanConfiguration(arguments: ["-jpg"])
        
        XCTAssertTrue(testConfig.config[ScanlineConfigOptionJPEG] as? Bool == true)
    }

    func testResolutionOptionWithNonNumericalValue() {
        let testConfig = ScanConfiguration(arguments: ["-resolution", "booger"])
        
        XCTAssertNil(testConfig.config[ScanlineConfigOptionResolution] as? Int)
    }
    
    func testLetterNotLegal() {
        let testConfig = ScanConfiguration(arguments: ["-letter"])
        
        XCTAssertTrue(testConfig.config[ScanlineConfigOptionLetter] as? Bool == true)
        XCTAssertFalse(testConfig.config[ScanlineConfigOptionLegal] as? Bool == true)
    }
    
    func testLegalNotLetter() {
        let testConfig = ScanConfiguration(arguments: ["-legal"])
        
        XCTAssertFalse(testConfig.config[ScanlineConfigOptionLetter] as? Bool == true)
        XCTAssertTrue(testConfig.config[ScanlineConfigOptionLegal] as? Bool == true)
    }
    
    func testMissingSecondParameter() {
        // This would throw an array out of bounds error previously.
        _ = ScanConfiguration(arguments: ["-scanner"], configFilePath: testConfigPath)
        
        let testConfig = ScanConfiguration(arguments: ["-scanner", "epson"])
        XCTAssertEqual(testConfig.config[ScanlineConfigOptionScanner] as? String ?? "", "epson")
    }
}
