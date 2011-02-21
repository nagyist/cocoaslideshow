/* CocoaSlideShow */

#import <Cocoa/Cocoa.h>

#import "RemoteControl.h"

#import "MyImageView.h"
#import "ImagesController.h"

#import "CSSMapController.h"

@class CSSBorderlessWindow;
@class BatchController;

@interface CocoaSlideShow : NSObject
{	
	IBOutlet NSWindow *mainWindow;
	IBOutlet CSSBorderlessWindow *slideShowPanel;
	
	IBOutlet CSSMapController *mapController;
	NSMutableArray *images;
	
	IBOutlet ImagesController *imagesController;
	IBOutlet MyImageView *imageView;
	IBOutlet NSImageView *panelImageView;
	IBOutlet NSTextField *userCommentTextField;
	IBOutlet NSTableView *tableView;
	IBOutlet NSTokenField *keywordsTokenField;
	
	IBOutlet NSTabView *tabView;
	IBOutlet NSTabViewItem *imageTabViewItem;
	IBOutlet NSTabViewItem *mapTabViewItem;
	
	IBOutlet NSView *kmlSavePanelAccessoryView;
	IBOutlet NSView *thumbnailsExportAccessoryView;
	IBOutlet NSApplication *application;
    IBOutlet BatchController *batchController;
	
	NSToolbar *toolbar;
	
	RemoteControl *remoteControl;
	NSUndoManager *undoManager;
	NSTimer *timer;
    
	BOOL isFullScreen;
	BOOL takeFilesFromDefault;
	BOOL isSaving;
	BOOL isExporting;
}

- (BOOL)isFullScreen;

- (ImagesController *)imagesController;

- (BOOL)isMap;

- (IBAction)undo:(id)sender;
- (IBAction)redo:(id)sender;

- (IBAction)setDirectory:(id)sender;
- (IBAction)addDirectory:(id)sender;
- (IBAction)fullScreenMode:(id)sener;
- (IBAction)exitFullScreen:(id)sender;
- (IBAction)toggleFullScreen:(id)sender;
- (IBAction)rotateLeft:(id)sender;
- (IBAction)rotateRight:(id)sender;
- (IBAction)revealInFinder:(id)sender;
- (IBAction)exportToDirectory:(id)sender;
- (IBAction)open:(id)sender;
- (IBAction)save:(id)sender;

- (IBAction)startSlideShow:(id)sender;
- (IBAction)toggleSlideShow:(id)sender;

- (IBAction)toggleGoogleMap:(id)sender;

- (IBAction)exportKMLToFile:(id)sender;
- (IBAction)resizeJPEGs:(id)sender;

- (void)invalidateTimer;
- (NSUndoManager *)undoManager;

@end
