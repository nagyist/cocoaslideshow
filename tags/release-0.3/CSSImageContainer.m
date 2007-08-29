//
//  CSSImageContainer.m
//  CocoaSlideShow
//
//  Created by Nicolas Seriot on 25.08.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "CSSImageContainer.h"
#import "NSString+CSS.h"

@implementation CSSImageContainer

- (CSSBitmapImageRep *)bitmap {
	BOOL importDone = [[[NSApp delegate] valueForKey:@"importDone"] boolValue];
	BOOL isSaving = [[[NSApp delegate] valueForKey:@"isSaving"] boolValue];
	BOOL multipleImagesSelected = [[[NSApp delegate] valueForKey:@"multipleImagesSelected"] boolValue];

	if(!importDone || (multipleImagesSelected && !isSaving) ) {
		return nil;
	}

	if(bitmap != nil) {
		return bitmap;
	}

	bitmap = [[CSSBitmapImageRep alloc] initWithData:[NSData dataWithContentsOfFile:path]];
	[bitmap setPath:path];

	return bitmap;
}

- (void)dealloc {
	//NSLog(@"bitmap release %@", path);
	[path release];
	[bitmap release];
	[super dealloc];
}

- (void)forgetBitmap {
	[bitmap release];
	bitmap = nil;
}

- (void)copyToDirectory:(NSString *)destDirectory {
	NSString *destPath = [destDirectory stringByAppendingPathComponent:[path lastPathComponent]];
	NSFileManager *fm = [NSFileManager defaultManager];

	if ([fm fileExistsAtPath:path]) {
		[fm copyPath:path toPath:destPath handler:nil];
	}
}

- (void)moveToTrash {
	NSString *trashPath = [@"~/.Trash/" stringByAppendingPathComponent:[path lastPathComponent]];
	[[NSFileManager defaultManager] movePath:path toPath:trashPath handler:nil];
}

- (void)revealInFinder {
	NSString *parentDirectory = [path stringByDeletingLastPathComponent];
	[[NSWorkspace sharedWorkspace] openFile:parentDirectory];
}

- (NSString *)path {
	return path;
}

@end
