//
//  ScanConfiguration.m
//  scanline
//
//  Created by Scott J. Kleper on 9/26/13.
//
//

#import "ScanConfiguration.h"
#import "DDLog.h"

int ddLogLevel = LOG_LEVEL_INFO;

@interface ScanConfiguration()
@end

@implementation ScanConfiguration

+ (NSDictionary*)configOptions
{
    return @{
             ScanlineConfigOptionDuplex: @{
                     @"type": @"flag",
                     @"synonyms": @[@"dup"],
                     @"setter": @"duplex",
                     @"description": @"Duplex (two-sided) scanning mode, for scanners that support it."
                     },
             ScanlineConfigOptionBatch: @{
                     @"type": @"flag",
                     @"description": @"scanline will pause after each page, allowing you to continue to scan additional pages until you say you're done."
                     },
             ScanlineConfigOptionList: @{
                     @"description": @"List all available scanners, then exit."
                     },
             ScanlineConfigOptionFlatbed: @{
                     @"synonyms": @[@"fb"],
                     @"description": @"Scan from the scanner's flatbed (default is paper feeder)"
                     },
             ScanlineConfigOptionJPEG: @{
                     @"synonyms": @[@"jpg"],
                     @"description": @"Scan to a JPEG file (default is PDF)"
                     },
             ScanlineConfigOptionLegal: @{
                     @"description": @"Scan a legal size page"
                     },
             ScanlineConfigOptionLetter: @{
                     @"description": @"Scan a letter size page"
                     },
             ScanlineConfigOptionA4: @{
                     @"description": @"Scan a A4 size page"
                     },
             ScanlineConfigOptionMono: @{
                     @"synonyms": @[@"bw"],
                     @"description": @"Scan in monochrome (black and white)"
                     },
             ScanlineConfigOptionOpen: @{
                     @"description": @"Open the scanned image when done."
                     },
             ScanlineConfigOptionDir: @{
                     @"synonyms": @[@"folder"],
                     @"type": @"string",
                     @"description": @"Specify a directory where the files should go.",
                     @"default": [NSString stringWithFormat:@"%@/Documents/Archive", NSHomeDirectory()]
                     },
             ScanlineConfigOptionName: @{
                     @"type": @"string",
                     @"description": @"Specify a custom name for the output file."
                     },
             ScanlineConfigOptionVerbose: @{
                     @"synonyms": @[@"v"],
                     @"description": @"Provide verbose logging."
                     },
             ScanlineConfigOptionScanner: @{
                     @"synonyms": @[@"s"],
                     @"description": @"Specify which scanner to use (use -list to list available scanners).",
                     @"type": @"string"
                     },
             ScanlineConfigOptionResolution: @{
                     @"synonyms": @[@"res", @"minResolution"],
                     @"type": @"string",
                     @"description": @"Specify minimum resolution at which to scan (in dpi)",
                     @"default": @"150"
                     }
             };
}

+ (NSString*)canonicalConfigKeyFor:(NSString*)key
{
    NSDictionary* configOptions = [ScanConfiguration configOptions];
    
    if (configOptions[key] != nil) return key;
    
    for (NSString *canonicalKey in configOptions.keyEnumerator) {
        NSDictionary *details = configOptions[canonicalKey];
        if ([(NSArray*)details[@"synonyms"] containsObject:key]) return canonicalKey;
    }
    
    return nil;
}

- (id)init
{
    if (self = [super init]) {
        NSDictionary *configOptions = [ScanConfiguration configOptions];
        _config = [NSMutableDictionary dictionaryWithCapacity:configOptions.attributeKeys.count];
        
        _tags = [NSMutableArray arrayWithCapacity:0];
        
        [self loadConfigurationDefaults];
        [self loadConfigurationFromFile];
    }
    return self;
}

- (id)initWithArguments:(NSArray *)inArguments
{
    if (self = [self init]) {
        [self loadConfigurationFromArguments:inArguments];
    }
    return self;
}

