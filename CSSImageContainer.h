//
//  CSSImageContainer.h
//  CocoaSlideShow
//
//  Created by Nicolas Seriot on 25.08.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSSBitmapImageRep.h"

@interface CSSImageContainer : NSObject {
	NSString *path;
	CSSBitmapImageRep *bitmap;
	BOOL isFlagged;
	// TODO keep rotation angle
}

// TODO allow save rotated image

+ (CSSImageContainer *)containerWithPath:(NSString *)aPath;

- (NSString *)path;
- (void)forgetBitmap;

- (CSSBitmapImageRep *)bitmap;

- (NSString *)fileName;
- (void)setFileName:(NSString *)s;

- (void)flag;
- (void)unflag;
- (void)toggleFlag;
- (void)removeFlag;
- (BOOL)isFlagged;
- (NSImage *)flagIcon;

@end
