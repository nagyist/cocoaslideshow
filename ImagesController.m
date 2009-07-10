#import "ImagesController.h"
#import "CSSImageContainer.h"
#import "NSFileManager+CSS.h"
#import "CocoaSlideShow.h"

@implementation ImagesController

- (void)awakeFromNib {
	inMemoryBitmapsContainers = [[NSMutableArray alloc] initWithCapacity:IN_MEMORY_BITMAPS];

	allowedExtensions = [NSArray arrayWithObjects:@"jpg", @"jpeg", @"jpe", @"tif", @"tiff", @"gif", @"png", @"pct", @"pict", @"pic",
								  //@"pdf", @"eps", @"epi", @"epsf", @"epsi", @"ps",
								  @"ico", @"icns",  @"bmp", @"bmpf",
								  @"dng", @"cr2", @"crw", @"fpx", @"fpix", @"raf", @"dcr", @"ptng", @"pnt", @"mac", @"mrw", @"nef",
								  @"orf", @"exr", @"psd", @"qti", @"qtif", @"hdr", @"sgi", @"srf", @"targa", @"tga", @"cur", @"xbm", nil];
	[allowedExtensions retain];	
}

- (void)dealloc {
	[inMemoryBitmapsContainers release];
	[super dealloc];
}

- (NSUndoManager *)undoManager {
	return [cocoaSlideShow undoManager];
}

- (NSIndexSet *)flaggedIndexes {
	NSMutableIndexSet *flaggedIndexes = [[NSMutableIndexSet alloc] init];
	
	NSEnumerator *e = [[self arrangedObjects] objectEnumerator];
	CSSImageContainer *container;
	while(( container = [e nextObject] )) {
		if([container isFlagged]) {
			[flaggedIndexes addIndex:[[self arrangedObjects] indexOfObject:container]];
		}
	}
	[self setSelectionIndexes:flaggedIndexes];
	return [flaggedIndexes autorelease];
}

- (void)flagIndexes:(NSIndexSet *)indexSet {
	[[[self arrangedObjects] objectsAtIndexes:indexSet] makeObjectsPerformSelector:@selector(flag)]; 
}

- (IBAction)flag:(id)sender {
	[[[self undoManager] prepareWithInvocationTarget:self] unflag:self];
	[[self selectedObjects] makeObjectsPerformSelector:@selector(flag)];
}

- (IBAction)unflag:(id)sender {
	[[[self undoManager] prepareWithInvocationTarget:self] flag:self];
	[[self selectedObjects] makeObjectsPerformSelector:@selector(unflag)];
}

- (IBAction)toggleFlags:(id)sender {
	[[[self undoManager] prepareWithInvocationTarget:self] toggleFlags:self];
	[[self selectedObjects] makeObjectsPerformSelector:@selector(toggleFlag)];
}

- (IBAction)selectFlags:(id)sender {
	[[[self undoManager] prepareWithInvocationTarget:self] setSelectionIndexes:[self selectionIndexes]];
	[self setSelectionIndexes:[self flaggedIndexes]];
}

- (IBAction)removeAllFlags:(id)sender {
	[[[self undoManager] prepareWithInvocationTarget:self] flagIndexes:[self flaggedIndexes]];
	[[self arrangedObjects] makeObjectsPerformSelector:@selector(removeFlag)];
}

- (IBAction)remove:(id)sender {
	[[[self undoManager] prepareWithInvocationTarget:self] performSelector:@selector(addFiles:) withObject:[self valueForKeyPath:@"selectedObjects.path"]];
	[super remove:sender];
}

- (void)selectPreviousImage {
	
	if([self canSelectPrevious]) {
		[[[self undoManager] prepareWithInvocationTarget:self] selectNext:self];
		[self selectPrevious:self];
	}
}

- (void)selectNextImage {

	if([self canSelectNext]) {
		[[[self undoManager] prepareWithInvocationTarget:self] selectPrevious:self];
		[self selectNext:self];
	}
}

