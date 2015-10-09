//
//  scanline_Tests.m
//  scanline Tests
//
//  Created by Scott J. Kleper on 9/26/13.
//
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "DDLog.h"
#import "DDTTYLogger.h"
#import "DDASLLogger.h"

#import "ScanConfiguration.h"

@interface scanline_Tests : XCTestCase

@end

@implementation scanline_Tests

ScanConfiguration *config;

- (void)setUp
{
    [super setUp];

    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    ddLogLevel = LOG_LEVEL_VERBOSE;
    
    config = [ScanConfiguration alloc];
    id mock = [OCMockObject partialMockForObject:config];
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
    config = [config init];
    XCTAssertTrue(config.config[ScanlineConfigOptionDuplex]);
    XCTAssertFalse(config.config[ScanlineConfigOptionBatch]);
    XCTAssertFalse(config.config[ScanlineConfigOptionFlatbed]);
    XCTAssertEqualObjects(config.config[ScanlineConfigOptionName], @"the_name");
}

- (void)testLoadConfigurationFromFileUsingEmptyArguments
{
    config = [config initWithArguments:[NSArray array]];
    XCTAssertTrue(config.config[ScanlineConfigOptionDuplex]);
    XCTAssertFalse(config.config[ScanlineConfigOptionBatch]);
    XCTAssertFalse(config.config[ScanlineConfigOptionFlatbed]);
    XCTAssertEqualObjects(config.config[ScanlineConfigOptionName], @"the_name");
}

- (void)testLoadConfigurationFromFileWithArgumentOverride
{
    config = [config initWithArguments:[NSArray arrayWithObjects:@"-flatbed", nil]];
    XCTAssertTrue(config.config[ScanlineConfigOptionDuplex]);
    XCTAssertFalse(config.config[ScanlineConfigOptionBatch]);
    XCTAssertTrue(config.config[ScanlineConfigOptionFlatbed]);
    XCTAssertEqualObjects(config.config[ScanlineConfigOptionName], @"the_name");
}

- (void)testGettingTagsFromCommandline
{
    config = [config initWithArguments:[NSArray arrayWithObjects:@"taxes-2013", nil]];
    DDLogInfo(@"first tag: %@", [[config tags] objectAtIndex:0]);
    XCTAssertTrue([[[config tags] objectAtIndex:0] isEqualToString:@"taxes-2013"]);
}

- (void)testJpegOption
{
    config = [config initWithArguments:[NSArray arrayWithObjects:@"-jpeg", nil]];
    XCTAssertTrue(config.config[ScanlineConfigOptionJPEG]);
}

- (void)testJpegOptionWithJpg
{
    config = [config initWithArguments:[NSArray arrayWithObjects:@"-jpg", nil]];
    XCTAssertTrue(config.config[ScanlineConfigOptionJPEG]);
}

- (void)testResolutionOptionWithNonNumericalValue
{
    config = [config initWithArguments:[NSArray arrayWithObjects:@"-resolution", @"booger", nil]];
    XCTAssertEqual([config.config[ScanlineConfigOptionResolution] intValue], 0);
}

- (void)testLetterNotLegal
{
    config = [config initWithArguments:@[@"-letter"]];
    XCTAssertTrue(config.config[ScanlineConfigOptionLetter]);
    XCTAssertFalse(config.config[ScanlineConfigOptionLegal]);
}

- (void)testLegalNotLetter
{
    config = [config initWithArguments:@[@"-legal"]];
    XCTAssertTrue(config.config[ScanlineConfigOptionLegal]);
    XCTAssertFalse(config.config[ScanlineConfigOptionLetter]);
}
@end
