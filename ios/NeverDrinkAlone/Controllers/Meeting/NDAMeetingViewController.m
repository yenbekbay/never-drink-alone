#import "NDAMeetingViewController.h"

#import "CRGradientNavigationBar.h"
#import "NDAAlertManager.h"
#import "NDAChatViewController.h"
#import "NDAConstants.h"
#import "NDAMeetingDetailsView.h"
#import "NDAMeetingManager.h"
#import "NDAMeetingUserInfoView.h"
#import "NSDate+NDAHelpers.h"
#import "PFUser+NDAHelpers.h"
#import "UIColor+NDAHelpers.h"
#import "UIColor+NDATints.h"
#import "UIFont+NDASizes.h"
#import "UIImage+NDAHelpers.h"
#import "UIView+AYUtils.h"
#import <Analytics/Analytics.h>
#import <JTSImageViewController/JTSImageViewController.h>
#import <Parse/Parse.h>

@interface NDAMeetingViewController ()

@property (nonatomic) NDAAlertManager *alertManager;
@property (nonatomic) NDAMeeting *meeting;
@property (nonatomic) NDAMeetingDetailsView *meetingDetailsView;
@property (nonatomic) NDAMeetingUserInfoView *userInfoView;
@property (nonatomic) NSDate *decisionDeadline;
@property (nonatomic) NSTimer *deadlineTimer;
@property (nonatomic) UIButton *noButton;
@property (nonatomic) UIButton *yesButton;
@property (nonatomic) UILabel *countdownLabel;
@property (nonatomic) UIView *meetingDetailsViewWrapper;
@property (nonatomic, getter = isUserInfoExpanded) BOOL userInfoExpanded;
@property (nonatomic) BOOL accepted;

@end

@implementation NDAMeetingViewController

#pragma mark Initialization

- (instancetype)initWithMeeting:(NDAMeeting *)meeting {
  self = [super init];
  if (!self) {
    return nil;
  }

  self.meeting = meeting;

  return self;
}

#pragma mark Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor whiteColor];
  self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
  self.alertManager = [NDAAlertManager new];
  self.userInfoExpanded = YES;
  [self switchUserInteraction];
  [self setUpViews];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.navigationController.navigationBar.translucent = YES;
  [(CRGradientNavigationBar *)self.navigationController.navigationBar setBarTintGradientColors:@[
     [UIColor clearColor],
     [UIColor clearColor]
   ]];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUserStatuses) name:kReloadMeetingNotification object:nil];
  if (self.meetingDetailsView) {
    [self updateUserStatuses];
  }
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self.meetingDetailsView flashScrollIndicators];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  self.navigationController.navigationBar.translucent = NO;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Private

