//
//  CSSImageContainer.h
//  CocoaSlideShow
//
//  Created by Nicolas Seriot on 25.08.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CSSImageContainer : NSObject {
	NSString *path;
	CGImageSourceRef source;
	NSMutableDictionary *metadata;

	BOOL sourceRead;
	BOOL isFlagged;
	BOOL isLoadingCache;
	BOOL isJpeg;
	
	int userRotation;
}

- (NSString *)exifDateTime;

- (NSString *)prettyLatitude;
- (NSString *)prettyLongitude;

- (BOOL)loadSource;

- (NSImage *)image;

- (void)rotateLeft;
- (void)rotateRight;

- (int)orientationDegrees;

- (NSString *)path;
- (NSImage *)image;

- (NSDictionary *)exif;
- (NSDictionary *)gps;

+ (CSSImageContainer *)containerWithPath:(NSString *)aPath;

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

@end
