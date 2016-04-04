//
//  ScanConfiguration.h
//  scanline
//
//  Created by Scott J. Kleper on 9/26/13.
//
//

#import <Foundation/Foundation.h>
#import "DDLog.h"

#define SKLog(FORMAT, ...) printf("%s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);

static NSString * const ScanlineConfigOptionDuplex = @"duplex";
static NSString * const ScanlineConfigOptionBatch = @"batch";
static NSString * const ScanlineConfigOptionList = @"list";
static NSString * const ScanlineConfigOptionFlatbed = @"flatbed";
static NSString * const ScanlineConfigOptionJPEG = @"jpeg";
static NSString * const ScanlineConfigOptionA4 = @"a4";
static NSString * const ScanlineConfigOptionLegal = @"legal";
static NSString * const ScanlineConfigOptionLetter = @"letter";
static NSString * const ScanlineConfigOptionMono = @"mono";
static NSString * const ScanlineConfigOptionOpen = @"open";
static NSString * const ScanlineConfigOptionDir = @"dir";
static NSString * const ScanlineConfigOptionName = @"name";
static NSString * const ScanlineConfigOptionVerbose = @"verbose";
static NSString * const ScanlineConfigOptionScanner = @"scanner";
static NSString * const ScanlineConfigOptionResolution = @"resolution";

@interface ScanConfiguration : NSObject

@property (strong, nonatomic) NSMutableArray *tags;
@property (strong, nonatomic) NSMutableDictionary *config;

- (id)init;
- (id)initWithArguments:(NSArray *)inArguments;

- (NSString*)configFilePath;
+ (NSDictionary*)configOptions;

@end

extern int ddLogLevel;
