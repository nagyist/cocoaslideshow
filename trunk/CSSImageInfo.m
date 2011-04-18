//
//  CSSImageContainer.m
//  CocoaSlideShow
//
//  Created by Nicolas Seriot on 25.08.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "CSSImageInfo.h"
#import "NSString+CSS.h"
#import "CocoaSlideShow.h"
#import "NSFileManager+CSS.h"
#import "NSImage+CSS.h"
#import "ImagesController.h"

static NSString *const kMultipleSelectionAllowsEdition = @"MultipleSelectionAllowsEdition";
static NSString *const kRenameFilesWithKeywords = @"RenameFilesWithKeywords";
static NSString *const kRenameFilesNameWithNumbering = @"RenameFilesNameWithNumbering";
static NSString *const kRenameFilesSeparator = @"RenameFilesSeparator";
static NSString *const kRenameLowercaseExtension = @"RenameLowercaseExtension";

@implementation CSSImageInfo

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

- (id)initWithPath:(NSString *)aPath andController:(ImagesController *)controller {
	self = [super init];
	[self setPath:aPath];
    imagesController = controller;
    formatter = [[NSNumberFormatter alloc] init];
	return self;
}

+ (CSSImageInfo *)containerWithPath:(NSString *)aPath andController:(ImagesController *)controller {
	return [[[CSSImageInfo alloc] initWithPath:aPath 
                                 andController:controller] autorelease];
}

