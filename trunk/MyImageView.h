/* MyImageView */

#import <Cocoa/Cocoa.h>

@interface MyImageView : NSImageView
{
    IBOutlet id delegate;
	BOOL isDraggingFromSelf;
}

@end
