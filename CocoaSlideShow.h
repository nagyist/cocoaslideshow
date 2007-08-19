/* CocoaSlideShow */

#import <Cocoa/Cocoa.h>
#import "RemoteControl.h"

#import "MyImageView.h"

@interface CocoaSlideShow : NSObject
{
	IBOutlet NSWindow *mainWindow;
	IBOutlet NSPanel *slideShowPanel;

	NSImage *currentImage;
	NSMutableArray *images;

	IBOutlet NSArrayController *imagesController;
	IBOutlet MyImageView *imageView;
	IBOutlet NSImageView *panelImageView;

	RemoteControl* remoteControl;

	BOOL isFullScreen;
}

- (IBAction)setDirectory:(id)sender;
- (IBAction)addDirectory:(id)sender;
- (IBAction)fullScreenMode:(id)sener;
- (IBAction)exitFullScreen:(id)sender;
- (IBAction)toggleFullScreen:(id)sender;

- (IBAction)rotateLeft:(id)sender;
- (IBAction)rotateRight:(id)sender;

- (IBAction)moveToTrash:(id)sender;
- (IBAction)exportToDirectory:(id)sender;

@end