- (void)setUpViews {
  self.userInfoView = [[NDAMeetingUserInfoView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, kMeetingUserInfoViewHeight + kMeetingCutoutSize.height)];
  self.userInfoView.meetingDelegate = self;
  PFUser *meetingUser = [self.meeting.match.firstUser.objectId isEqualToString:[PFUser currentUser].objectId] ? self.meeting.match.secondUser : self.meeting.match.firstUser;
  PFQuery *query = [PFUser query];
  [query includeKey:kUserPictureKey];
  [query getObjectInBackgroundWithId:meetingUser.objectId block:^(PFObject *object, NSError *error) {
    if (!error) {
      [self switchUserInteraction];
      self.userInfoView.user = (PFUser *)object;
    } else {
      DDLogError(@"Error occured while getting meeting user: %@", error);
    }
  }];

  self.meetingDetailsViewWrapper = [[UIView alloc] initWithFrame:CGRectMake(0, self.userInfoView.height - kMeetingCutoutSize.height, self.view.width, self.view.height - self.userInfoView.bottom + kMeetingCutoutSize.height - kBigButtonHeight - kSmallButtonHeight)];
  self.meetingDetailsViewWrapper.backgroundColor = [UIColor whiteColor];
  self.meetingDetailsView = [[NDAMeetingDetailsView alloc] initWithFrame:self.meetingDetailsViewWrapper.bounds];
  self.meetingDetailsView.meeting = self.meeting;
  self.meetingDetailsView.meetingDelegate = self;
  [self setUpCutoutMask];
  [self.meetingDetailsViewWrapper addSubview:self.meetingDetailsView];

  self.countdownLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.height - kBigButtonHeight - kSmallButtonHeight, self.view.width, kSmallButtonHeight)];
  self.countdownLabel.font = [UIFont fontWithName:kRegularFontName size:[UIFont smallTextFontSize]];
  self.countdownLabel.textColor = [UIColor nda_darkGrayColor];
  self.countdownLabel.textAlignment = NSTextAlignmentCenter;
  self.countdownLabel.backgroundColor = [UIColor nda_lightGrayColor];

  self.yesButton = [[UIButton alloc] initWithFrame:CGRectMake(0, self.countdownLabel.bottom, self.view.width * 0.7f, kBigButtonHeight)];
  [self.yesButton setTitle:NSLocalizedString(@"Да, я приду", nil) forState:UIControlStateNormal];
  self.yesButton.titleLabel.font = [UIFont fontWithName:kLightFontName size:[UIFont bigButtonFontSize]];
  [self.yesButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  self.yesButton.tintColor = [UIColor whiteColor];
  [self.yesButton setBackgroundImage:[UIImage imageWithColor:[UIColor nda_greenColor]] forState:UIControlStateNormal];
  [self.yesButton setBackgroundImage:[UIImage imageWithColor:[[UIColor nda_greenColor] darkerColor:0.1f]] forState:UIControlStateHighlighted];
  self.yesButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^(id _) {
    [self updateDecisionWithAccepted:YES animated:YES saving:YES];
    return [RACSignal empty];
  }];

  self.noButton = [[UIButton alloc] initWithFrame:CGRectMake(self.yesButton.right, self.yesButton.top, self.view.width * 0.3f, kBigButtonHeight)];
  [self.noButton setTitle:NSLocalizedString(@"Нет", nil) forState:UIControlStateNormal];
  self.noButton.titleLabel.font = [UIFont fontWithName:kLightFontName size:[UIFont mediumButtonFontSize]];
  self.noButton.tintColor = [UIColor whiteColor];
  [self.noButton setBackgroundImage:[UIImage imageWithColor:[UIColor nda_accentColor]] forState:UIControlStateNormal];
  [self.noButton setBackgroundImage:[UIImage imageWithColor:[[UIColor nda_accentColor] darkerColor:0.1f]] forState:UIControlStateHighlighted];
  self.noButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^(id _) {
    [self updateDecisionWithAccepted:NO animated:YES saving:YES];
    return [RACSignal empty];
  }];

  [self.view addSubview:self.userInfoView];
  [self.view addSubview:self.meetingDetailsViewWrapper];
  [self.view addSubview:self.yesButton];
  [[[NDAMeetingManager sharedInstance] getUserMeeting] subscribeNext:^(PFObject *userMeeting) {
    BOOL hasAccepted = [userMeeting[kUserHasAcceptedKey] boolValue];
    BOOL hasRejected = [userMeeting[kUserHasRejectedKey] boolValue];
    if (hasAccepted || hasRejected) {
      [self updateDecisionWithAccepted:hasAccepted animated:NO saving:NO];
    } else {
      [PFUser currentUser][kUserHasUndecidedMeetingKey] = @YES;
      [[PFUser currentUser] saveEventually];
      [self enableNavigationBar:NO];
      [self.view addSubview:self.countdownLabel];
      [self.view addSubview:self.noButton];
      self.decisionDeadline = [NSDate dateForHour:18];
      self.deadlineTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateCountdown) userInfo:nil repeats:YES];
    }
  } error:^(NSError *error) {
    DDLogError(@"Error occured while getting user meeting: %@", error);
  }];
}

- (void)setUpCutoutMask {
  UIBezierPath *path = [UIBezierPath new];

  [path moveToPoint:CGPointMake(0, kMeetingCutoutSize.height)];
  [path addLineToPoint:CGPointMake((self.view.width - kMeetingCutoutSize.width) / 2, kMeetingCutoutSize.height)];
  [path addLineToPoint:CGPointMake(self.view.width / 2, 0)];
  [path addLineToPoint:CGPointMake((self.view.width + kMeetingCutoutSize.width) / 2, kMeetingCutoutSize.height)];
  [path addLineToPoint:CGPointMake(self.view.width, kMeetingCutoutSize.height)];
  [path addLineToPoint:CGPointMake(self.view.width, self.meetingDetailsView.height)];
  [path addLineToPoint:CGPointMake(0, self.meetingDetailsView.height)];
  [path addLineToPoint:CGPointMake(0, kMeetingCutoutSize.height)];

  CAShapeLayer *mask = [CAShapeLayer new];
  mask.frame = self.meetingDetailsViewWrapper.bounds;
  mask.path = path.CGPath;
  self.meetingDetailsViewWrapper.layer.mask = mask;
}

- (void)updateDecisionWithAccepted:(BOOL)accepted animated:(BOOL)animated saving:(BOOL)saving {
  if (animated) {
    [UIView animateWithDuration:0.4f animations:^{
      [self decisionMade];
    } completion:^(BOOL finished) {
      [self updateCutoutMask];
      if (accepted) {
        [self userAccepted:animated saving:saving];
      } else {
        [self userRejected:animated saving:saving];
      }
    }];
  } else {
    [self decisionMade];
    [self updateCutoutMask];
    if (accepted) {
      [self userAccepted:animated saving:saving];
    } else {
      [self userRejected:animated saving:saving];
    }
  }
}

