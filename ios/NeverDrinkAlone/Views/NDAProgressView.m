//
//  Copyright (c) 2014 kishikawa katsumi, 2015 Ayan Yenbekbay.
//

#import "NDAProgressView.h"

#import "UIView+AYUtils.h"

@interface NDAProgressView ()

@property (nonatomic) CALayer *backgroundLayer;
@property (nonatomic) CAShapeLayer *progressLayer;

@end

@implementation NDAProgressView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (!self) {
    return nil;
  }

  self.backgroundColor = [UIColor clearColor];
  self.lineWidth = 3.0f;
  self.tintColor = [UIColor whiteColor];
  self.radius = 20.0f;
  [self.backgroundLayer addSublayer:self.progressLayer];
  self.backgroundView = [self defaultBackgroundView];
  self.indeterminate = YES;
  self.spinnerHeight = self.height;

  return self;
}

#pragma mark Lifecycle

- (void)layoutSubviews {
  [super layoutSubviews];
  self.backgroundLayer.frame = self.bounds;
  self.backgroundLayer.anchorPoint = CGPointMake(0.5f, (self.spinnerHeight / self.height) / 2);

  UIBezierPath *path = [UIBezierPath bezierPath];
  path.lineCapStyle = kCGLineCapButt;
  path.lineWidth = self.lineWidth;

  CGPoint center = CGPointMake(self.width / 2, self.spinnerHeight / 2);
  [path addArcWithCenter:center radius:self.radius + self.lineWidth / 2 startAngle:(CGFloat) - M_PI_2 endAngle:(CGFloat)(M_PI + M_PI_2) clockwise:YES];

  self.progressLayer.path = path.CGPath;
}

#pragma mark Getters & setters

- (UIView *)defaultBackgroundView {
  UIView *backgroundView = [UIView new];

  backgroundView.backgroundColor = [UIColor blackColor];

  return backgroundView;
}

- (CALayer *)backgroundLayer {
  if (!_backgroundLayer) {
    _backgroundLayer = [CALayer layer];
    _backgroundLayer.backgroundColor = [UIColor clearColor].CGColor;
  }
  return _backgroundLayer;
}

- (CAShapeLayer *)progressLayer {
  if (!_progressLayer) {
    _progressLayer = [CAShapeLayer layer];
    _progressLayer.fillColor = [UIColor clearColor].CGColor;
    _progressLayer.strokeColor = self.tintColor.CGColor;
    _progressLayer.lineWidth = self.lineWidth;
    _progressLayer.strokeStart = 0;
    _progressLayer.strokeEnd = 0;
  }
  return _progressLayer;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
  _backgroundView.backgroundColor = backgroundColor;
}

- (void)setBackgroundView:(UIView *)backgroundView {
  if (_backgroundView.superview) {
    [_backgroundView removeFromSuperview];
  }

  backgroundView.frame = self.bounds;
  backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

  [self.backgroundLayer removeFromSuperlayer];
  [backgroundView.layer addSublayer:self.backgroundLayer];

  [self addSubview:backgroundView];

  _backgroundView = backgroundView;
}

- (CGFloat)lineWidth {
  return self.progressLayer.lineWidth;
}

- (void)setLineWidth:(CGFloat)lineWidth {
  self.progressLayer.lineWidth = lineWidth;
}

- (UIColor *)tintColor {
  return [UIColor colorWithCGColor:self.progressLayer.strokeColor];
}

- (void)setTintColor:(UIColor *)tintColor {
  _progressLayer.strokeColor = tintColor.CGColor;
}

- (void)setSpinnerHeight:(CGFloat)spinnerHeight {
  _spinnerHeight = spinnerHeight;

  self.backgroundLayer.frame = self.bounds;
  self.backgroundLayer.anchorPoint = CGPointMake(0.5f, (_spinnerHeight / self.height) / 2);
}

