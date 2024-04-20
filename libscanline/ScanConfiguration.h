//
//  ScanConfiguration.h
//  scanline
//
//  Created by Scott J. Kleper on 9/26/13.
//
//

#import <Foundation/Foundation.h>

#define SKLog(FORMAT, ...) printf("%s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);

NS_ASSUME_NONNULL_BEGIN

static NSString * const ScanlineConfigOptionDuplex = @"duplex";
static NSString * const ScanlineConfigOptionBatch = @"batch";
static NSString * const ScanlineConfigOptionList = @"list";
static NSString * const ScanlineConfigOptionFlatbed = @"flatbed";
static NSString * const ScanlineConfigOptionJPEG = @"jpeg";
static NSString * const ScanlineConfigOptionTIFF = @"tiff";
static NSString * const ScanlineConfigOptionLegal = @"legal";
static NSString * const ScanlineConfigOptionLetter = @"letter";
static NSString * const ScanlineConfigOptionA4 = @"a4";
static NSString * const ScanlineConfigOptionMono = @"mono";
static NSString * const ScanlineConfigOptionOpen = @"open";
static NSString * const ScanlineConfigOptionDir = @"dir";
static NSString * const ScanlineConfigOptionName = @"name";
static NSString * const ScanlineConfigOptionVerbose = @"verbose";
static NSString * const ScanlineConfigOptionScanner = @"scanner";
static NSString * const ScanlineConfigOptionResolution = @"resolution";
static NSString * const ScanlineConfigOptionBrowseSecs = @"browsesecs";
static NSString * const ScanlineConfigOptionExactName = @"exactname";
static NSString * const ScanlineConfigOptionOCR = @"ocr";

@interface ScanConfiguration : NSObject

@property (strong, nonatomic) NSMutableArray *tags;
@property (strong, nonatomic) NSMutableDictionary *config;

- (nonnull id)init;
- (nonnull id)initWithArguments:(nonnull NSArray *)inArguments;
- (nonnull id)initWithArguments:(nonnull NSArray *)inArguments configFilePath:(NSString *)configFilePath;

+ (nonnull NSDictionary *)configOptions;

@end

extern BOOL verboseLogging;

NS_ASSUME_NONNULL_END
