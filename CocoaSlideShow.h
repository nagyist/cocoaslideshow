/* CocoaSlideShow */

#import <Cocoa/Cocoa.h>
#import "RemoteControl.h"

#import "MyImageView.h"

@interface CocoaSlideShow : NSObject
{
	IBOutlet NSWindow *mainWindow;
	IBOutlet NSPanel *slideShowPanel;

	NSMutableArray *images;
	NSMutableArray *inMemoryBitmapsContainers;

	IBOutlet NSArrayController *imagesController;
	IBOutlet MyImageView *imageView;
	IBOutlet NSImageView *panelImageView;
	IBOutlet NSTextField *userCommentTextField;
	IBOutlet NSTableView *tableView;
	IBOutlet NSTokenField *keywordsTokenField;

	unsigned inMemoryBitmapsNextIndex;

	RemoteControl* remoteControl;

	BOOL isFullScreen;
	BOOL takeFilesFromDefault;
	
	BOOL importDone;
	BOOL isSaving;
}

- (IBAction)setDirectory:(id)sender;
- (IBAction)addDirectory:(id)sender;
- (IBAction)fullScreenMode:(id)sener;
- (IBAction)exitFullScreen:(id)sender;
- (IBAction)toggleFullScreen:(id)sender;
- (IBAction)rotateLeft:(id)sender;
- (IBAction)rotateRight:(id)sender;
- (IBAction)revealInFinder:(id)sender;
- (IBAction)moveToTrash:(id)sender;
- (IBAction)exportToDirectory:(id)sender;
- (IBAction)open:(id)sender;

- (BOOL)multipleImagesSelected;

@end
