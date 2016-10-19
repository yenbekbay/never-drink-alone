#import "UIImage+NDAHelpers.h"
#import "NDAMacros.h"

@implementation UIImage (NDAHelpers)

+ (instancetype)imageWithColor:(UIColor *)color {
  CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);

  UIGraphicsBeginImageContext(rect.size);
  CGContextRef context = UIGraphicsGetCurrentContext();

  CGContextSetFillColorWithColor(context, [color CGColor]);
  CGContextFillRect(context, rect);

  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return image;
}

- (instancetype)crop:(CGRect)rect {
  if (self.scale > 1.0f) {
    rect = CGRectMake(rect.origin.x * self.scale, rect.origin.y * self.scale, rect.size.width * self.scale, rect.size.height * self.scale);
  }

  CGImageRef imageRef = CGImageCreateWithImageInRect(self.CGImage, rect);
  UIImage *result = [UIImage imageWithCGImage:imageRef scale:self.scale orientation:self.imageOrientation];
  CGImageRelease(imageRef);
  return result;
}

- (instancetype)getRoundedRectImage {
  CGRect frame = CGRectMake(0, 0, self.size.width, self.size.height);

  UIGraphicsBeginImageContextWithOptions(self.size, NO, 1.0);
  [[UIBezierPath bezierPathWithRoundedRect:frame cornerRadius:self.size.height] addClip];
  [self drawInRect:frame];
  UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return finalImage;
}

+ (instancetype)convertViewToImage:(UIView *)view {
  CGFloat scale = [UIScreen mainScreen].scale;
  UIImage *capturedScreen;

  if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
    // Optimized/fast method for rendering a UIView as image on iOS 7 and later versions.
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, scale);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    capturedScreen = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
  } else {
    // For devices running on earlier iOS versions.
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, scale);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    capturedScreen = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
  }

  return capturedScreen;
}

@end
