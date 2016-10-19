#import "NDAMeetingCard.h"

#import "NDAConstants.h"
#import "NSDate+NDAHelpers.h"
#import "UIColor+NDAHelpers.h"
#import "UIColor+NDATints.h"
#import "UIFont+NDASizes.h"
#import "UIImage+NDAHelpers.h"
#import "UILabel+NDAHelpers.h"
#import "UIView+AYUtils.h"
#import <pop/POP.h>

static UIEdgeInsets const kMeetingCardPadding = {
  15, 15, 15, 15
};
static CGFloat const kMeetingSummaryLabelPadding = 10;

@interface NDAMeetingCard ()

@property (nonatomic) UILabel *dayLabel;
@property (nonatomic) UILabel *weekdayLabel;
@property (nonatomic) UILabel *summaryLabel;
@property (nonatomic) UIImageView *disclosureIconView;
@property (nonatomic) UILabel *placeholderLabel;

@end

@implementation NDAMeetingCard

#pragma mark Initialization

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (!self) {
    return nil;
  }

  self.backgroundColor = [UIColor nda_accentColor];
  self.clipsToBounds = YES;
  self.layer.cornerRadius = kDashboardCardCornerRadius;
  self.hidden = YES;
  [self setBackgroundImage:[UIImage imageWithColor:[UIColor nda_accentColor]] forState:UIControlStateNormal];
  [self setBackgroundImage:[UIImage imageWithColor:[[UIColor nda_accentColor] darkerColor:0.1f]] forState:UIControlStateHighlighted];

  [self addTarget:self action:@selector(scaleToSmall) forControlEvents:UIControlEventTouchDown | UIControlEventTouchDragEnter];
  [self addTarget:self action:@selector(scaleAnimation) forControlEvents:UIControlEventTouchUpInside];
  [self addTarget:self action:@selector(scaleToDefault) forControlEvents:UIControlEventTouchDragExit];

  self.dayLabel = [UILabel new];
  self.dayLabel.font = [UIFont fontWithName:kLightFontName size:[UIFont extraLargeTextFontSize]];
  [self addSubview:self.dayLabel];

  self.weekdayLabel = [UILabel new];
  self.weekdayLabel.font = [UIFont fontWithName:kLightFontName size:[UIFont largeTextFontSize]];
  [self addSubview:self.weekdayLabel];

  self.summaryLabel = [UILabel new];
  self.summaryLabel.font = [UIFont fontWithName:kLightFontName size:[UIFont mediumTextFontSize]];
  self.summaryLabel.numberOfLines = 0;
  [self addSubview:self.summaryLabel];

  for (UILabel *label in @[self.dayLabel, self.weekdayLabel, self.summaryLabel]) {
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
  }

  self.disclosureIconView = [[UIImageView alloc] initWithFrame:CGRectMake(self.width - kMeetingCardPadding.right - kMeetingPlaceViewDisclosureIconSize.width, (self.height - kMeetingPlaceViewDisclosureIconSize.height) / 2, kMeetingPlaceViewDisclosureIconSize.width, kMeetingPlaceViewDisclosureIconSize.height)];
  self.disclosureIconView.tintColor = [UIColor whiteColor];
  self.disclosureIconView.image = [[UIImage imageNamed:@"DisclosureIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  [self addSubview:self.disclosureIconView];

  self.placeholderLabel = [[UILabel alloc] initWithFrame:self.bounds];
  self.placeholderLabel.font = [UIFont fontWithName:kLightFontName size:[UIFont mediumTextFontSize]];
  self.placeholderLabel.textColor = [UIColor whiteColor];
  self.placeholderLabel.numberOfLines = 0;
  self.placeholderLabel.textAlignment = NSTextAlignmentCenter;
  self.placeholderLabel.text = NSLocalizedString(@"Пожалуйста, подождите, пока Судьба отправит вам новое приглашение на встречу.", nil);
  [self addSubview:self.placeholderLabel];

  self.meeting = nil;

  return self;
}

- (void)setMeeting:(NDAMeeting *)meeting {
  _meeting = meeting;
  self.userInteractionEnabled = !!meeting;
  self.placeholderLabel.hidden = !!meeting;
  for (UIView *view in @[self.dayLabel, self.weekdayLabel, self.summaryLabel, self.disclosureIconView]) {
    view.hidden = !meeting;
  }
  if (meeting) {
    self.dayLabel.text = [meeting.timeSlot.date dayString];
    self.weekdayLabel.text = [meeting.timeSlot.date weekdayString];

    CGSize dayLabelSize = [self.dayLabel.text sizeWithAttributes:@{ NSFontAttributeName : self.dayLabel.font }];
    CGSize weekdayLabelSize = [self.weekdayLabel.text sizeWithAttributes:@{ NSFontAttributeName : self.weekdayLabel.font }];
    CGFloat maxLabelWidth = MAX(dayLabelSize.width, weekdayLabelSize.width);

    self.dayLabel.frame = CGRectMake(kMeetingCardPadding.left, 0, maxLabelWidth, dayLabelSize.height);
    self.weekdayLabel.frame = CGRectMake(kMeetingCardPadding.left, self.dayLabel.bottom, maxLabelWidth, weekdayLabelSize.height);
    CGFloat diff = (self.height - self.weekdayLabel.bottom) / 2;
    for (UILabel *label in @[self.dayLabel, self.weekdayLabel]) {
      label.top += diff;
    }
    self.summaryLabel.frame = CGRectMake(self.dayLabel.right + kMeetingSummaryLabelPadding, 0, self.disclosureIconView.left - kMeetingSummaryLabelPadding * 2 - self.dayLabel.right, 0);

    NSMutableAttributedString *summaryText = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"Встреча в ", nil) attributes:@{ NSFontAttributeName : [UIFont fontWithName:kLightFontName size:[UIFont largeTextFontSize]] }];
    [summaryText appendAttributedString:[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"%@:00", nil), meeting.timeSlot.startingHour] attributes:@{ NSFontAttributeName : [UIFont fontWithName:kRegularFontName size:[UIFont largeTextFontSize]] }]];
    [summaryText appendAttributedString:[[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@" в ", nil) attributes:@{ NSFontAttributeName : [UIFont fontWithName:kLightFontName size:[UIFont largeTextFontSize]] }]];
    [summaryText appendAttributedString:[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"\n%@.", nil), meeting.meetingPlace.name] attributes:@{ NSFontAttributeName : [UIFont fontWithName:kRegularFontName size:[UIFont largeTextFontSize]] }]];
    self.summaryLabel.attributedText = summaryText;
    [self.summaryLabel setFrameToFitWithHeightLimit:0];
    self.summaryLabel.centerY = self.height / 2;
  }
}

