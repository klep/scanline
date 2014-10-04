//
//  ScanConfiguration.h
//  scanline
//
//  Created by Scott J. Kleper on 9/26/13.
//
//

#import <Foundation/Foundation.h>
#import "DDLog.h"

@interface ScanConfiguration : NSObject {
}

@property (getter = isDuplex)   BOOL               duplex;
@property (getter = isBatch)    BOOL               batch;
@property (getter = isFlatbed)  BOOL               flatbed;
@property (getter = listOnly)   BOOL               list;
@property (getter = isJpeg)     BOOL               jpeg;
@property (getter = isLegal)    BOOL               legal;
@property (getter = isMono)     BOOL               mono;
@property                       BOOL               open;
@property (strong)              NSString*          dir;
@property (strong)              NSString*          name;
@property (strong)              NSMutableArray*    tags;
@property (strong)              NSString*          scanner;
@property                       int                resolution;


- (id)init;
- (id)initWithArguments:(NSArray *)inArguments;
- (void)print;

- (NSString*)configFilePath;
@end

extern int ddLogLevel;
