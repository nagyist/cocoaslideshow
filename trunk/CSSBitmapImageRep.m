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

/*
- (id)init {
	self = [super init];
	NSLog(@"init %@", self);
	return self;
}
*/

- (NSImage *)image {
	return [[[NSImage alloc] initWithData:[self TIFFRepresentation]] autorelease];	// FIXME: too slow!!!
}

- (NSDictionary *)exif {
	return [super valueForProperty:NSImageEXIFData];
}


- (NSDictionary *)readGPS {
	//NSLog(@"readKeywords %@", self);
	CGImageSourceRef source = CGImageSourceCreateWithURL ((CFURLRef)[NSURL fileURLWithPath:path], nil);
	NSDictionary *properties = (NSDictionary*) CGImageSourceCopyPropertiesAtIndex(source, 0, NULL);
	//NSLog(@"-- properties: %@", properties);
    CFRelease(source);
	return [properties objectForKey:@"{GPS}"];
}


- (NSArray *)readKeywords {
	//NSLog(@"readKeywords %@", self);
	CGImageSourceRef source = CGImageSourceCreateWithURL ((CFURLRef)[NSURL fileURLWithPath:path], nil);
	NSDictionary *properties = (NSDictionary*) CGImageSourceCopyPropertiesAtIndex(source, 0, NULL);
	//NSLog(@"-- properties: %@", properties);
    CFRelease(source);
	return [[properties objectForKey:(NSString *)kCGImagePropertyIPTCDictionary] objectForKey:(NSString *)kCGImagePropertyIPTCKeywords];
}

- (void)setPath:(NSString *)aPath {
	//NSLog(@"%@ setPath %@", self, aPath);
	[self willChangeValueForKey:@"path"];
	[path autorelease];
	path = [aPath retain];
	[self didChangeValueForKey:@"path"];

	[self willChangeValueForKey:@"userComment"];
	userComment = [[[self exif] valueForKey:(NSString *)kCGImagePropertyExifUserComment] retain];
	[self didChangeValueForKey:@"userComment"];
	
	[self willChangeValueForKey:@"keywords"];
	keywords = [self readKeywords];
	[self didChangeValueForKey:@"keywords"];
	
	[self willChangeValueForKey:@"gps"];
	gps = [self readGPS];
	[self didChangeValueForKey:@"gps"];
	
	
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

- (NSDictionary *)gps {
	return gps;
}

- (NSString *)prettyGPS {
	NSString *latitude = [gps objectForKey:@"Latitude"];
	NSString *longitude = [gps objectForKey:@"Longitude"];
	NSString *latitudeRef = [gps objectForKey:@"LatitudeRef"];
	NSString *longitudeRef = [gps objectForKey:@"LongitudeRef"];
	
	if(!latitude || !longitude || !latitudeRef || !longitudeRef) return nil;
	
	return [NSString stringWithFormat:@"%@ %@, %@ %@", [[latitude description] substringToIndex:8], latitudeRef, [[longitude description] substringToIndex:8], longitudeRef];
}

- (NSURL *)googleMapsURL {
	NSString *latitude = [gps objectForKey:@"Latitude"];
	NSString *longitude = [gps objectForKey:@"Longitude"];

	if(!latitude || !longitude) return nil;
	
	NSString *s = [NSString stringWithFormat:@"http://maps.google.com/?q=%@,%@", latitude, longitude];
	return [NSURL URLWithString:s];
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
	//} else if ([keyPath isEqualToString:@"image"]) {
	//	return [self image];
	} else {
		return [super valueForKeyPath:keyPath];
	}
}

- (void)dealloc {
	//NSLog(@"dealloc %@", self);
	[path release];
	[userComment release];
	[keywords release];
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