#pragma mark Public

- (RACSignal *)show {
  self.hidden = NO;
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    POPSpringAnimation *rotationAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerRotationX];
    rotationAnimation.springBounciness = 18;
    rotationAnimation.dynamicsMass = 2;
    rotationAnimation.dynamicsTension = 200;
    rotationAnimation.fromValue = @(M_PI_2);
    rotationAnimation.toValue = @(0);
    [self.layer pop_addAnimation:rotationAnimation forKey:@"rotationAnimation"];
    rotationAnimation.completionBlock = ^(POPAnimation *animation, BOOL finished) {
      [subscriber sendCompleted];
    };
    return nil;
  }];
}

- (RACSignal *)hide {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    POPSpringAnimation *rotationAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerRotationX];
    rotationAnimation.springBounciness = 18;
    rotationAnimation.dynamicsMass = 2;
    rotationAnimation.dynamicsTension = 200;
    rotationAnimation.fromValue = @(0);
    rotationAnimation.toValue = @(-M_PI_2);
    [self.layer pop_addAnimation:rotationAnimation forKey:@"rotationAnimation"];
    rotationAnimation.completionBlock = ^(POPAnimation *animation, BOOL finished) {
      self.hidden = YES;
      self.layer.transform = CATransform3DIdentity;
      [subscriber sendCompleted];
    };
    return nil;
  }];
}

#pragma mark Animations

- (void)scaleToSmall {
  POPBasicAnimation *scaleAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
  scaleAnimation.toValue = [NSValue valueWithCGSize:CGSizeMake(0.95f, 0.95f)];
  [self.layer pop_addAnimation:scaleAnimation forKey:@"layerScaleSmallAnimation"];
}

- (void)scaleAnimation {
  POPSpringAnimation *scaleAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
  scaleAnimation.velocity = [NSValue valueWithCGSize:CGSizeMake(3, 3)];
  scaleAnimation.toValue = [NSValue valueWithCGSize:CGSizeMake(1, 1)];
  scaleAnimation.springBounciness = 18;
  [self.layer pop_addAnimation:scaleAnimation forKey:@"layerScaleSpringAnimation"];
}

- (void)scaleToDefault {
  POPBasicAnimation *scaleAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
  scaleAnimation.toValue = [NSValue valueWithCGSize:CGSizeMake(1, 1)];
  [self.layer pop_addAnimation:scaleAnimation forKey:@"layerScaleDefaultAnimation"];
}

@end
