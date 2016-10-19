#import <UIKit/UIKit.h>

@interface UIImage (NDAHelpers)

+ (instancetype)imageWithColor:(UIColor *)color;
- (instancetype)crop:(CGRect)rect;
- (instancetype)getRoundedRectImage;
+ (instancetype)convertViewToImage:(UIView *)view;

@end
