#import <Cocoa/Cocoa.h>


@interface CSSBitmapImageRep:NSBitmapImageRep {
	NSString *path;
	NSString *userComment;
}

- (void)setPath:(NSString *)aPath;
//- (void)setupExif;
- (NSDictionary *)exif;
- (void)setUserComment:(NSString *)comment;
- (NSString *)userComment;

- (NSString *)prettySize;
@end
