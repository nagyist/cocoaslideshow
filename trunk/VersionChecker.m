#import "VersionChecker.h"

// TODO move this string in info.plist
static NSString *VERSION_CHECK_URL_STRING = @"http://cocoaslideshow.googlecode.com/svn/trunk/VersionCheck.plist";
//static NSString *VERSION_CHECK_URL_STRING = @"http://127.0.0.1/~nst/SSVersionCheck.plist";

static VersionChecker *sharedInstance = nil;

@implementation VersionChecker

+ (VersionChecker *)sharedInstance {
    if (sharedInstance == nil) {
        sharedInstance = [[VersionChecker alloc] init];
    }
    return sharedInstance;
}

- (BOOL) version:(NSArray *)a isBiggerThan:(NSArray *)b {
    unsigned aa = [[a objectAtIndex:0] intValue];
    unsigned ab = [[a objectAtIndex:1] intValue];
    unsigned cc = [a count] > 2 ? [[a objectAtIndex:2] intValue] : 0;

    unsigned ba = [[b objectAtIndex:0] intValue];
    unsigned bb = [[b objectAtIndex:1] intValue];
    unsigned bc = [b count] > 2 ? [[b objectAtIndex:2] intValue] : 0;

    return ((aa > ba) || (aa == ba && ab > bb) || (aa == ba && ab == bb && cc > bc));
}

- (void) checkUpdateWithDisplayingAlertIfUpToDate:(NSNumber *)displayPanelInAnyCase {
    NSAutoreleasePool *subPool = [[NSAutoreleasePool alloc] init];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // set defaults, redundant with addDefaults.plist
    if([[defaults dictionaryRepresentation] valueForKey:@"versionCheckRunAtStartup"] == nil) {
        [defaults setBool:YES forKey:@"versionCheckRunAtStartup"];
    }

    if([defaults boolForKey:@"versionCheckRunAtStartup"] == NO) {
        [subPool release];
        return;
    }

    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *currentVersionString = [infoDictionary valueForKey:@"CFBundleShortVersionString"];
    NSArray *currentVersion = [currentVersionString componentsSeparatedByString:@"."];

    NSURL *versionCheckURL = [NSURL URLWithString:VERSION_CHECK_URL_STRING];
    NSDictionary *d = [NSDictionary dictionaryWithContentsOfURL:versionCheckURL];
    if(d == nil ||
      [d valueForKey:@"LatestVersion"] == nil ||
      [d valueForKey:@"PageURL"] == nil ||
      [d valueForKey:@"DownloadURL"] == nil) {
        [subPool release];
        return;
    }

    NSString *latestVersionString = [d valueForKey:@"LatestVersion"];
    NSArray *latestVersion = [latestVersionString componentsSeparatedByString:@"."];
    NSURL *pageURL = [NSURL URLWithString:[d valueForKey:@"PageURL"]];
    NSURL *downloadURL = [NSURL URLWithString:[d valueForKey:@"DownloadURL"]];
    /*
    NSLog(@"currentVersion %@", currentVersion);
    NSLog(@"latestVersion %@", latestVersion);
    */
    if([self version:latestVersion isBiggerThan:currentVersion] == NO) {
        if([displayPanelInAnyCase boolValue]) {
            NSRunInformationalAlertPanel(NSLocalizedString(@"You are up to date!", nil),
                                         [NSString stringWithFormat:NSLocalizedString(@"CocoaSlideShow %@ is the latest version available.", nil), latestVersionString],
                                         NSLocalizedString(@"OK", nil),
                                         @"",
                                         @"");
        }
        [subPool release];
        return;
    }
    
    int alertReturn = NSRunAlertPanel([NSString stringWithFormat: NSLocalizedString(@"CocoaSlideShow version %@ is available", nil), latestVersionString],
                                      [NSString stringWithFormat: NSLocalizedString(@"What do you want to do?", nil), latestVersionString],
                                      NSLocalizedString(@"Download now", nil),
                                      NSLocalizedString(@"Ignore and Continue", nil),
                                      NSLocalizedString(@"Open CocoaSlideShow website", nil));
                                      
    switch (alertReturn) {
        case NSAlertDefaultReturn:
            // download
            [[NSWorkspace sharedWorkspace] openURL:downloadURL];
            break;
        case NSAlertOtherReturn:
            // open web site
            [[NSWorkspace sharedWorkspace] openURL:pageURL];
            break;
        default:
            break;
    }
    
    [subPool release];
}

- (IBAction) checkUpdate:(id)sender {
    [NSThread detachNewThreadSelector:@selector(checkUpdateWithDisplayingAlertIfUpToDate:)
                             toTarget:self
                           withObject:[NSNumber numberWithBool:NO]];
}

- (IBAction) checkUpdateAndShowPanel:(id)sender {
    [NSThread detachNewThreadSelector:@selector(checkUpdateWithDisplayingAlertIfUpToDate:)
                             toTarget:self
                           withObject:[NSNumber numberWithBool:YES]];
}

@end