- (BOOL)multipleImagesSelected {
	return [[self selectedObjects] count] > 1;
}

- (BOOL)containsPath:(NSString *)path {
	NSArray *paths = [self valueForKeyPath:@"arrangedObjects.path"];
	return [paths containsObject:path];
}

- (BOOL)extensionIsAllowed:(NSString *)path {
	return [allowedExtensions containsObject:[[path pathExtension] lowercaseString]];
}

- (void)addFiles:(NSArray *)filePaths {
	//NSLog(@"-- addFiles: %@", filePaths);
	//importDone = NO;
	
	//CSSImageContainer *firstInsertedObject = nil;

	NSEnumerator *e = [filePaths objectEnumerator];
	NSString *path;
   // http://developer.apple.com/documentation/Cocoa/Conceptual/CocoaDrawingGuide/Images/chapter_7_section_3.html

	//NSMutableArray *containersToAdd = [[NSMutableArray alloc] init];
	
	while(( path = [e nextObject] )) {
		if([[NSFileManager defaultManager] isDirectory:path]) {
			NSArray *dirContent = [[NSFileManager defaultManager] directoryContentFullPaths:path recursive:YES];
			[self addFiles:dirContent];
			continue;
		}
		
		if([path hasPrefix:@"."] || ![self extensionIsAllowed:path]) {
			continue;
		}

		[self addObject:[CSSImageContainer containerWithPath:path]];
	}
	
	//NSLog(@"-- containersToAdd: %@", containersToAdd);
	//[self addObjects:containersToAdd];
	//[containersToAdd release];
	
	//importDone = YES;
}

- (void)addDirFiles:(NSString *)dir {
	//NSLog(@"-- addDirFiles: %@", dir);
	[self addFiles:[NSArray arrayWithObject:dir]];
	[[[self undoManager] prepareWithInvocationTarget:self] remove:self];
}

- (IBAction)moveToTrash:(id)sender {
	[[self selectedObjects] makeObjectsPerformSelector:@selector(moveToTrash)];
	[self removeObjectsAtArrangedObjectIndexes:[self selectionIndexes]];
}

- (void)bitmapWasLoadedInContainer:(CSSImageContainer *)c {
	if(![inMemoryBitmapsContainers containsObject:c]) {
		[inMemoryBitmapsContainers addObject:c];
	}
}
/*
- (void)forgetUnusedBitmaps {
	
	int i;
	int count = [inMemoryBitmapsContainers count];
	for(i = count-1; i > 1; i--) {
		CSSImageContainer *c = [inMemoryBitmapsContainers objectAtIndex:i];
		if(c->bitmap == nil) {
			//NSLog(@"-- skip %@", [c path]);
			continue;
		}
		[c forgetBitmap];
		[inMemoryBitmapsContainers removeObject:c];
	}
}
 */

/*
- (NSArray *)flagged {
	NSPredicate *p = [NSPredicate predicateWithFormat:@"flagged == YES"];
	NSMutableArray *ma = [[self arrangedObjects] mutableCopy];
	[ma filterUsingPredicate:p];
	return [ma autorelease];
}
*/

#pragma mark GPS

- (BOOL)atLeastOneImageWithGPSSelected {
	
	NSEnumerator *e = [[self selectedObjects] objectEnumerator];
	CSSImageContainer *container = nil;

	while((container = [e nextObject])) {
		if([[container valueForKeyPath:@"gps"] isKindOfClass:[NSDictionary class]]) {
			//NSLog(@"-- atLeastOneImageWithGPSSelected");
			return YES;
		}
	}

	return NO;
}


- (IBAction)openGoogleMap:(id)sender {
	if(![[self selectedObjects] count]) return;
	CSSImageContainer *i = [[self selectedObjects] lastObject];
	NSURL *url = [i googleMapsURL];
	if(!url) return;
	[[NSWorkspace sharedWorkspace] openURL:url];
}

@end


