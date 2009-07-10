//
//  CSSImageContainer.h
//  CocoaSlideShow
//
//  Created by Nicolas Seriot on 25.08.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CSSImageContainer : NSObject {

@protected
	
	CGImageSourceRef source;
	NSMutableDictionary *metadata;
	BOOL sourceRead; // read source once
	
	NSString *UTI; //this is the type of image (e.g., public.jpeg)
	NSString *path;
	BOOL isFlagged;
	
	BOOL isLoadingCache;
	
	BOOL isJpeg;
}

- (NSString *)exifDateTime;

- (NSString *)prettyLatitude;
- (NSString *)prettyLongitude;

- (BOOL)loadSource;

- (NSImage *)image;


- (NSString *)path;
- (NSImage *)image;

- (NSDictionary *)exif;
- (NSDictionary *)gps;

+ (CSSImageContainer *)containerWithPath:(NSString *)aPath;

- (NSString *)path;

//- (void)loadNewBitmap;
//- (void)forgetBitmap;

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
