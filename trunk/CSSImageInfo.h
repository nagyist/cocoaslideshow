//
//  CSSImageContainer.h
//  CocoaSlideShow
//
//  Created by Nicolas Seriot on 25.08.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ImagesController;

@interface CSSImageInfo : NSObject {
	NSString *path;
    NSString *newFilename;
	CGImageSourceRef source;
	NSMutableDictionary *metadata;
    ImagesController *imagesController;
    NSNumberFormatter* formatter;

	BOOL sourceRead;
	BOOL isFlagged;
	BOOL isLoadingCache;
	BOOL isJpeg;
    BOOL isModified;
	
	int userRotation;
    
    NSLock *lock;
}

+ (CSSImageInfo *)containerWithPath:(NSString *)aPath andController:(ImagesController *)controller;

- (NSString *)jsAddPoint;
- (NSString *)jsRemovePoint;

- (NSString *)jsShowPoint;
- (NSString *)jsHidePoint;

- (NSString *)exifDateTime;

- (NSString *)prettyLatitude;
- (NSString *)prettyLongitude;

- (BOOL)loadSource;
- (BOOL)isJpeg;
- (BOOL)isModified;

- (NSImage *)image;

- (void)rotateLeft;
- (void)rotateRight;

- (int)orientationDegrees;

- (NSString *)path;
- (NSImage *)image;

- (NSDictionary *)exif;
- (NSDictionary *)gps;

- (NSString *)path;

- (NSURL *)googleMapsURL;

- (NSString *)fileName;
- (void)setFileName:(NSString *)s;

- (void)flag;
- (void)unflag;
- (void)toggleFlag;
- (void)removeFlag;
- (BOOL)isFlagged;
- (NSImage *)flagIcon;
- (void)saveSourceWithMetadata;
- (void)resizeJPEGWithOptions:(NSDictionary *)options;

@end
