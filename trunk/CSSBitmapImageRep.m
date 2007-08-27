//
//  NSBitmapImageRep+Exif.m
//  CocoaSlideShow
//
//  Created by Nicolas Seriot on 22.08.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "CSSBitmapImageRep.h"
#import "NSString+CSS.h"
#import "NSFileManager+CSS.h"

@implementation CSSBitmapImageRep

+ (void)initialize {
	[self exposeBinding:@"exif"];
}

- (NSDictionary *)exif {
	return [super valueForProperty:NSImageEXIFData];
}

- (NSArray *)readKeywords {
	CGImageSourceRef source = CGImageSourceCreateWithURL ((CFURLRef)[NSURL fileURLWithPath:path], nil);
	NSDictionary *properties = (NSDictionary*) CGImageSourceCopyPropertiesAtIndex(source, 0, NULL);
	return [[properties objectForKey:(NSString *)kCGImagePropertyIPTCDictionary] objectForKey:(NSString *)kCGImagePropertyIPTCKeywords];
}

- (void)setPath:(NSString *)aPath {
	[self willChangeValueForKey:@"path"];
	[path autorelease];
	path = [aPath retain];
	[self didChangeValueForKey:@"path"];

	[self willChangeValueForKey:@"userComment"];
	userComment = [[self exif] valueForKey:(NSString *)kCGImagePropertyExifUserComment];
	[self didChangeValueForKey:@"userComment"];
	
	[self willChangeValueForKey:@"keywords"];
	keywords = [self readKeywords];
	[self didChangeValueForKey:@"keywords"];
	
	//NSLog(@"[self exif] %@", [self exif]);
	//NSLog(@"keywords = %@", keywords);
}

- (void)setUserComment:(NSString *)comment {
	if(![path pathIsJpeg]) {
		return;
	}
	
	NSLog(@"setUserComment %@", comment);
	
	[self willChangeValueForKey:@"userComment"];
	[userComment autorelease];
	userComment = [comment retain];
	[self didChangeValueForKey:@"userComment"];
		
	NSMutableDictionary *exifData = [[self valueForProperty:NSImageEXIFData] mutableCopy];
	if(!exifData) {
		exifData = [[NSMutableDictionary alloc] init];
	}
	[exifData setValue:userComment forKey:(NSString *)kCGImagePropertyExifUserComment];
	
	NSData *data = [self representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:exifData forKey:NSImageEXIFData]];
	[exifData release];
	[data writeToFile:path atomically:YES];
}

- (void)setKeywords:(NSArray *)asciiKeywords {
	if(![path pathIsJpeg]) {
		return;
	}

	NSLog(@"setKeywords %@", asciiKeywords);
	[self willChangeValueForKey:@"keywords"];
	[keywords autorelease];
	keywords = [asciiKeywords retain];
	[self didChangeValueForKey:@"keywords"];
	
	NSMutableDictionary *iptcDictionary = [NSDictionary dictionaryWithObject:asciiKeywords forKey:(NSString *)kCGImagePropertyIPTCKeywords];
	NSDictionary *newImageProperties = [NSDictionary dictionaryWithObject:iptcDictionary forKey:(NSString *)kCGImagePropertyIPTCDictionary];

	NSMutableData *newImageFileData = [[NSMutableData alloc] init];
	CGImageSourceRef imageSource = CGImageSourceCreateWithURL ((CFURLRef)[NSURL fileURLWithPath:path], nil);
	CGImageDestinationRef imageDestination = CGImageDestinationCreateWithData((CFMutableDataRef)newImageFileData, CGImageSourceGetType(imageSource), 1, NULL);

	CGImageDestinationAddImageFromSource(imageDestination, imageSource, 0, (CFDictionaryRef) newImageProperties);

    if (CGImageDestinationFinalize(imageDestination))
        [newImageFileData writeToFile:path atomically:YES];

    CFRelease(imageDestination);
    CFRelease(imageSource);
    [newImageFileData release];
}

- (NSArray *)keywords {
	return keywords;
}

- (NSString *)userComment {
	return userComment;
}

- (id)valueForKeyPath:(NSString *)keyPath {
	if([keyPath hasPrefix:@"exif."]) {	
		NSArray *fullPathComponents = [keyPath componentsSeparatedByString: @"."];
		NSArray *shortPathComponents = [fullPathComponents subarrayWithRange:NSMakeRange(1, [fullPathComponents count] - 1)];
		NSString *exifPath = [shortPathComponents componentsJoinedByString:@"."];
		return [[super valueForProperty:NSImageEXIFData] valueForKeyPath:exifPath];
	} else {
		return [super valueForKeyPath:keyPath];
	}
}

- (void)dealloc {
	[path release];
	//[userComment release]; // FIXME uncomment and fix crash
	//[keywords release]; // FIXME uncomment and fix crash
	[super dealloc];
}

- (NSString *)prettyImageSize {
	NSString *x = [self valueForKeyPath:@"exif.PixelXDimension"];
	NSString *y = [self valueForKeyPath:@"exif.PixelYDimension"];
	if(x && y) {
		return [NSString stringWithFormat:@"%@x%@", x, y];
	}
	return nil;
}

- (NSString *)prettyFileSize {
	return [[NSFileManager defaultManager] prettyFileSize:path];	
}

@end
