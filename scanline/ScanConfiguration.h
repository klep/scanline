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
    NSMutableArray*                 mTags;
    NSMutableArray*                 mScannedDestinationURLs;
    NSString*                       mDir;
    NSString*                       mName;
    BOOL                            fBatch;
    BOOL                            fFlatbed;
}

@property (getter = isDuplex)   BOOL               duplex;
@property (getter = isBatch)    BOOL               batch;
@property (getter = isFlatbed)  BOOL               flatbed;
@property (strong)              NSString*          dir;
@property (strong)              NSString*          name;
@property (strong)              NSMutableArray*    tags;

- (id)init;
- (id)initWithArguments:(NSArray *)inArguments;

- (NSString*)configFilePath;
@end

extern int ddLogLevel;
