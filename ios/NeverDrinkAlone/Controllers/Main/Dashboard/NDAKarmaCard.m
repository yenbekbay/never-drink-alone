#import "NDAKarmaCard.h"

#import "NDAConstants.h"
#import "UIColor+NDATints.h"
#import "UIFont+NDASizes.h"
#import "UILabel+NDAHelpers.h"
#import "UIView+AYUtils.h"
#import <Parse/Parse.h>

static UIEdgeInsets const kKarmaCardPadding = {
  10, 15, 10, 15
};

@interface NDAKarmaCard ()

@property (nonatomic) UILabel *descriptionLabel;
@property (nonatomic) UILabel *valueLabel;
@property (nonatomic) NSNumber *karma;

@end

@implementation NDAKarmaCard

#pragma mark Initialization

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (!self) {
    return nil;
  }

  self.clipsToBounds = YES;
  self.layer.cornerRadius = kDashboardCardCornerRadius;
  self.backgroundColor = [UIColor nda_greenColor];
  self.userInteractionEnabled = NO;

  self.descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(kKarmaCardPadding.left, kKarmaCardPadding.top, self.width - kKarmaCardPadding.left - kKarmaCardPadding.right, (self.height - kKarmaCardPadding.top - kKarmaCardPadding.bottom) * 0.25f)];
  self.descriptionLabel.font = [UIFont fontWithName:kLightFontName size:[UIFont largeTextFontSize]];
  self.descriptionLabel.text = NSLocalizedString(@"Ваша карма", nil);
  self.descriptionLabel.hidden = YES;
  [self addSubview:self.descriptionLabel];

  self.valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(kKarmaCardPadding.left, self.descriptionLabel.bottom, self.width - kKarmaCardPadding.left - kKarmaCardPadding.right, (self.height - kKarmaCardPadding.top - kKarmaCardPadding.bottom) * 0.75f)];
  self.valueLabel.font = [UIFont fontWithName:kLightFontName size:[UIFont karmaFontSize]];
  [self addSubview:self.valueLabel];

  for (UILabel *label in @[self.descriptionLabel, self.valueLabel]) {
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
  }

  [[self updateKarma] subscribeError:^(NSError *error) {
    DDLogError(@"Error occured while updating karma: %@", error);
  }];

  return self;
}

#pragma mark Public

- (RACSignal *)updateKarma {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    [[PFUser currentUser] fetchInBackgroundWithBlock:^(PFObject *userObject, NSError *error) {
      if (error) {
        [subscriber sendError:error];
      } else {
        NSNumber *karma = userObject[kUserKarmaKey];
        if ([karma integerValue] == [self.karma integerValue]) {
          [subscriber sendCompleted];
        } else {
          self.karma = karma;
          [UIView transitionWithView:self duration:0.4f options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionFlipFromRight animations:^{
            self.backgroundColor = [karma integerValue] > 0 ? [UIColor nda_greenColor] : [UIColor nda_accentColor];
            self.valueLabel.text = [karma integerValue] > 0 ? [NSString stringWithFormat : @"+%@", karma] :[karma stringValue];
            self.descriptionLabel.hidden = NO;
          } completion:^(BOOL finished) {
            DDLogVerbose(@"Updated karma");
            [subscriber sendCompleted];
          }];
        }
      }
    }];
    return nil;
  }];
}

@end
