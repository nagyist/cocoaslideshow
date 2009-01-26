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
	return [metadata objectForKey:(NSString *)kCGImagePropertyExifDictionary];
}

- (NSDictionary *)iptc {
	return [metadata objectForKey:(NSString *)kCGImagePropertyIPTCDictionary];
}

- (NSDictionary *)gps {
	return [metadata objectForKey:(NSString *)kCGImagePropertyGPSDictionary];
}

- (void)setPath:(NSString *)aPath {
	//NSLog(@"%@ setPath %@", self, aPath);
	
	[path autorelease];
	path = aPath;
	[path retain];
	
	[url autorelease];
	url = [NSURL fileURLWithPath:aPath];
	[url retain];
	
	source = CGImageSourceCreateWithURL( (CFURLRef) url, NULL);
	if (!source) {
		NSLog(@"Error: could not create image source");
		return;
	}
	
	NSDictionary *immutableMetadata = (NSDictionary *) CGImageSourceCopyPropertiesAtIndex(source,0,NULL);
	[metadata autorelease];
	metadata = [immutableMetadata mutableCopy];
	[immutableMetadata release];
}

- (BOOL)saveSourceWithMetadata {
	CFStringRef UTI = CGImageSourceGetType(source);
    NSMutableData *data = [NSMutableData data];
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithData((CFMutableDataRef)data, UTI, 1, NULL);
    if(!destination) {
        NSLog(@"Error: could not create image destination");
		CFRelease(destination);
        return NO;
    }
    
    CGImageDestinationAddImageFromSource(destination, source, 0, (CFDictionaryRef)metadata);
    
    BOOL success = CGImageDestinationFinalize(destination); // write metadata into the data object
	if(!success) {
		NSLog(@"Error: could not finalize destination");
		CFRelease(destination);
		return NO;
	}
	
	CFRelease(destination);
	return [data writeToURL:url atomically:YES];	
}

- (BOOL)isJpeg {
	CFStringRef UTI = CGImageSourceGetType(source); //this is the type of image (e.g., public.jpeg)
	return [(NSString *)UTI isEqualToString:@"public.jpeg"];
}

- (void)setUserComment:(NSString *)comment {
	//NSLog(@"set user comment: %@", comment);
	if(![self isJpeg]) {
		return;
	}
	
	[self willChangeValueForKey:@"exif"];
	[self willChangeValueForKey:@"userComment"];
	NSMutableDictionary *exifData = [[metadata objectForKey:(NSString *)kCGImagePropertyExifDictionary] mutableCopy];
	if(!exifData) {
		exifData = [[NSMutableDictionary alloc] init];
	}
	[exifData setObject:comment forKey:(NSString *)kCGImagePropertyExifUserComment];
	[metadata setObject:exifData forKey:(NSString *)kCGImagePropertyExifDictionary];
	[exifData release];
	[self didChangeValueForKey:@"userComment"];
	[self didChangeValueForKey:@"exif"];
	
	BOOL success = [self saveSourceWithMetadata];
	if(!success) {
		NSLog(@"Error: can't set user comment");
	}
}

- (void)setKeywords:(NSArray *)keywords {
	//NSLog(@"set user keywords: %@", keywords);
	if(![self isJpeg]) {
		return;
	}

	[self willChangeValueForKey:@"keywords"];
	NSMutableDictionary *iptcDict = [[self iptc] mutableCopy];
	if(!iptcDict) {
		iptcDict = [[NSMutableDictionary alloc] init];
	}
	[iptcDict setObject:keywords forKey:(NSString *)kCGImagePropertyIPTCKeywords];
	[metadata setObject:iptcDict forKey:(NSString *)kCGImagePropertyIPTCDictionary];
	[iptcDict release];
	[self didChangeValueForKey:@"keywords"];
	
	BOOL success = [self saveSourceWithMetadata];
	if(!success) {
		NSLog(@"Error: can't set keywords");
	}
}

- (NSArray *)keywords {
	return [[self iptc] objectForKey:(NSString *)kCGImagePropertyIPTCKeywords];
}

- (NSString *)userComment {
	return [[self exif] objectForKey:(NSString *)kCGImagePropertyExifUserComment];
}

- (NSString *)prettyGPS {
	NSDictionary *gps = [self gps];
	if(!gps) return nil;
	
	NSString *latitude = [gps objectForKey:(NSString *)kCGImagePropertyGPSLatitude];
	NSString *longitude = [gps objectForKey:(NSString *)kCGImagePropertyGPSLongitude];
	NSString *latitudeRef = [gps objectForKey:(NSString *)kCGImagePropertyGPSLatitudeRef];
	NSString *longitudeRef = [gps objectForKey:(NSString *)kCGImagePropertyGPSLongitudeRef];
	
	if(!latitude || !longitude || !latitudeRef || !longitudeRef) return nil;
	
	return [NSString stringWithFormat:@"%@ %@, %@ %@", [[latitude description] substringToIndex:8], latitudeRef, [[longitude description] substringToIndex:8], longitudeRef];
}

- (NSURL *)googleMapsURL {
	NSDictionary *gps = [self gps];
	if(!gps) return nil;
	
	NSString *latitude = [gps objectForKey:(NSString *)kCGImagePropertyGPSLatitude];
	NSString *longitude = [gps objectForKey:(NSString *)kCGImagePropertyGPSLongitude];
	
	if(!latitude || !longitude) return nil;
	
	NSString *s = [NSString stringWithFormat:@"http://maps.google.com/?q=%@,%@", latitude, longitude];
	return [NSURL URLWithString:s];
}

- (NSString *)gmapMarkerWithIndex:(int)i {
	NSDictionary *gps = [self gps];
	if(!gps) return @"";
	NSString *marker = [NSString stringWithFormat:@"marker%d", i];
	NSNumber *latitude = [gps objectForKey:@"Latitude"];
	NSNumber *longitude = [gps objectForKey:@"Longitude"];
	
//	return [NSString stringWithFormat:@"\nvar %@ = new GMarker(new GLatLng(%@,%@), {title: \"test\"});\n \
//			map.addOverlay(%@);\n \
//			GEvent.addListener(%@, \"click\", function() { %@.openInfoWindowHtml(\"xxx\") });\n \
//			bounds.extend(%@.getLatLng());\n\n",
//			marker, latitude, longitude, marker, marker, marker, marker];

	return [NSString stringWithFormat:@"\nvar %@ = new GMarker(new GLatLng(%@,%@), {title: \"test\"});\n \
			map.addOverlay(%@);\n \
			bounds.extend(%@.getLatLng());\n\n",
			marker, latitude, longitude, marker, marker, marker, marker];	
}

- (NSString *)exifDateTime {
	NSDictionary *exif = [metadata objectForKey:@"{Exif}"];
	return [exif objectForKey:(NSString *)kCGImagePropertyExifDateTimeOriginal];
}

- (void)dealloc {
	[path release];
	[super dealloc];
}

- (NSString *)prettyImageSize {
	NSString *x = [[self exif] objectForKey:(NSString *)kCGImagePropertyExifPixelXDimension];
	NSString *y = [[self exif] objectForKey:(NSString *)kCGImagePropertyExifPixelYDimension];
	if(x && y) {
		return [NSString stringWithFormat:@"%@x%@", x, y];
	}
	return nil;
}

- (NSString *)prettyFileSize {
	return [[NSFileManager defaultManager] prettyFileSize:path];	
}

@end
