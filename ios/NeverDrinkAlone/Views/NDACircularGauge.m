#import "NDACircularGauge.h"

@implementation NDACircularGauge

#pragma mark Initialization

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (!self) {
    return nil;
  }

  self.backgroundColor = [UIColor clearColor];
  self.color = [UIColor grayColor];
  self.strokeWidthRatio = 0.15f;

  return self;
}

#pragma mark Setters

- (void)setValue:(CGFloat)value {
  _value = MAX(MIN(value, 1), 0);
  [self setNeedsDisplay];
}

- (void)setStrokeWidth:(CGFloat)strokeWidth {
  _strokeWidthRatio = -1;
  _strokeWidth = strokeWidth;
}

- (void)setStrokeWidthRatio:(CGFloat)strokeWidthRatio {
  _strokeWidth = -1;
  _strokeWidthRatio = strokeWidthRatio;
}

- (void)setColor:(UIColor *)color {
  _color = color;
  [self setNeedsDisplay];
}

#pragma mark Drawing

- (void)drawRect:(CGRect)rect {
  CGContextRef ctx = UIGraphicsGetCurrentContext();

  CGPoint center = CGPointMake(CGRectGetWidth(rect) / 2, CGRectGetHeight(rect) / 2);
  CGFloat minSize = MIN(CGRectGetWidth(rect), CGRectGetHeight(rect));
  CGFloat lineWidth = _strokeWidth;

  if (lineWidth == -1) {
    lineWidth = minSize * _strokeWidthRatio;
  }
  CGFloat radius = (minSize - lineWidth) / 2;
  CGFloat endAngle = (CGFloat)(M_PI * (self.value * 2));

  CGContextSaveGState(ctx);
  CGContextTranslateCTM(ctx, center.x, center.y);
  CGContextRotateCTM(ctx, (CGFloat)(-M_PI * 0.5f));

  CGContextSetLineWidth(ctx, lineWidth);
  CGContextSetLineCap(ctx, kCGLineCapRound);

  // "Full" Background Circle
  CGContextBeginPath(ctx);
  CGContextAddArc(ctx, 0, 0, radius, 0, (CGFloat)(2 * M_PI), 0);
  CGContextSetStrokeColorWithColor(ctx, [_color colorWithAlphaComponent:0.1f].CGColor);
  CGContextStrokePath(ctx);

  // Progress Arc
  CGContextBeginPath(ctx);
  CGContextAddArc(ctx, 0, 0, radius, 0, endAngle, 0);
  CGContextSetStrokeColorWithColor(ctx, [_color colorWithAlphaComponent:0.9f].CGColor);
  CGContextStrokePath(ctx);

  CGContextRestoreGState(ctx);
}

@end
