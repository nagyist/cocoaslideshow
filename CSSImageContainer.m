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

/*
- (id)init {
	self = [super init];
	NSLog(@"init %@", self);
	return self;
}
*/

+ (void)initialize {
    [self setKeys:[NSArray arrayWithObjects:@"isFlagged", nil] triggerChangeNotificationsForDependentKey:@"flagIcon"];
}

- (CSSBitmapImageRep *)bitmap {
	BOOL importDone = [[[NSApp delegate] valueForKeyPath:@"imagesController.importDone"] boolValue];
	BOOL isSaving = [[[NSApp delegate] valueForKey:@"isSaving"] boolValue];
	BOOL multipleImagesSelected = [[[NSApp delegate] valueForKeyPath:@"imagesController.multipleImagesSelected"] boolValue];

	if(!importDone || (multipleImagesSelected && !isSaving) ) {
		return nil;
	}

	if(bitmap != nil) {
		return bitmap;
	}

	//NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"file://%@", path]]];
	NSData *data = [NSData dataWithContentsOfFile:path];
	//NSLog(@"data %d path %@", [data length], path);
	//NSArray *reps = [NSBitmapImageRep imageRepsWithData:data];
	//NSLog(@"-- %@", reps);
	bitmap = [[CSSBitmapImageRep alloc] initWithData:data];
	[bitmap setPath:path];

	return bitmap;
}

- (void)dealloc {
	//NSLog(@"dealloc %@", self);
	[path release];
	[bitmap release];
	[super dealloc];
}

- (void)forgetBitmap {
	[bitmap release];
	bitmap = nil;
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

- (NSString *)path {
	return path;
}

@end
