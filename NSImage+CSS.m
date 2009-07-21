//
//  NSImage+CSS.m
//  CocoaSlideShow
//
//  Created by Nicolas Seriot on 19.07.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

// http://www.cocoadev.com/index.pl?ThumbnailImages

#import "NSImage+CSS.h"
#import <Epeg/EpegWrapper.h>

@implementation NSImage (CSS)

+(BOOL)scaleAndSaveJPEGThumbnailFromFile:(NSString *)srcPath toPath:(NSString *)dstPath boundingBox:(NSSize)boundingBox {
	NSImage *thumbnail = [EpegWrapper imageWithPath2:srcPath boundingBox:boundingBox];
	
	NSData *jpegData = [NSBitmapImageRep representationOfImageRepsInArray:[thumbnail representations]
																usingType:NSJPEGFileType
															   properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.75]
																									  forKey:NSImageCompressionFactor]];
	return [jpegData writeToFile:dstPath atomically:NO];
}

+(BOOL)scaleAndSaveAsJPEG:(NSString *)source 
				 maxwidth:(int)width 
				maxheight:(int)height 
				  quality:(float)quality
				   saveTo:(NSString *)dest {
	
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSBitmapImageRep *rep = nil;
    NSBitmapImageRep *output = nil;
    NSImage *scratch = nil;
    int w,h,nw,nh;
    NSData *bitmapData;
    
    rep = [NSBitmapImageRep imageRepWithContentsOfFile:source];
    
    // could not open file
    if (!rep) {
		NSLog(@"Could not load '%@'", source);
		[pool release];
		return NO;
    }
    
    // validation
    if (quality<=0.0) quality = 0.85;
    if (quality>1.0) quality = 1.00;
    
    // source image size
    w = nw = [rep pixelsWide];
    h = nh = [rep pixelsHigh];
    
    if (w>width || h>height) {
		float wr, hr;
		
		// ratios
		wr = w/(float)width;
		hr = h/(float)height;
		
		
		if (wr>hr) { // landscape
			nw = width;
			nh = h/wr;
		} else { // portrait
			nh = height;
			nw = w/hr;
		}
    }
    
    // image to render into
    scratch = [[[NSImage alloc] initWithSize:NSMakeSize(nw, nh)] autorelease];
    
    // could not create image
    if (!scratch) {
		NSLog(@"Could not render image");
		[pool release];
		return NO;
    }
    
    // draw into image, to scale it
    [scratch lockFocus];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    [rep drawInRect:NSMakeRect(0.0, 0.0, nw, nh)];
    output = [[[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0,0,nw,nh)] autorelease];
    [scratch unlockFocus];
    
    // could not get result
    if (!output) {
		NSLog(@"Could not scale image");
		[pool release];
		return NO;
    }
    
    // save as JPEG
    NSDictionary *properties =
	[NSDictionary dictionaryWithObjectsAndKeys:
	 [NSNumber numberWithFloat:quality],
	 NSImageCompressionFactor, NULL];    
    
    bitmapData = [output representationUsingType:NSJPEGFileType
									  properties:properties];
    
    // could not get result
    if (!bitmapData) {
		NSLog(@"Could not convert to JPEG");
		[pool release];
		return NO;
    }
    
    BOOL ret = [bitmapData writeToFile:dest atomically:YES];
    
    [pool release];
    
    return ret;
}

@end
