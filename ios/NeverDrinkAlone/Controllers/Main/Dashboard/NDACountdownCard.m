#import "NDACountdownCard.h"

#import "NDACircularGauge.h"
#import "NDAConstants.h"
#import "NSDate+NDAHelpers.h"
#import "UIColor+NDATints.h"
#import "UIFont+NDASizes.h"
#import "UILabel+NDAHelpers.h"
#import "UIView+AYUtils.h"
#import <pop/POP.h>

static UIEdgeInsets const kCountdownCardPadding = {
  15, 30, 10, 30
};
static CGFloat const kCountdownGaugeBottomPadding = 10;
static NSString *const kPOPGaugeValue = @"gaugeValue";

@interface NDACountdownCard ()

@property (nonatomic) NDACircularGauge *gauge;
@property (nonatomic) NSDate *countdownDate;
@property (nonatomic) NSTimer *countdownTimer;
@property (nonatomic) UILabel *descriptionLabel;
@property (nonatomic) UILabel *timeLabel;

@end

@implementation NDACountdownCard

#pragma mark Initialization

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (!self) {
    return nil;
  }

  self.backgroundColor = [UIColor nda_primaryColor];
  self.clipsToBounds = YES;
  self.layer.cornerRadius = kDashboardCardCornerRadius;
  self.userInteractionEnabled = NO;

  self.descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(kCountdownCardPadding.left, 0, self.width - kCountdownCardPadding.left - kCountdownCardPadding.right, 0)];
  self.descriptionLabel.font = [UIFont fontWithName:kLightFontName size:[UIFont mediumTextFontSize]];
  self.descriptionLabel.textColor = [UIColor whiteColor];
  self.descriptionLabel.textAlignment = NSTextAlignmentCenter;
  self.descriptionLabel.numberOfLines = 0;
  self.descriptionLabel.text = NSLocalizedString(@"осталось до следующего приглашения на встречу", nil);
  [self.descriptionLabel setFrameToFitWithHeightLimit:0];
  self.descriptionLabel.top = self.height - self.descriptionLabel.height - kCountdownCardPadding.bottom;
  [self addSubview:self.descriptionLabel];

  self.gauge = [[NDACircularGauge alloc] initWithFrame:CGRectMake(kCountdownCardPadding.left, kCountdownCardPadding.top, self.width - kCountdownCardPadding.left - kCountdownCardPadding.right, self.descriptionLabel.top - kCountdownCardPadding.top - kCountdownGaugeBottomPadding)];
  self.gauge.strokeWidthRatio = 0.15f;
  self.gauge.color = [UIColor nda_accentColor];
  self.gauge.value = 0;
  [self addSubview:self.gauge];

  self.timeLabel = [[UILabel alloc] initWithFrame:self.gauge.frame];
  self.timeLabel.font = [UIFont fontWithName:kLightFontName size:[UIFont extraLargeTextFontSize]];
  self.timeLabel.textColor = [UIColor whiteColor];
  self.timeLabel.textAlignment = NSTextAlignmentCenter;
  self.timeLabel.alpha = 0;
  [self addSubview:self.timeLabel];

  return self;
}

#pragma mark Public

- (void)startCountdown {
  [self updateCountdown];
  [self fadeTimeLabel];
  self.countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateCountdown) userInfo:nil repeats:YES];
}

- (void)stopCountdown {
  if (self.countdownTimer) {
    [self.countdownTimer invalidate];
  }
  [self animateGaugeToValue:@0];
  [self fadeTimeLabel];
  self.timeLabel.text = @"--:--:--";
}

- (void)updateCountdown {
  if (!self.countdownDate || [self.countdownDate timeLeftToDate] <= 0) {
    self.countdownDate = [NSDate dateForHour:12];
  }
  [self animateGaugeToValue:@(1 - [self.countdownDate timeLeftToDate] / (60 * 60 * 24))];
  self.timeLabel.text = [self.countdownDate formattedTimeLeftToDate];
}

#pragma mark Private

- (void)fadeTimeLabel {
  if (self.timeLabel.alpha == 0) {
    POPBasicAnimation *fadeAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPViewAlpha];
    fadeAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    fadeAnimation.toValue = @(1);
    fadeAnimation.duration = 2;
    [self.timeLabel pop_addAnimation:fadeAnimation forKey:@"fadeAnimation"];
  }
}

- (void)animateGaugeToValue:(NSNumber *)value {
  if (self.gauge.value != [value doubleValue]) {
    POPAnimatableProperty *gaugeAnimationProperty = [POPAnimatableProperty propertyWithName:kPOPGaugeValue initializer:^(POPMutableAnimatableProperty *prop) {
      prop.readBlock = ^(id obj, CGFloat values[]) {
        values[0] = [(NDACircularGauge *)obj value];
      };
      prop.writeBlock = ^(id obj, const CGFloat values[]) {
        [(NDACircularGauge *)obj setValue:values[0]];
      };
      prop.threshold = 0.01f;
    }];
    POPSpringAnimation *gaugeAnimation = [POPSpringAnimation animation];
    gaugeAnimation.property = gaugeAnimationProperty;
    gaugeAnimation.toValue = value;
    gaugeAnimation.springBounciness = 10;
    [self.gauge pop_addAnimation:gaugeAnimation forKey:@"gaugeValueAnimation"];
  }
}

@end
