#import "UIColor+NDAHelpers.h"

@implementation UIColor (NDAHelpers)

- (instancetype)lighterColor:(CGFloat)increment {
  CGFloat r, g, b, a;
  if ([self getRed:&r green:&g blue:&b alpha:&a]) {
    return [UIColor colorWithRed:(CGFloat)MIN(r + increment, 1)
            green:(CGFloat)MIN(g + increment, 1)
            blue:(CGFloat)MIN(b + increment, 1)
            alpha:a];
  }
  return nil;
}

- (instancetype)darkerColor:(CGFloat)decrement {
  CGFloat r, g, b, a;
  if ([self getRed:&r green:&g blue:&b alpha:&a]) {
    return [UIColor colorWithRed:(CGFloat)MAX(r - decrement, 0)
            green:(CGFloat)MAX(g - decrement, 0)
            blue:(CGFloat)MAX(b - decrement, 0)
            alpha:a];
  }
  return nil;
}

@end
