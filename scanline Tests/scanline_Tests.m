//
//  scanline_Tests.m
//  scanline Tests
//
//  Created by Scott J. Kleper on 9/26/13.
//
//

#import <XCTest/XCTest.h>
#import "OCMock/OCMock.h"

#import "DDLog.h"
#import "DDTTYLogger.h"
#import "DDASLLogger.h"

#import "ScanConfiguration.h"

@interface scanline_Tests : XCTestCase

@end

@implementation scanline_Tests

ScanConfiguration *testConfig;

- (void)setUp
{
    [super setUp];

    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    ddLogLevel = LOG_LEVEL_VERBOSE;
    
    testConfig = [ScanConfiguration alloc];
    id mock = [OCMockObject partialMockForObject:testConfig];
    NSString *testConfPath = ((NSURL*)[NSURL fileURLWithPath:@"config_test.conf"]).path;

    [[[mock stub] andReturn:testConfPath] configFilePath];
}

- (void)tearDown
{
    [DDLog flushLog];
    
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testLoadConfigurationFromFile
{
    testConfig = [testConfig init];
    XCTAssertTrue(testConfig.config[ScanlineConfigOptionDuplex]);
    XCTAssertFalse(testConfig.config[ScanlineConfigOptionBatch]);
    XCTAssertFalse(testConfig.config[ScanlineConfigOptionFlatbed]);
    XCTAssertEqualObjects(testConfig.config[ScanlineConfigOptionName], @"the_name");
}

- (void)testLoadConfigurationFromFileUsingEmptyArguments
{
    testConfig = [testConfig initWithArguments:[NSArray array]];
    XCTAssertTrue(testConfig.config[ScanlineConfigOptionDuplex]);
    XCTAssertFalse(testConfig.config[ScanlineConfigOptionBatch]);
    XCTAssertFalse(testConfig.config[ScanlineConfigOptionFlatbed]);
    XCTAssertEqualObjects(testConfig.config[ScanlineConfigOptionName], @"the_name");
}

- (void)testLoadConfigurationFromFileWithArgumentOverride
{
    testConfig = [testConfig initWithArguments:[NSArray arrayWithObjects:@"-flatbed", nil]];
    XCTAssertTrue(testConfig.config[ScanlineConfigOptionDuplex]);
    XCTAssertFalse(testConfig.config[ScanlineConfigOptionBatch]);
    XCTAssertTrue(testConfig.config[ScanlineConfigOptionFlatbed]);
    XCTAssertEqualObjects(testConfig.config[ScanlineConfigOptionName], @"the_name");
}

- (void)testGettingTagsFromCommandline
{
    testConfig = [testConfig initWithArguments:[NSArray arrayWithObjects:@"taxes-2013", nil]];
    DDLogInfo(@"first tag: %@", [[testConfig tags] objectAtIndex:0]);
    XCTAssertTrue([[[testConfig tags] objectAtIndex:0] isEqualToString:@"taxes-2013"]);
}

- (void)testJpegOption
{
    testConfig = [testConfig initWithArguments:[NSArray arrayWithObjects:@"-jpeg", nil]];
    XCTAssertTrue(testConfig.config[ScanlineConfigOptionJPEG]);
}

- (void)testJpegOptionWithJpg
{
    testConfig = [testConfig initWithArguments:[NSArray arrayWithObjects:@"-jpg", nil]];
    XCTAssertTrue(testConfig.config[ScanlineConfigOptionJPEG]);
}

- (void)testResolutionOptionWithNonNumericalValue
{
    testConfig = [testConfig initWithArguments:[NSArray arrayWithObjects:@"-resolution", @"booger", nil]];
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
