#import "NDAMeetingDetailsView.h"

#import "NDAConstants.h"
#import "NDAInterest.h"
#import "NDAMeetingManager.h"
#import "NDAMeetingPlaceView.h"
#import "NDAMeetingUserStatusView.h"
#import "NDATimeSlot.h"
#import "NSDate+NDAHelpers.h"
#import "UIColor+NDATints.h"
#import "UIFont+NDASizes.h"
#import "UILabel+NDAHelpers.h"
#import "UIView+AYUtils.h"
#import <Parse/Parse.h>

CGFloat const kMeetingDetailsViewSpacing = 10;

@interface NDAMeetingDetailsView () <UIScrollViewDelegate>

/**
 *  Label indicating the time of the meeting.
 */
@property (nonatomic) UILabel *summaryLabel;
/**
 *  View for the meeting place.
 */
@property (nonatomic) NDAMeetingPlaceView *meetingPlaceView;

@property (nonatomic) NDAMeetingUserStatusView *firstUserStatusView;
@property (nonatomic) NDAMeetingUserStatusView *secondUserStatusView;
/**
 *  Label with the mutual interests of two meeting users.
 */
@property (nonatomic) UILabel *interestsOverviewLabel;

@property (nonatomic, assign) CGFloat lastContentOffset;

@end

@implementation NDAMeetingDetailsView

#pragma mark Setters

- (void)setMeeting:(NDAMeeting *)meeting {
  _meeting = meeting;
  self.delegate = self;
  self.alwaysBounceVertical = YES;
  [self setUpSummaryLabel];
  [self setUpMeetingPlaceView];
  [self setUpUserStatusViews];
  [self setUpInterestsOverviewLabel];
}

#pragma mark Private

- (void)setUpSummaryLabel {
  self.summaryLabel = [[UILabel alloc] initWithFrame:CGRectMake(kMeetingViewPadding, kMeetingViewPadding + kMeetingCutoutSize.height, CGRectGetWidth([UIScreen mainScreen].bounds) - kMeetingViewPadding * 2, 0)];
  self.summaryLabel.font = [UIFont fontWithName:kRegularFontName size:[UIFont largeTextFontSize]];
  self.summaryLabel.textColor = [UIColor nda_textColor];
  self.summaryLabel.numberOfLines = 0;
  NSString *dayString = [self.meeting.timeSlot.date fullDate];
  self.summaryLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@, %@:00-%@:00", nil), dayString, self.meeting.timeSlot.startingHour, @([self.meeting.timeSlot.startingHour integerValue] + 1)];
  [self.summaryLabel setFrameToFitWithHeightLimit:0];

  [self addSubview:self.summaryLabel];
}

- (void)setUpMeetingPlaceView {
  self.meetingPlaceView = [[NDAMeetingPlaceView alloc] initWithFrame:CGRectMake(kMeetingViewPadding, self.summaryLabel.bottom + kMeetingDetailsViewSpacing, [self.meeting.meetingPlace sizeForCell].width, [self.meeting.meetingPlace sizeForCell].height)];
  self.meetingPlaceView.meetingPlace = self.meeting.meetingPlace;

  [self addSubview:self.meetingPlaceView];
}

- (void)setUpUserStatusViews {
  self.firstUserStatusView = [[NDAMeetingUserStatusView alloc] initWithFrame:CGRectMake(kMeetingViewPadding, self.meetingPlaceView.bottom + kMeetingDetailsViewSpacing, CGRectGetWidth([UIScreen mainScreen].bounds) - kMeetingViewPadding * 2, 30)];
  self.secondUserStatusView = [[NDAMeetingUserStatusView alloc] initWithFrame:CGRectOffset(self.firstUserStatusView.frame, 0, self.firstUserStatusView.height)];
  [self addSubview:self.firstUserStatusView];
  [self addSubview:self.secondUserStatusView];
  [self setUserStatuses];
}

- (void)setUpInterestsOverviewLabel {
  self.interestsOverviewLabel = [[UILabel alloc] initWithFrame:CGRectMake(kMeetingViewPadding, self.secondUserStatusView.bottom + kMeetingDetailsViewSpacing, CGRectGetWidth([UIScreen mainScreen].bounds) - kMeetingViewPadding * 2, 0)];
  self.interestsOverviewLabel.textColor = [UIColor nda_textColor];
  self.interestsOverviewLabel.numberOfLines = 0;
  [self addSubview:self.interestsOverviewLabel];

  [[[NDAMeetingManager sharedInstance] getCommonInterests] subscribeNext:^(NSArray *interests) {
    NSString *mutualInterestsString = [[interests componentsJoinedByString:@", "] lowercaseString];
    NSMutableAttributedString *interestsOverviewText = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"Вас обоих интересуют\n", nil) attributes:@{ NSFontAttributeName : [UIFont fontWithName:kLightFontName size:[UIFont mediumTextFontSize]] }];
    [interestsOverviewText appendAttributedString:[[NSMutableAttributedString alloc] initWithString:mutualInterestsString attributes:@{ NSFontAttributeName : [UIFont fontWithName:kRegularFontName size:[UIFont mediumTextFontSize]] }]];
    self.interestsOverviewLabel.attributedText = interestsOverviewText;
    [self.interestsOverviewLabel setFrameToFitWithHeightLimit:0];
    self.contentSize = CGSizeMake(self.width, self.interestsOverviewLabel.bottom + kMeetingViewPadding);
  } error:^(NSError *error) {
    DDLogError(@"Error occured while getting common interests: %@", error);
    self.interestsOverviewLabel.text = NSLocalizedString(@"Общих интересов не найдено.", nil);
    [self.interestsOverviewLabel setFrameToFitWithHeightLimit:0];
    self.contentSize = CGSizeMake(self.width, self.interestsOverviewLabel.bottom + kMeetingViewPadding);
  }];
}

#pragma mark Public

- (void)setUserStatuses {
  [[[NDAMeetingManager sharedInstance] getUserMeetings] subscribeNext:^(NSArray *userMeetings) {
    self.firstUserStatusView.userMeeting = userMeetings[0];
    self.secondUserStatusView.userMeeting = userMeetings[1];
  } error:^(NSError *error) {
    DDLogError(@"Error occured while getting user meetings: %@", error);
  }];
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
  if (fabs(self.lastContentOffset - scrollView.contentOffset.y) > 10) {
    if (self.lastContentOffset > scrollView.contentOffset.y) {
      [self.meetingDelegate expandUserInfoView];
    } else if (self.lastContentOffset < scrollView.contentOffset.y) {
      [self.meetingDelegate shrinkUserInfoView];
    }
  }
  self.lastContentOffset = scrollView.contentOffset.y;
}

@end
