/* MyImageView */

#import <Cocoa/Cocoa.h>

@interface MyImageView : NSImageView
{
    IBOutlet id delegate;
	BOOL isDragAndDrop;
}

-(void) setDelegate: (id) del;

@end
