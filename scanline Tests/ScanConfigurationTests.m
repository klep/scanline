//
//  scanline_Tests.m
//  scanline Tests
//
//  Created by Scott J. Kleper on 9/26/13.
//
//

#import <XCTest/XCTest.h>

#import "../scanline/ScanConfiguration.h"

@interface ScanConfigurationTests : XCTestCase

@end

@implementation ScanConfigurationTests

ScanConfiguration *testConfig;

- (void)setUp
{
    [super setUp];
    
    testConfig = [ScanConfiguration alloc];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testLoadConfigurationFromFile
{
    testConfig = [testConfig initWithArguments:@[] configFilePath:@"Scanline Tests.xctest/Contents/Resources/config_test.conf"];
    XCTAssertTrue(testConfig.config[ScanlineConfigOptionDuplex]);
    XCTAssertFalse(testConfig.config[ScanlineConfigOptionBatch]);
    XCTAssertFalse(testConfig.config[ScanlineConfigOptionFlatbed]);
    XCTAssertEqualObjects(testConfig.config[ScanlineConfigOptionName], @"the_name");
}

- (void)testLoadConfigurationFromFileWithArgumentOverride
{
    testConfig = [testConfig initWithArguments:[NSArray arrayWithObjects:@"-flatbed", nil] configFilePath:@"Scanline Tests.xctest/Contents/Resources/config_test.conf"];
    XCTAssertTrue(testConfig.config[ScanlineConfigOptionDuplex]);
    XCTAssertFalse(testConfig.config[ScanlineConfigOptionBatch]);
    XCTAssertTrue(testConfig.config[ScanlineConfigOptionFlatbed]);
    XCTAssertEqualObjects(testConfig.config[ScanlineConfigOptionName], @"the_name");
}

- (void)testGettingTagsFromCommandline
{
    testConfig = [testConfig initWithArguments:[NSArray arrayWithObjects:@"taxes-2013", nil] configFilePath:@"Scanline Tests.xctest/Contents/Resources/config_test.conf"];
    XCTAssertTrue([[[testConfig tags] objectAtIndex:0] isEqualToString:@"taxes-2013"]);
}

- (void)testJpegOption
{
    testConfig = [testConfig initWithArguments:[NSArray arrayWithObjects:@"-jpeg", nil] configFilePath:@"Scanline Tests.xctest/Contents/Resources/config_test.conf"];
    XCTAssertTrue(testConfig.config[ScanlineConfigOptionJPEG]);
}

- (void)testJpegOptionWithJpg
{
    testConfig = [testConfig initWithArguments:[NSArray arrayWithObjects:@"-jpg", nil] configFilePath:@"Scanline Tests.xctest/Contents/Resources/config_test.conf"];
    XCTAssertTrue(testConfig.config[ScanlineConfigOptionJPEG]);
}

- (void)testResolutionOptionWithNonNumericalValue
{
    testConfig = [testConfig initWithArguments:[NSArray arrayWithObjects:@"-resolution", @"booger", nil] configFilePath:@"Scanline Tests.xctest/Contents/Resources/config_test.conf"];
    XCTAssertEqual([testConfig.config[ScanlineConfigOptionResolution] intValue], 0);
}

- (void)testLetterNotLegal
{
    testConfig = [testConfig initWithArguments:@[@"-letter"]];
    XCTAssertTrue(testConfig.config[ScanlineConfigOptionLetter]);
    XCTAssertFalse(testConfig.config[ScanlineConfigOptionLegal]);
}

- (void)testLegalNotLetter
{
    testConfig = [testConfig initWithArguments:@[@"-legal"]];
    XCTAssertTrue(testConfig.config[ScanlineConfigOptionLegal]);
    XCTAssertFalse(testConfig.config[ScanlineConfigOptionLetter]);
}
@end
