#import "NDAMeetingUserStatusView.h"

#import "NDAConstants.h"
#import "UIColor+NDATints.h"
#import "UIFont+NDASizes.h"
#import "UIImage+NDAHelpers.h"
#import "UIView+AYUtils.h"

static UIEdgeInsets const kMeetingUserStatusViewPadding = {
  5, 0, 5, 10
};
static CGFloat const kMeetingUserStatusViewIconSpacing = 5;

@interface NDAMeetingUserStatusView ()

@property (nonatomic) UIImageView *iconView;
@property (nonatomic) UILabel *nameLabel;

@end

@implementation NDAMeetingUserStatusView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (!self) {
    return nil;
  }

  self.iconView = [[UIImageView alloc] initWithFrame:CGRectMake(kMeetingUserStatusViewPadding.left, kMeetingUserStatusViewPadding.top, self.height - kMeetingUserStatusViewPadding.top - kMeetingUserStatusViewPadding.bottom, self.height - kMeetingUserStatusViewPadding.top - kMeetingUserStatusViewPadding.bottom)];
  self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.iconView.right + kMeetingUserStatusViewIconSpacing, self.iconView.top, (self.width - self.iconView.right - kMeetingUserStatusViewIconSpacing - kMeetingUserStatusViewPadding.right), self.iconView.height)];
  self.nameLabel.font = [UIFont fontWithName:kRegularFontName size:[UIFont mediumTextFontSize]];
  self.nameLabel.textColor = [UIColor nda_textColor];

  [self addSubview:self.iconView];
  [self addSubview:self.nameLabel];

  return self;
}

#pragma mark Setters

- (void)setUserMeeting:(PFObject *)userMeeting {
  _userMeeting = userMeeting;
  NSString *name = [NSString stringWithFormat:@"%@ %@", userMeeting[kUserKey][kUserFirstNameKey], userMeeting[kUserKey][kUserLastNameKey]];
  self.nameLabel.text = name;

  BOOL hasAccepted = [userMeeting[kUserHasAcceptedKey] boolValue];
  BOOL hasRejected = [userMeeting[kUserHasRejectedKey] boolValue];
  if (hasAccepted) {
    self.iconView.image = [[UIImage imageNamed:@"StatusAcceptedIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.iconView.tintColor = [UIColor nda_greenColor];
  } else if (hasRejected) {
    self.iconView.image = [[UIImage imageNamed:@"StatusRejectedIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.iconView.tintColor = [UIColor nda_accentColor];
  } else {
    self.nameLabel.text = [self.nameLabel.text stringByAppendingString:NSLocalizedString(@" (ожидается)", nil)];
    self.iconView.image = [[UIImage imageNamed:@"StatusUndecidedIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.iconView.tintColor = [UIColor nda_textColor];
  }
}

@end
