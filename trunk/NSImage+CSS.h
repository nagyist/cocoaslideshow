//
//  NSImage+CSS.h
//  CocoaSlideShow
//
//  Created by Nicolas Seriot on 19.07.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSImage (CSS)

+ (BOOL)scaleAndSaveJPEGThumbnailFromFile:(NSString *)srcPath
								  toPath:(NSString *)dstPath
							 boundingBox:(NSSize)boundingBox;

+ (BOOL)scaleAndSaveAsJPEG:(NSString *)source
				 maxwidth:(int)width
				maxheight:(int)height
				  quality:(float)quality
				   saveTo:(NSString *)dest;

- (NSImage *)rotatedImageByDegrees:(int)degrees;

@end