- (void)dealloc {

	if(source) {
		CFRelease(source);
		source = nil;
	}

	[path release];
	[metadata release];
    [newFilename release];
    [formatter release];

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

// FIXME: not thread safe, source might be read while export and released too early while displaying map, @synchronized seems to kill performance though
- (BOOL)loadSource {
	/*
    BOOL isMap = [[[NSApp delegate] valueForKey:@"isMap"] boolValue];
	BOOL isExporting = [[[NSApp delegate] valueForKey:@"isExporting"] boolValue];
	BOOL multipleImagesSelected = [[[NSApp delegate] valueForKeyPath:@"imagesController.multipleImagesSelected"] boolValue];
	BOOL readOnMultiSelect = [[NSUserDefaults standardUserDefaults] boolForKey:kMultipleSelectionAllowsEdition];

    
	if(!readOnMultiSelect && multipleImagesSelected && !isMap && !isExporting) {
		return NO;
    }
     */
	
	//NSLog(@"-- loadSource %@", path);
	NSURL *url = [NSURL fileURLWithPath:path];

	source = CGImageSourceCreateWithURL((CFURLRef)url, NULL);

	NSString *UTI = nil;
	
	if (!source) {
		CGImageSourceStatus status = CGImageSourceGetStatus(source);
		NSLog(@"Error: could not create image source. Status: %d", status);
		return NO;
	}
	
	sourceRead = YES;
	
	// fill caches
	CFDictionaryRef metadataRef = CGImageSourceCopyPropertiesAtIndex(source,0,NULL);
	if(metadataRef) {
		NSDictionary *immutableMetadata = (NSDictionary *)metadataRef;
		
		//NSLog(@"-- immutableMetadata %@", immutableMetadata);
		
		[metadata release];
		metadata = [immutableMetadata mutableCopy];
		CFRelease(metadataRef);
	}
	
	UTI = (NSString *)CGImageSourceGetType(source);
	CFRelease(source);
	source = nil;
	
	[self willChangeValueForKey:@"isJpeg"];
	isJpeg = [UTI isEqualToString:@"public.jpeg"];
	[self didChangeValueForKey:@"isJpeg"];
    
	return YES;
}

- (void)rotateLeft {
	userRotation -= 90;
}

- (void)rotateRight {
	userRotation += 90;	
}

// http://www.impulseadventure.com/photo/exif-orientation.html
- (int)orientationDegrees {
	NSString *s = [[self metadata] valueForKey:@"Orientation"];
	if(!s) return userRotation;
	
	int o = [s intValue];
	switch(o) {
		case 1:
			return 0 + userRotation; break;
		case 8:
			return 90 + userRotation; break;
		case 3:
			return 180 + userRotation; break;
		case 6:
			return 270 + userRotation; break;
		default:
			return 0 + userRotation;
	}
}

- (NSString *)fileName {
    if (newFilename)
        return newFilename;
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

- (void)saveSourceWithMetadata {
    if(!source) {
		NSURL *url = [NSURL fileURLWithPath:path];
		source = CGImageSourceCreateWithURL((CFURLRef)url, NULL);
	}
	
	if(!source) {
		CGImageSourceStatus status = CGImageSourceGetStatus(source);
		NSLog(@"Error: could not create image source. Status: %d", status);
		return;
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
        return;
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
		return;
	}
	
	CFRelease(destination);
	if(source) {
		CFRelease(source);
		source = nil;
	}
	
	NSURL *url = [NSURL fileURLWithPath:path];
	NSError *error = nil;
	[data writeToURL:url options:NSAtomicWrite error:&error];

	if(error) {
		NSLog(@"-- error: can't write data: %@", [error localizedDescription]);
	}
    if (newFilename) {
        [self setFileName:newFilename];
        [newFilename release];
        newFilename = nil;
    }
    
	isModified = NO;
    [imagesController didSaveCSSImageInfo:self];
	return;
}

- (BOOL)isJPEGExt {
    return [[[self path] lowercaseString] hasSuffix:@".jpg"];
}

- (void)resizeJPEGWithOptions:(NSDictionary *)options {
    // Let a second change to rely on the extension to export
    if(![self isJpeg] && ![self isJPEGExt]) return;
    
    NSString *exportDir = [options objectForKey:@"ExportDir"];
	NSNumber *width = [options objectForKey:@"Width"];
	NSNumber *height = [options objectForKey:@"Height"];
	NSSize bbox = NSMakeSize([width floatValue], [height floatValue]);
    
    NSString *thumbPath = [[exportDir stringByAppendingPathComponent:[[self path] lastPathComponent]] lowercaseString];
    
    BOOL success = [NSImage scaleAndSaveJPEGThumbnailFromFile:[self path] toPath:thumbPath boundingBox:bbox rotation:[self orientationDegrees]];
    
    if(!success) {
        NSLog(@"Could not scale and save as jpeg into %@", thumbPath);
    }
}

- (BOOL)isJpeg {
	if(!sourceRead) [self loadSource];
	return isJpeg;
}

- (BOOL)isModified {
    return isModified;
}

- (NSString *)jsAddPoint {
	NSString *latitude = [self prettyLatitude];
	NSString *longitude = [self prettyLongitude];
	if([latitude length] == 0 || [longitude length] == 0) return nil;

	NSString *filePath = [self path];
	NSString *fileName = [filePath lastPathComponent];
	NSDictionary *fileAttributes = [[NSFileManager defaultManager] fileAttributesAtPath:filePath traverseLink:YES];
	NSString *fileModDateString = fileAttributes ? [[fileAttributes objectForKey:NSFileModificationDate] description] : @"";
	
	return [NSString stringWithFormat:@"addPoint(\"h%d\", %@, %@, \"%@\", \"%@\", \"%@\", %d);", [self hash], latitude, longitude, fileName, filePath, fileModDateString, [self orientationDegrees]];
}

- (NSString *)jsRemovePoint {
	return [NSString stringWithFormat:@"removePoint(\"h%d\");", [self hash]];
}

- (NSString *)jsShowPoint {
	return [NSString stringWithFormat:@"showPoint(\"h%d\");", [self hash]];
}

- (NSString *)jsHidePoint {
	return [NSString stringWithFormat:@"hidePoint(\"h%d\");", [self hash]];
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
	
	isModified = YES;
    [imagesController needSaveCSSImageInfo:self];
}

- (void)setFileNameWithKeywords:(NSArray *)keywords appendNumeration:(BOOL)appendNumeration {
    NSString *fname;
    
    if (appendNumeration) {
        int count = [[imagesController arrangedObjects] count];
        int num = [[imagesController arrangedObjects] indexOfObject:self] + 1;
        
        NSString *format = @"";
        
        while (count > 10) {
            format = [format stringByAppendingString:@"0"];
            count = count / 10;
        }
        
        [formatter setFormat: format];
        fname = [formatter stringFromNumber:[NSNumber numberWithInt:num]];
        fname = [fname stringByAppendingString:@"_"];
    } else {
        fname = @"";
    }
    NSString *separator = [[NSUserDefaults standardUserDefaults] stringForKey:kRenameFilesSeparator];
    int count = [keywords count];
    int i;
    for (i = 0; i < count; i++) {
        NSString *word = [keywords objectAtIndex:i];
        fname = [fname stringByAppendingString:word];
        if (i < count -1) {
            fname = [fname stringByAppendingString:separator];
        }
    }
    
    BOOL renameLowercaseExtension = [[NSUserDefaults standardUserDefaults] boolForKey:kRenameLowercaseExtension];
    if (renameLowercaseExtension) {
        fname = [fname stringByAppendingPathExtension:[[[self fileName] pathExtension] lowercaseString]];
    } else {
        fname = [fname stringByAppendingPathExtension:[[self fileName] pathExtension]];
    }

    [self willChangeValueForKey:@"fileName"];
    [newFilename release];
    newFilename = nil;
    newFilename = fname;
    [newFilename retain];
    [self didChangeValueForKey:@"fileName"];
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
	
    BOOL renameFilesWithKeywords = [[NSUserDefaults standardUserDefaults] boolForKey:kRenameFilesWithKeywords];
    if (renameFilesWithKeywords) {
        BOOL renameFilesNumeWithNumbering = [[NSUserDefaults standardUserDefaults] boolForKey:kRenameFilesNameWithNumbering];
        [self setFileNameWithKeywords:keywords appendNumeration:renameFilesNumeWithNumbering];
    }
    
    isModified = YES;
    [imagesController needSaveCSSImageInfo:self];
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
	//NSLog(@"--image with path:%@", path);
	int orientationDegrees = [self orientationDegrees];
	
	return [[[[NSImage alloc] initByReferencingFile:path] autorelease] rotatedWithAngle:orientationDegrees];
}

// just to appear to be KVC compliant, useful when droping an image on the imageView
- (void)setImage:(NSImage *)anImage {
	//NSLog(@"-- setImage:%@", anImage);
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
