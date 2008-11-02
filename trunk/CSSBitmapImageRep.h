#import <Cocoa/Cocoa.h>


@interface CSSBitmapImageRep:NSBitmapImageRep {
	NSString *path;
	NSString *userComment;
	NSArray *keywords;
	NSDictionary *gps;
	NSDictionary *properties;
}

- (NSImage *)image;

- (void)setPath:(NSString *)aPath;
- (NSDictionary *)exif;

- (void)setUserComment:(NSString *)comment;
- (NSString *)userComment;

- (void)setKeywords:(NSArray *)keywords;
- (NSArray *)keywords;

- (NSDictionary *)gps;

- (NSString *)prettyImageSize;

- (NSURL *)googleMapsURL;

@end