- (void)userAccepted:(BOOL)animated saving:(BOOL)saving {
  [[[NDAMeetingManager sharedInstance] getUserMeetings] subscribeNext:^(NSArray *userMeetings) {
    PFObject *otherUserMeeting = [[userMeetings[0][kUserKey] objectId] isEqualToString:[PFUser currentUser].objectId] ? userMeetings[1] : userMeetings[0];
    BOOL otherUserAccepted = [otherUserMeeting[kUserHasAcceptedKey] boolValue];
    BOOL otherUserRejected = [otherUserMeeting[kUserHasRejectedKey] boolValue];
    NSString *newYesButtonTitle;
    if (otherUserAccepted) {
      newYesButtonTitle = NSLocalizedString(@"Перейти к чату", nil);
    } else if (otherUserRejected) {
      newYesButtonTitle = [NSString stringWithFormat:@"%@ %@", otherUserMeeting[kUserKey][kUserFirstNameKey], ([otherUserMeeting[kUserKey][kUserGenderKey] integerValue] == 0 ? NSLocalizedString(@"отказался", nil) : NSLocalizedString(@"отказалась", nil))];
    } else {
      newYesButtonTitle = NSLocalizedString(@"Ожидается ответ", nil);
    }
    if (saving) {
      [self saveUserDecision:YES];
    }
    if ([self.yesButton.titleLabel.text isEqualToString:newYesButtonTitle]) {
      return;
    }
    if (animated) {
      [UIView transitionWithView:self.yesButton duration:0.4f options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionFlipFromRight animations:^{
        [self.yesButton setTitle:newYesButtonTitle forState:UIControlStateNormal];
        self.accepted = YES;
      } completion:nil];
    } else {
      [self.yesButton setTitle:newYesButtonTitle forState:UIControlStateNormal];
      self.accepted = YES;
    }
    self.yesButton.userInteractionEnabled = otherUserAccepted;
    self.yesButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^(id _) {
      NDAChatViewController *chatViewController = [[NDAChatViewController alloc] initWithMatch:self.meeting.match];
      [self.navigationController pushViewController:chatViewController animated:YES];
      return [RACSignal empty];
    }];
  } error:^(NSError *error) {
    DDLogError(@"Error occured while getting user meetings: %@", error);
    [self.alertManager showNotificationWithText:NSLocalizedString(@"Что-то пошло не так. Попробуйте еще раз", nil)];
  }];
}

- (void)userRejected:(BOOL)animated saving:(BOOL)saving {
  if (saving) {
    [self saveUserDecision:NO];
  }
  if (animated) {
    [UIView transitionWithView:self.yesButton duration:0.4f options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionFlipFromRight animations:^{
      [self.yesButton setTitle:NSLocalizedString(@"Вы отказались", nil) forState:UIControlStateNormal];
      [self.yesButton setBackgroundImage:[UIImage imageWithColor:[UIColor nda_accentColor]] forState:UIControlStateNormal];
    } completion:nil];
  } else {
    [self.yesButton setTitle:NSLocalizedString(@"Вы отказались", nil) forState:UIControlStateNormal];
    [self.yesButton setBackgroundImage:[UIImage imageWithColor:[UIColor nda_accentColor]] forState:UIControlStateNormal];
  }
  self.yesButton.userInteractionEnabled = NO;
  self.yesButton.rac_command = nil;
}

- (void)updateCountdown {
  if ([self.decisionDeadline timeLeftToDate] < 60 * 60) {
    self.countdownLabel.textColor = [UIColor nda_accentColor];
    if ([self.decisionDeadline timeLeftToDate] <= 0) {
      [self deadlineMet];
    }
  }
  self.countdownLabel.text = [NSString stringWithFormat:@"%@, чтобы принять решение", [self.decisionDeadline formattedTimeLeftToDate]];
}

