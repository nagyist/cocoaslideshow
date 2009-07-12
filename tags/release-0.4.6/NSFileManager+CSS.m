//
//  NSFileManager+CSS.m
//  CocoaSlideShow
//
//  Created by Nicolas Seriot on 17.08.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NSFileManager+CSS.h"


@implementation NSFileManager (CSS)

- (BOOL) isDirectory:(NSString *)path {
	BOOL isDir;
	[self fileExistsAtPath:path isDirectory:&isDir];
	return isDir;
}

- (NSArray *)directoryContentFullPaths:(NSString*)dirPath recursive:(BOOL)isRecursive {
	if(![self isDirectory:dirPath]) {
		return nil;
	}
	
	NSArray *dirContent = [[NSFileManager defaultManager] directoryContentsAtPath:dirPath];
	
	NSMutableArray *fullPaths = [[NSMutableArray alloc] init];
	
	NSEnumerator *e = [dirContent objectEnumerator];
	NSString *name;
	NSString *currentPath;
	while (( name = [e nextObject] )) {
		currentPath = [dirPath stringByAppendingPathComponent:name];
		if([self isDirectory:currentPath]) {
			if(isRecursive) {
				[fullPaths arrayByAddingObjectsFromArray:[self directoryContentFullPaths:currentPath recursive:YES]];
			} else {
				continue;
			}
		}
		
		[fullPaths addObject:[dirPath stringByAppendingPathComponent:name]];
	}
	
	return [fullPaths autorelease];	
}

- (NSString *)prettyFileSize:(NSString *)path {
	NSDictionary *fileAttributes = [[NSFileManager defaultManager] fileAttributesAtPath:path traverseLink:YES];
	float fileSize = (float)[fileAttributes fileSize];
	NSString *unit = @"bytes";
	
	if(fileSize > 1024) {
		fileSize /= 1024;
		unit = @"KB";
	}
	
	if(fileSize > 1024) {
		fileSize /= 1024;
		unit = @"MB";
		return [NSString stringWithFormat:@"%0.1f %@", fileSize, unit];
	} else {
		return [NSString stringWithFormat:@"%d %@", (int)fileSize, unit];	
	}

}

@end