- (void)help
{
    NSDictionary *configOptions = [ScanConfiguration configOptions];
    
    SKLog(@"Usage: scanline [-option] [-option] [tag] [tag] [tag]...");
    SKLog(@"");
    
    for (NSString *key in configOptions.keyEnumerator) {
        SKLog(@"-%@:", key);
        SKLog(@"Purpose: %@", configOptions[key][@"description"]);
        if (configOptions[key][@"default"] != nil) {
            SKLog(@"Default: %@", configOptions[key][@"default"]);
        }
        SKLog(@"");
    }
    
    SKLog(@"");
    SKLog(@"Examples:");
    SKLog(@"");
    SKLog(@"scanline -duplex taxes");
    SKLog(@"   ^-- Scan 2-sided and place in %@/taxes/", configOptions[ScanlineConfigOptionDir][@"default"]);
    SKLog(@"scanline bills dental");
    SKLog(@"   ^-- Scan and place in %@/bills/ with alias in %@/dental/",
          configOptions[ScanlineConfigOptionDir][@"default"],
          configOptions[ScanlineConfigOptionDir][@"default"]);
    
}

- (void)loadConfigurationDefaults
{
    NSDictionary *configOptions = [ScanConfiguration configOptions];

    for (NSString *key in configOptions.keyEnumerator) {
        NSDictionary *details = configOptions[key];
        if ([details[@"type"] isEqualToString:@"string"]) {
            if (details[@"default"] != nil) {
                _config[key] = details[@"default"];
            } else {
                // nil
            }
        } else {
            // default config type is flag initialized to nil
        }
    }
}


- (NSString*)configFilePath
{
    return [NSString stringWithFormat:@"%@/.scanline.conf", NSHomeDirectory()];
}

- (void)loadConfigurationFromFile
{
    NSString* configPath = [self configFilePath];
    DDLogVerbose(@"configPath: %@", configPath);
    
    if ([[NSFileManager defaultManager] isReadableFileAtPath:configPath]) {
        NSString* valueString = [NSString stringWithContentsOfFile:configPath encoding:NSUTF8StringEncoding error:nil];
        NSArray* values = [valueString componentsSeparatedByString:@"\n"];
        [self loadConfigurationFromArguments:values];
    }
}

- (void)loadConfigurationFromArguments:(NSArray*)inArguments
{
    DDLogVerbose(@"loading config from arguments: %@", inArguments);
    for (int i = 0; i < [inArguments count]; i++) {
        NSString* theArg = [inArguments objectAtIndex:i];

        if ([theArg isEqualToString:@"-help"] ||
            [theArg isEqualToString:@"--help"]) {
            [self help]; // haha self help!
            exit(1);
        } else if([theArg hasPrefix:@"-"]) {
            NSString *canonicalKey = [ScanConfiguration canonicalConfigKeyFor:[theArg substringFromIndex:1]];
            
            if (canonicalKey == nil) {
                SKLog(@"WARNING: Unknown option '%@' will be ignored", theArg);
            } else {
                NSDictionary *configDetails = [ScanConfiguration configOptions][canonicalKey];
                if ([(NSString *)configDetails[@"type"] isEqualToString:@"string"]) {
                    if (i < [inArguments count] && [inArguments objectAtIndex:i+1] != nil) {
                        NSString *value = [inArguments objectAtIndex:++i];
                        self.config[canonicalKey] = value;
                    } else {
                        SKLog(@"WARNING: No value provided for option '%@'", theArg);
                    }
                } else {
                    self.config[canonicalKey] = @YES;
                }
            }
        } else if (![theArg isEqualToString:@""]) {
            DDLogVerbose(@"Adding tag: %@", theArg);
            [_tags addObject:theArg];
        }
    }

    if (self.config[ScanlineConfigOptionVerbose]) {
        ddLogLevel = LOG_LEVEL_VERBOSE;
        DDLogVerbose(@"Verbose logging enabled.");
    }

    if ([self.config[ScanlineConfigOptionResolution] isEqualToString:@"0"]) {
        DDLogError(@"WARNING: Scanning at resolution of 0. This will scan at the scanner's lowest possible resolution.");
    }
}

@end





















