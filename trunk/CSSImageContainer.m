//
//  CSSImageContainer.m
//  CocoaSlideShow
//
//  Created by Nicolas Seriot on 25.08.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "CSSImageContainer.h"
#import "NSString+CSS.h"
#import "CocoaSlideShow.h"
#import "NSFileManager+CSS.h"

@implementation CSSImageContainer

+ (void)initialize {
    [self setKeys:[NSArray arrayWithObjects:@"isFlagged", nil] triggerChangeNotificationsForDependentKey:@"flagIcon"];
}

- (void)setPath:(NSString *)aPath {
	if(aPath == nil) {
		NSLog(@"-- aPath is nil :-(");
		return;
	}
	
	if(path != aPath) {
		[path release];
		path = [aPath retain];
	}
}

- (NSString *)path {
	return path;
}

- (id)initWithPath:(NSString *)aPath {
	self = [super init];
	[self setPath:aPath];
	return self;
}

+ (CSSImageContainer *)containerWithPath:(NSString *)aPath {
	return [[[CSSImageContainer alloc] initWithPath:aPath] autorelease];
}

- (void)dealloc {
	//NSLog(@"-- dealloc %@", path);
	
	[path release];
	
	if(source) {
		CFRelease(source);
		source = nil;
	}
	[path release];
	[metadata release];

	[super dealloc];
}

- (NSMutableDictionary *)metadata {
	if(!sourceRead) [self loadSource];
	return metadata;
}

- (NSString *)exifDateTime {
	NSDictionary *exif = [[self metadata] objectForKey:(NSString *)kCGImagePropertyExifDictionary];
	return [exif objectForKey:(NSString *)kCGImagePropertyExifDateTimeOriginal];
}

- (NSString *)prettyLatitude {
	NSDictionary *gps = [self gps];
	
	if(!gps) return @"";
	
	NSNumber *latitude = [gps objectForKey:@"Latitude"];
	NSString *latitudeRef = [gps objectForKey:@"LatitudeRef"];
	
	if(!latitude) return @"";
	
	return [latitudeRef isEqualToString:@"S"] ? [@"-" stringByAppendingFormat:@"%@", latitude] : [latitude description];
}

- (NSString *)prettyLongitude {
	NSDictionary *gps = [self gps];
	
	if(!gps) return @"";
	
	NSNumber *longitude = [gps objectForKey:@"Longitude"];
	NSString *longitudeRef = [gps objectForKey:@"LongitudeRef"];
	
	if(!longitude) return @"";
	
	return [longitudeRef isEqualToString:@"W"] ? [@"-" stringByAppendingFormat:@"%@", longitude] : [longitude description];
}

- (BOOL)loadSource {
	BOOL isMap = [[[NSApp delegate] valueForKey:@"isMap"] boolValue];
	BOOL multipleImagesSelected = [[[NSApp delegate] valueForKeyPath:@"imagesController.multipleImagesSelected"] boolValue];
	BOOL readOnMultiSelect = [[NSUserDefaults standardUserDefaults] boolForKey:@"MultipleSelectionAllowsEdition"];

	if(!readOnMultiSelect && multipleImagesSelected && !isMap) {
		return nil;
    }
	
	//NSLog(@"-- loadSource %@", path);
	NSURL *url = [NSURL fileURLWithPath:path];
	source = CGImageSourceCreateWithURL((CFURLRef)url, NULL);
	
	if (!source) {
		CGImageSourceStatus status = CGImageSourceGetStatus(source);
		NSLog(@"Error: could not create image source. Status: %d", status);
		return NO;
	}
	
	sourceRead = YES;
	
	// fill caches
	
	CFDictionaryRef metadataRef = CGImageSourceCopyPropertiesAtIndex(source,0,NULL);
	NSDictionary *immutableMetadata = (NSDictionary *)metadataRef;
	[metadata autorelease];
	metadata = [immutableMetadata mutableCopy];
	CFRelease(metadataRef);

	NSString *UTI = (NSString *)CGImageSourceGetType(source);

	CFRelease(source);
	source = nil;
	
	[self willChangeValueForKey:@"isJpeg"];
	isJpeg = [UTI isEqualToString:@"public.jpeg"];
	[self didChangeValueForKey:@"isJpeg"];
    
	return YES;
}

- (NSString *)fileName {
	return [path lastPathComponent];
}

- (void)setFileName:(NSString *)s {
	NSString *newPath = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:s];
	
	if([[NSFileManager defaultManager] fileExistsAtPath:newPath]) return;

	if([[NSFileManager defaultManager] movePath:path toPath:newPath handler:nil]) {
		[self setValue:newPath forKey:@"path"];
	}
}

- (NSString *)latitude {
	return [[self gps] objectForKey:(NSString *)kCGImagePropertyGPSLatitude];
}

- (NSString *)longitude {
	return [[self gps] objectForKey:(NSString *)kCGImagePropertyGPSLongitude];
}

- (NSString *)latitudeRef {
	return [[self gps] objectForKey:(NSString *)kCGImagePropertyGPSLatitudeRef];
}

- (NSString *)longitudeRef {
	return [[self gps] objectForKey:(NSString *)kCGImagePropertyGPSLongitudeRef];
}

- (NSDictionary *)exif {
	return [[self metadata] objectForKey:(NSString *)kCGImagePropertyExifDictionary];
}

- (NSDictionary *)iptc {
	return [[self metadata] objectForKey:(NSString *)kCGImagePropertyIPTCDictionary];
}

- (NSDictionary *)gps {
	return [[self metadata] objectForKey:(NSString *)kCGImagePropertyGPSDictionary];
}

