/* MyWindow */

#import <Cocoa/Cocoa.h>

@interface MyWindow : NSWindow
{
    id delegate;
}

-(void) setDelegate: (id) del;

@end
