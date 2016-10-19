#import "NDALoadingImageView.h"

@implementation NDALoadingImageView

#pragma mark Initialization

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (!self) {
    return nil;
  }

  _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  self.spinner.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
  [self addSubview:self.spinner];

  return self;
}

#pragma mark Setters

- (void)setSpinnerStyle:(UIActivityIndicatorViewStyle)style {
  self.spinner.activityIndicatorViewStyle = style;
}

#pragma mark Public

- (void)startSpinning {
  [self.spinner startAnimating];
}

- (void)stopSpinning {
  [self.spinner stopAnimating];
}

@end