- (BOOL)saveSourceWithMetadata {

	if(!source) {
		NSURL *url = [NSURL fileURLWithPath:path];
		source = CGImageSourceCreateWithURL((CFURLRef)url, NULL);
	}
	
	if(!source) {
		CGImageSourceStatus status = CGImageSourceGetStatus(source);
		NSLog(@"Error: could not create image source. Status: %d", status);
		return NO;
	}
	
	NSData *data = [NSMutableData data];
    CGImageDestinationRef destination = CGImageDestinationCreateWithData((CFMutableDataRef)data, (CFStringRef)@"public.jpeg", 1, NULL);
    if(!destination) {
        NSLog(@"Error: could not create image destination");
		CFRelease(destination);
		if(source) {
			CFRelease(source);
			source = nil;
		}
        return NO;
    }
    
    CGImageDestinationAddImageFromSource(destination, source, 0, (CFDictionaryRef)metadata);
    BOOL success = CGImageDestinationFinalize(destination); // write metadata into the data object
	if(!success) {
		NSLog(@"Error: could not finalize destination");
		CFRelease(destination);
		if(source) {
			CFRelease(source);
			source = nil;
		}
		return NO;
	}
	
	CFRelease(destination);
	if(source) {
		CFRelease(source);
		source = nil;
	}
	
	NSURL *url = [NSURL fileURLWithPath:path];
	NSError *error = nil;
	success = [data writeToURL:url options:NSAtomicWrite error:&error];

	if(error) {
		NSLog(@"-- error: can't write data: %@", [error localizedDescription]);
	}
	
	return success;
}

- (BOOL)isJpeg {
	return isJpeg;
}

- (void)setUserComment:(NSString *)comment {
	if(![self isJpeg]) return;

	if(!sourceRead) [self loadSource];
	
	[self willChangeValueForKey:@"userComment"];
	[self willChangeValueForKey:@"exif"];
	NSMutableDictionary *exifData = [[metadata objectForKey:(NSString *)kCGImagePropertyExifDictionary] mutableCopy];
	if(!exifData) {
		exifData = [[NSMutableDictionary alloc] init];
	}
	[exifData setObject:comment forKey:(NSString *)kCGImagePropertyExifUserComment];
	[metadata setObject:exifData forKey:(NSString *)kCGImagePropertyExifDictionary];
	[exifData release];
	[self didChangeValueForKey:@"exif"];
	[self didChangeValueForKey:@"userComment"];
	
	BOOL success = [self saveSourceWithMetadata];
	if(!success) {
		NSLog(@"Error: can't set user comment");
	}
	
	return;
}

- (void)setKeywords:(NSArray *)keywords {
	if(![self isJpeg]) return;

	if(!sourceRead) [self loadSource];

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
	
	NSString *latitude = [[gps objectForKey:(NSString *)kCGImagePropertyGPSLatitude] description];
	NSString *longitude = [[gps objectForKey:(NSString *)kCGImagePropertyGPSLongitude] description];
	NSString *latitudeRef = [gps objectForKey:(NSString *)kCGImagePropertyGPSLatitudeRef];
	NSString *longitudeRef = [gps objectForKey:(NSString *)kCGImagePropertyGPSLongitudeRef];
	
	if(!latitude || !longitude || !latitudeRef || !longitudeRef) return nil;
	
	NSString *trimedLatitude = [latitude length] > 8 ? [latitude substringToIndex:8] : latitude;
	NSString *trimedLongitude = [longitude length] > 8 ? [longitude substringToIndex:8] : longitude;
	
	return [NSString stringWithFormat:@"%@ %@, %@ %@", trimedLatitude, latitudeRef, trimedLongitude, longitudeRef];
}

- (NSImage *)image {
	//if(![[NSApp delegate] isFullScreen]) return nil;
	return [[[NSImage alloc] initByReferencingFile:path] autorelease];
}

- (NSURL *)googleMapsURL {
	NSString *latitude = [self prettyLatitude];
	NSString *longitude = [self prettyLongitude];
	
	if([latitude length] == 0 || [longitude length] == 0) return nil;
	
	NSString *s = [NSString stringWithFormat:@"http://maps.google.com/?q=%@,%@", latitude, longitude];
	return [NSURL URLWithString:s];
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

- (void)flag {
	[self setValue:[NSNumber numberWithBool:YES] forKey:@"isFlagged"];
}

- (void)unflag {
	[self setValue:[NSNumber numberWithBool:NO] forKey:@"isFlagged"];
}

- (void)toggleFlag {
	[self setValue:[NSNumber numberWithBool:!isFlagged] forKey:@"isFlagged"];
}

- (void)removeFlag {
	[self setValue:[NSNumber numberWithBool:NO] forKey:@"isFlagged"];	
}

- (BOOL)isFlagged {
	return isFlagged;
}

- (NSImage *)flagIcon {
	return isFlagged ? [NSImage imageNamed:@"Flagged.png"] : nil;
}

- (void)copyToDirectory:(NSString *)destDirectory {
	NSString *destPath = [destDirectory stringByAppendingPathComponent:[path lastPathComponent]];
	NSFileManager *fm = [NSFileManager defaultManager];

	if ([fm fileExistsAtPath:path]) {
		[fm copyPath:path toPath:destPath handler:nil];
	}
}

- (void)moveToTrash {
	NSString *trashPath = [[@"~/.Trash/" stringByExpandingTildeInPath] stringByAppendingPathComponent:[path lastPathComponent]];
	[[NSFileManager defaultManager] movePath:path toPath:trashPath handler:nil];
}

- (void)revealInFinder {
	[[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:@""];
}

@end
