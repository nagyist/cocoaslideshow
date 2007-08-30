/* ImagesController */

#import <Cocoa/Cocoa.h>

#define IN_MEMORY_BITMAPS 5

@class CocoaSlideShow;

@interface ImagesController : NSArrayController
{
	IBOutlet CocoaSlideShow *cocoaSlideShow;
	BOOL importDone;
	unsigned inMemoryBitmapsNextIndex;
	NSMutableArray *inMemoryBitmapsContainers;
}

- (NSUndoManager *)undoManager;
- (NSIndexSet *)flaggedIndexes;
- (void)flagIndexes:(NSIndexSet *)indexSet;
- (IBAction)flag:(id)sender;
- (IBAction)unflag:(id)sender;
- (IBAction)toggleFlags:(id)sender;
- (IBAction)selectFlags:(id)sender;
- (IBAction)removeAllFlags:(id)sender;
- (IBAction)remove:(id)sender;
- (IBAction)moveToTrash:(id)sender;
- (BOOL)containsPath:(NSString *)path;
- (BOOL)multipleImagesSelected;
- (void)selectPreviousImage;
- (void)selectNextImage;
- (void)addFiles:(NSArray *)filePaths;
- (void)addDirFiles:(NSString *)dir;
- (void) retainOnlyAFewImagesAndReleaseTheRest;

@end
