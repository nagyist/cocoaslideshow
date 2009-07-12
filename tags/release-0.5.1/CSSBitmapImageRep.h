#import <Cocoa/Cocoa.h>


@interface CSSBitmapImageRep:NSBitmapImageRep {
	NSString *path;
	NSURL *url;
	CGImageSourceRef source;
	NSMutableDictionary *metadata;
}

- (NSImage *)image;

- (void)setPath:(NSString *)aPath;
- (NSDictionary *)exif;
- (NSDictionary *)gps;

- (void)setUserComment:(NSString *)comment;
- (NSString *)userComment;

- (void)setKeywords:(NSArray *)keywords;
- (NSArray *)keywords;

- (NSString *)prettyImageSize;

- (NSURL *)googleMapsURL;
//- (NSString *)gmapMarkerWithIndex:(int)i;

@end
