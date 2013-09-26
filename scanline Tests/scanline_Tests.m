//
//  scanline_Tests.m
//  scanline Tests
//
//  Created by Scott J. Kleper on 9/26/13.
//
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "ScanConfiguration.h"

@interface scanline_Tests : XCTestCase

@end

@implementation scanline_Tests

ScanConfiguration *config;

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.

    config = [ScanConfiguration alloc];
    id mock = [OCMockObject partialMockForObject:config];
    [[[mock stub] andReturn:@"scanline Tests/config_test.conf"] configFilePath];
}

- (void)tearDown
{
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


@end
