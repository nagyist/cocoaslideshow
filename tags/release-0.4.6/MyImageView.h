/* MyImageView */

#import <Cocoa/Cocoa.h>

@interface MyImageView : NSImageView
{
    id delegate;
}

-(void) setDelegate: (id) del;

@end