- (void)deadlineMet {
  [self enableNavigationBar:YES];
  [PFUser currentUser][kUserHasUndecidedMeetingKey] = @NO;
  [[PFUser currentUser] saveEventually];
  [[NDAMeetingManager sharedInstance] resetMeeting];
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)saveUserDecision:(BOOL)accepted {
  [self enableNavigationBar:YES];
  [PFUser currentUser][kUserHasUndecidedMeetingKey] = @NO;
  [[PFUser currentUser] saveEventually];

  [[[NDAMeetingManager sharedInstance] getUserMeeting] subscribeNext:^(PFObject *userMeeting) {
    if (accepted) {
      [[[PFUser currentUser] karmaTransactionWithAmount:@1 description:@"Accepted a meeting"] subscribeError:^(NSError *error) {
        DDLogError(@"Error occured while performing a karma transaction: %@", error);
      }];
      userMeeting[kUserHasAcceptedKey] = @YES;
      [self.alertManager showNotificationWithText:NSLocalizedString(@"Отлично, +1 к карме! Ждите подтверждения встречи", nil) color:[UIColor nda_greenColor]];
      [[SEGAnalytics sharedAnalytics] track:@"Accepted a meeting" properties:nil options:@{
         @"meetingId" : self.meeting.objectId
       }];
    } else {
      [[[PFUser currentUser] karmaTransactionWithAmount:@(-2) description:@"Rejected a meeting"] subscribeError:^(NSError *error) {
        DDLogError(@"Error occured while performing a karma transaction: %@", error);
      }];
      userMeeting[kUserHasRejectedKey] = @YES;
      [self.alertManager showNotificationWithText:NSLocalizedString(@"Очень жаль. -2 от кармы", nil) color:[UIColor nda_accentColor]];
      [[SEGAnalytics sharedAnalytics] track:@"Rejected a meeting" properties:nil options:@{
         @"meetingId" : self.meeting.objectId
       }];
    }
    [userMeeting saveInBackgroundWithBlock:^(BOOL succeeded, NSError *savingError) {
      if (!savingError) {
        [[[NDAMeetingManager sharedInstance] updateMeetingStatus] subscribeError:^(NSError *error) {
          DDLogError(@"Error occured while updating meeting status: %@", error);
        } completed:^{
          DDLogVerbose(@"Updated meeting status");
        }];
        [[[NDAMeetingManager sharedInstance] notifySecondUser] subscribeError:^(NSError *error) {
          DDLogError(@"Error occured while notifying second user: %@", error);
        } completed:^{
          DDLogVerbose(@"Notified second user");
        }];
        if (!accepted) {
          [[NDAMeetingManager sharedInstance] resetMeeting];
        }
      }
    }];
    [self updateUserStatuses];
  } error:^(NSError *error) {
    DDLogError(@"Error occured while getting user meeting");
  }];
}

- (void)updateUserStatuses {
  [self.meetingDetailsView setUserStatuses];
  if (self.accepted) {
    [self userAccepted:YES saving:NO];
  }
}

- (void)decisionMade {
  self.countdownLabel.left = self.view.width;
  self.yesButton.width = self.view.width;
  self.noButton.left = self.yesButton.right;
  [self.deadlineTimer invalidate];
}

- (void)updateCutoutMask {
  self.meetingDetailsViewWrapper.frame = CGRectMake(0, self.userInfoView.bottom - kMeetingCutoutSize.height, self.meetingDetailsView.width, self.view.height - self.userInfoView.height + kMeetingCutoutSize.height - kBigButtonHeight);
  self.meetingDetailsView.frame = CGRectMake(0, 0, self.view.width, self.meetingDetailsViewWrapper.height);
  [self setUpCutoutMask];
}

- (void)enableNavigationBar:(BOOL)enabled {
  self.navigationController.navigationBar.hidden = !enabled;
  self.navigationController.interactivePopGestureRecognizer.enabled = enabled;
}

- (void)switchUserInteraction {
  self.view.userInteractionEnabled = !self.view.userInteractionEnabled;
}

#pragma mark NDAMeetingViewControllerDelegate

- (void)displayImageForImageView:(UIImageView *)imageView {
  JTSImageInfo *imageInfo = [JTSImageInfo new];

  imageInfo.image = imageView.image;
  imageInfo.referenceRect = imageView.frame;
  imageInfo.referenceView = imageView.superview;
  JTSImageViewController *imageViewer = [[JTSImageViewController alloc] initWithImageInfo:imageInfo mode:JTSImageViewControllerMode_Image backgroundStyle:JTSImageViewControllerBackgroundOption_None];
  [imageViewer showFromViewController:self transition:JTSImageViewControllerTransition_FromOriginalPosition];
}

- (void)shrinkUserInfoView {
  if (self.isUserInfoExpanded) {
    [self.userInfoView shrink];
    self.userInfoExpanded = NO;
  }
}

- (void)expandUserInfoView {
  if (!self.userInfoExpanded) {
    [self.userInfoView expand];
    self.userInfoExpanded = YES;
  }
}

- (void)userInfoViewChangedHeight:(CGFloat)heightDiff {
  self.meetingDetailsViewWrapper.top += heightDiff;
  self.meetingDetailsViewWrapper.height -= heightDiff;
  self.meetingDetailsView.frame = self.meetingDetailsViewWrapper.bounds;
  [self setUpCutoutMask];
}

@end
