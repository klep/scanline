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
    [[[mock stub] andReturn:@"scanline Tests/config_test.conf"] configFilePath];
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
    XCTAssertTrue([config isDuplex]);
    XCTAssertFalse([config isBatch]);
    XCTAssertFalse([config isFlatbed]);
    XCTAssertEqualObjects([config name], @"the_name");
}

- (void)testLoadConfigurationFromFileUsingEmptyArguments
{
    config = [config initWithArguments:[NSArray array]];
    XCTAssertTrue([config isDuplex]);
    XCTAssertFalse([config isBatch]);
    XCTAssertFalse([config isFlatbed]);
    XCTAssertEqualObjects([config name], @"the_name");
}

- (void)testLoadConfigurationFromFileWithArgumentOverride
{
    config = [config initWithArguments:[NSArray arrayWithObjects:@"-flatbed", nil]];
    XCTAssertTrue([config isDuplex]);
    XCTAssertFalse([config isBatch]);
    XCTAssertTrue([config isFlatbed]);
    XCTAssertEqualObjects([config name], @"the_name");
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
    XCTAssertTrue([config isJpeg]);
}

- (void)testJpegOptionWithJpg
{
    config = [config initWithArguments:[NSArray arrayWithObjects:@"-jpg", nil]];
    XCTAssertTrue([config isJpeg]);
}

- (void)testResolutionOptionWithNonNumericalValue
{
    config = [config initWithArguments:[NSArray arrayWithObjects:@"-resolution", @"booger", nil]];
    XCTAssertEqual([config resolution], 0);
}

@end
