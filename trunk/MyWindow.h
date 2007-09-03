/* MyWindow */

#import <Cocoa/Cocoa.h>
#import "ImagesController.h"

@interface MyWindow : NSWindow
{
	IBOutlet ImagesController *imagesController;
}

-(void) setDelegate: (id) del;

@end
