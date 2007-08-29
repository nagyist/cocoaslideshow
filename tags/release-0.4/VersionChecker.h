#import <Cocoa/Cocoa.h>


@interface VersionChecker : NSObject {

}

+ (VersionChecker *)sharedInstance;
- (IBAction) checkUpdate:(id)sender;
- (IBAction) checkUpdateAndShowPanel:(id)sender;

@end
