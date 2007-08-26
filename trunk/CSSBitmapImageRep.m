//
//  NSBitmapImageRep+Exif.m
//  CocoaSlideShow
//
//  Created by Nicolas Seriot on 22.08.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "CSSBitmapImageRep.h"
#import "NSString+CSS.h"

@implementation CSSBitmapImageRep

+ (void)initialize {
	[self exposeBinding:@"exif"];
}

- (NSDictionary *)exif {
	return [super valueForProperty:NSImageEXIFData];
}

- (void)setPath:(NSString *)aPath {
	[path autorelease];
	path = [aPath retain];
	userComment = [[self exif] valueForKey:(NSString *)kCGImagePropertyExifUserComment];
}

- (void)setUserComment:(NSString *)comment {
	if(![path pathIsJpeg]) {
		return;
	}
	
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

- (NSString *)userComment {
	return userComment;
}

- (id)valueForKeyPath:(NSString *)keyPath {
	if(![keyPath hasPrefix:@"exif."]) {
		return [super valueForKeyPath:keyPath];
	}
	
	NSArray *fullPathComponents = [keyPath componentsSeparatedByString: @"."];
	NSArray *shortPathComponents = [fullPathComponents subarrayWithRange:NSMakeRange(1, [fullPathComponents count] - 1)];
	NSString *exifPath = [shortPathComponents componentsJoinedByString:@"."];
	return [[super valueForProperty:NSImageEXIFData] valueForKeyPath:exifPath];
}

- (void)dealloc {
	[path release];
	[super dealloc];
}

- (NSString *)prettySize {
	NSString *x = [self valueForKeyPath:@"exif.PixelXDimension"];
	NSString *y = [self valueForKeyPath:@"exif.PixelYDimension"];
	if(x && y) {
		return [NSString stringWithFormat:@"%@x%@", x, y];
	}
	return nil;
}

@end
