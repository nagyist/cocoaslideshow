/* CocoaSlideShow */

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

#import "RemoteControl.h"

#import "MyImageView.h"
#import "ImagesController.h"

//#import "FlagImageTransformer.h"
#import "ImageResizer.h"

@interface CocoaSlideShow : NSObject
{
	IBOutlet NSWindow *mainWindow;
	IBOutlet NSPanel *slideShowPanel;
	NSWindow *fullScreenWindow;

	NSMutableArray *images;
	ImageResizer *ir;
	
	IBOutlet ImagesController *imagesController;
	IBOutlet MyImageView *imageView;
	IBOutlet NSImageView *panelImageView;
	IBOutlet NSTextField *userCommentTextField;
	IBOutlet NSTableView *tableView;
	IBOutlet NSTokenField *keywordsTokenField;
	
	IBOutlet WebView *webView;
	
	NSToolbar *toolbar;
	
	RemoteControl *remoteControl;
	NSUndoManager *undoManager;
	NSTimer *timer;

	BOOL isFullScreen;
	BOOL takeFilesFromDefault;
	
	BOOL isSaving;
}

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

- (IBAction)startSlideShow:(id)sender;
- (IBAction)toggleSlideShow:(id)sender;

@end
