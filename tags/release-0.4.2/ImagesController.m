#import "ImagesController.h"
#import "CSSImageContainer.h"
#import "NSFileManager+CSS.h"

@implementation ImagesController

- (void)awakeFromNib {
	inMemoryBitmapsContainers = [[NSMutableArray alloc] initWithCapacity:IN_MEMORY_BITMAPS];
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

- (void)addFiles:(NSArray *)filePaths {

	importDone = NO;
	
	CSSImageContainer *firstInsertedObject = nil;

	NSEnumerator *e = [filePaths objectEnumerator];
	NSString *path;
	NSArray *allowedExtensions = [NSArray arrayWithObjects:@"jpg", @"jpeg", @"tif", @"tiff", @"psd", @"gif", @"png", @"bmp", nil];
	NSArray *dirContent;
	while(( path = [e nextObject] )) {
		NSString *ext = [path pathExtension];
		
		dirContent = [[NSFileManager defaultManager] directoryContentFullPaths:path recursive:YES];
		if(dirContent) {
			[self addFiles:dirContent];
		}
		
		if([path hasPrefix:@"."] || ![allowedExtensions containsObject:[ext lowercaseString]]) {
			continue;
		}
		
		if(![self containsPath:path]) {
			CSSImageContainer *container = [[CSSImageContainer alloc] init];
			[container setValue:path forKey:@"path"];
			
			if(firstInsertedObject == nil) {
				firstInsertedObject = container;
			}
			[self addObject:[container autorelease]];
		}
	}
	
	importDone = YES;

	if(firstInsertedObject != nil) {
		[self setSelectedObjects:[NSArray arrayWithObject:firstInsertedObject]];
	}
}

- (void)addDirFiles:(NSString *)dir {
	[self addFiles:[NSArray arrayWithObject:dir]];
	[[[self undoManager] prepareWithInvocationTarget:self] remove:self];
}

- (IBAction)moveToTrash:(id)sender {
	[[self selectedObjects] makeObjectsPerformSelector:@selector(moveToTrash)];
	[self removeObjectsAtArrangedObjectIndexes:[self selectionIndexes]];
}

- (void) retainOnlyAFewImagesAndReleaseTheRest {
	if([[self selectedObjects] count] != 1) {
		return;
	}
	
	CSSImageContainer *c = [[self selectedObjects] lastObject];
	
	if(![inMemoryBitmapsContainers containsObject:c]) {
		if([inMemoryBitmapsContainers count] == IN_MEMORY_BITMAPS) {
			CSSImageContainer *oldContainer = [inMemoryBitmapsContainers objectAtIndex:0];
			[oldContainer forgetBitmap];
			[inMemoryBitmapsContainers removeObject:oldContainer];
		}
		[inMemoryBitmapsContainers addObject:c];
	}
}

@end
