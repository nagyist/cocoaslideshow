/* MyImageView */

#import <Cocoa/Cocoa.h>

@interface MyImageView : NSImageView
{
    IBOutlet id delegate;
	BOOL isDraggingFromSelf;
}

-(void) setDelegate: (id) del;

@end