- (void)setIndeterminate:(BOOL)indeterminate {
  if (_indeterminate == indeterminate) {
    return;
  }
  _indeterminate = indeterminate;

  self.backgroundView.hidden = NO;

  if (indeterminate) {
    _progressLayer.strokeStart = 0.1f;
    _progressLayer.strokeEnd = 1.0f;

    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    animation.toValue = @(M_PI);
    animation.duration = 0.5f;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animation.repeatCount = MAXFLOAT;
    animation.cumulative = YES;

    [self.backgroundLayer addAnimation:animation forKey:nil];
  } else {
    _progressLayer.actions = @{
      @"strokeStart" : [NSNull null], @"strokeEnd" : [NSNull null]
    };
    _progressLayer.strokeStart = 0;
    _progressLayer.strokeEnd = 0;

    [self.backgroundLayer removeAllAnimations];
  }
}

- (void)setProgress:(CGFloat)progress {
  [self setProgress:progress animated:YES];
}

#pragma mark Private

- (void)setProgress:(CGFloat)progress animated:(BOOL)animated {
  if (self.isIndeterminate) {
    self.indeterminate = NO;
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate date]];
  }

  if (_progress >= 1 && progress >= 1) {
    _progress = 1;
    return;
  }

  if (progress < 0) {
    progress = 0;
  }
  if (progress > 1) {
    progress = 1;
  }
  if (progress > 0) {
    self.backgroundView.hidden = NO;
  }

  self.progressLayer.actions = animated ? nil : @{
    @"strokeEnd" : [NSNull null]
  };
  self.progressLayer.strokeEnd = progress;

  if (progress >= 1) {
    [self performFinishAnimation];
  }

  _progress = progress;
}

#pragma mark Public

- (void)performFinishAnimation {
  CAShapeLayer *maskLayer = [CAShapeLayer layer];

  maskLayer.backgroundColor = [UIColor blackColor].CGColor;

  CGPoint center = CGPointMake(self.width / 2, _spinnerHeight / 2);

  UIBezierPath *initialPath = [UIBezierPath bezierPathWithRect:self.backgroundView.bounds];
  [initialPath moveToPoint:center];
  [initialPath addArcWithCenter:center radius:self.radius startAngle:0 endAngle:(CGFloat)(2 * M_PI) clockwise:YES];
  [initialPath addArcWithCenter:center radius:self.radius + self.lineWidth startAngle:0 endAngle:(CGFloat)(2 * M_PI) clockwise:YES];
  initialPath.usesEvenOddFillRule = YES;

  maskLayer.path = initialPath.CGPath;
  maskLayer.fillRule = kCAFillRuleEvenOdd;

  self.backgroundView.layer.mask = maskLayer;

  CGFloat outerRadius;
  CGFloat width = CGRectGetWidth(self.bounds) / 2;
  CGFloat height = CGRectGetHeight(self.bounds) / 2;
  if (width < height) {
    outerRadius = height * 1.5f;
  } else {
    outerRadius = width * 1.5f;
  }

  UIBezierPath *finalPath = [UIBezierPath bezierPathWithRect:self.backgroundView.bounds];
  [finalPath moveToPoint:center];
  [finalPath addArcWithCenter:center radius:0 startAngle:0 endAngle:(CGFloat)(2 * M_PI) clockwise:YES];
  [finalPath addArcWithCenter:center radius:outerRadius startAngle:0 endAngle:(CGFloat)(2 * M_PI) clockwise:YES];
  finalPath.usesEvenOddFillRule = YES;

  CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"path"];
  animation.delegate = self;
  animation.toValue = (id)finalPath.CGPath;
  animation.duration = 0.4f;
  animation.beginTime = CACurrentMediaTime() + 0.4f;
  animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
  animation.fillMode  = kCAFillModeForwards;
  animation.removedOnCompletion = NO;

  [maskLayer addAnimation:animation forKey:@"path"];
}

#pragma mark CAAnimation

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
  self.backgroundView.layer.mask = nil;
  self.backgroundView.hidden = YES;
  [self removeFromSuperview];
}

@end
