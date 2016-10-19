#import "NDADashboardViewController.h"

#import "JTProgressHUD.h"
#import "NDAAlertManager.h"
#import "NDAChatsViewController.h"
#import "NDACircularGauge.h"
#import "NDACountdownCard.h"
#import "NDAKarmaCard.h"
#import "NDAMeeting.h"
#import "NDAMeetingCard.h"
#import "NDAMeetingGoalPopup.h"
#import "NDAMeetingManager.h"
#import "NDAMeetingViewController.h"
#import "NSDate+NDAHelpers.h"
#import "PFUser+NDAHelpers.h"
#import "UIColor+NDATints.h"
#import "UIFont+NDASizes.h"
#import "UIImage+NDAHelpers.h"
#import "UIView+AYUtils.h"
#import <Analytics/Analytics.h>
#import <BBBadgeBarButtonItem/BBBadgeBarButtonItem.h>
#import <Firebase/Firebase.h>
#import <FSOpenInInstagram/FSOpenInInstagram.h>
#import <Parse/Parse.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

static CGFloat const kMeetingCardHeight = 100;
static CGFloat const kKarmaCardHeight = 150;
static CGFloat const kCountdownCardHeight = 300;
static CGFloat const kDashboardCardSpacing = 15;
static CGFloat const kDashboardViewPadding = 15;
static CGSize const kSelfieViewSize = {
  1000, 1000
};

@interface NDADashboardViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIDocumentInteractionControllerDelegate>

@property (nonatomic) AMPopTip *popTip;
@property (nonatomic) BBBadgeBarButtonItem *chatsButtonItem;
@property (nonatomic) Firebase *firebase;
@property (nonatomic) FSOpenInInstagram *instagrammer;
@property (nonatomic) NDAAlertManager *alertManager;
@property (nonatomic) NDACountdownCard *countdownCard;
@property (nonatomic) NDAKarmaCard *karmaCard;
@property (nonatomic) NDAMeeting *currentMeeting;
@property (nonatomic) NDAMeetingCard *meetingCard;
@property (nonatomic) NDAMeetingViewController *currentMeetingViewController;
@property (nonatomic) UIRefreshControl *refreshControl;
@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UIView *tipsView;
@property (nonatomic, getter = isRefreshing) BOOL refreshing;

@end

@implementation NDADashboardViewController

#pragma mark Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];

  self.alertManager = [[NDAAlertManager alloc] initWithRootViewController:self];
  self.instagrammer = [FSOpenInInstagram new];

  [self setUpScrollView];
  [self setUpCards];
  [self fixScrollView];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.delegate.navigationItem.title = @"Never Drink Alone";

  UIButton *settingsButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
  [settingsButton setImage:[[UIImage imageNamed:@"CogIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
  settingsButton.tintColor = [UIColor whiteColor];
  settingsButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^(id _) {
    [self.delegate switchView];
    return [RACSignal empty];
  }];
  UIBarButtonItem *settingsButtonItem = [[UIBarButtonItem alloc] initWithCustomView:settingsButton];
  [self.delegate.navigationItem setLeftBarButtonItem:settingsButtonItem];

  UIButton *chatsButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
  [chatsButton setImage:[[UIImage imageNamed:@"BubblesIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
  chatsButton.tintColor = [UIColor whiteColor];
  chatsButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^(id _) {
    NDAChatsViewController *chatsViewController = [NDAChatsViewController new];
    [self.navigationController pushViewController:chatsViewController animated:YES];
    return [RACSignal empty];
  }];
  self.chatsButtonItem = [[BBBadgeBarButtonItem alloc] initWithCustomUIButton:chatsButton];
  self.chatsButtonItem.badgeBGColor = [UIColor nda_accentColor];
  self.chatsButtonItem.badgeFont = [UIFont fontWithName:kRegularFontName size:11];
  self.chatsButtonItem.shouldHideBadgeAtZero = YES;
  [self.delegate.navigationItem setRightBarButtonItem:self.chatsButtonItem];
  if (!self.firebase) {
    [self updateChatsCounter];
  }

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadMeeting) name:kReloadMeetingNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshMeeting) name:kRefreshNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  PFUser *user = [PFUser currentUser];
  if (!user[kInterestedInKey]) {
    NDAMeetingGoalPopup *meetingGoalPopup = [NDAMeetingGoalPopup new];
    [[meetingGoalPopup getMeetingGoal] subscribeNext:^(NSNumber *meetingGoal) {
      DDLogVerbose(@"Got meeting goal for user");
      user[kInterestedInKey] = meetingGoal;
      [user saveEventually];
      [self refreshMeeting];
    }];
  } else {
    [self refreshMeeting];
  }
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Loading

- (void)refreshMeeting {
  [[self refreshMeeting:NO] subscribeCompleted:^{
    DDLogVerbose(@"Refreshed meeting");
  }];
}

- (void)reloadMeeting {
  [[self refreshMeeting:YES] subscribeCompleted:^{
    DDLogVerbose(@"Reloaded meeting");
  }];
}

- (RACSignal *)refreshMeeting:(BOOL)force {
  if (self.isRefreshing) {
    return [RACSignal empty];
  }
  self.refreshing = YES;
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    [[self.karmaCard updateKarma] subscribeCompleted:^{
      [[self displayAlert] subscribeError:^(NSError *error) {
        DDLogError(@"Error occured while displaying alert: %@", error);
      } completed:^{
        if (!force) {
          [self reloadMeeting];
        }
      }];
    }];
    if (self.currentMeeting) {
      if (force) {
        [[self resetMeeting] subscribeCompleted:^{
          self.refreshing = NO;
          DDLogVerbose(@"Reset meeting");
          [subscriber sendCompleted];
        }];
      } else {
        [[[NDAMeetingManager sharedInstance] getUserMeeting] subscribeNext:^(PFObject *userMeeting) {
          BOOL hasAccepted = [userMeeting[kUserHasAcceptedKey] boolValue];
          BOOL hasRejected = [userMeeting[kUserHasRejectedKey] boolValue];
          if (hasRejected) {
            [[self resetMeeting] subscribeCompleted:^{
              self.refreshing = NO;
              DDLogVerbose(@"Reset meeting");
              [subscriber sendCompleted];
            }];
          } else if (hasAccepted) {
            [self clearView];
            self.refreshing = NO;
            [self.countdownCard stopCountdown];
            [subscriber sendCompleted];
          }
        } error:^(NSError *error) {
          [self clearView];
          self.refreshing = NO;
          DDLogError(@"Error occured while refreshing meeting: %@", error);
          [subscriber sendError:error];
        }];
      }
    } else {
      [[self loadMeeting] subscribe:subscriber];
    }
    return nil;
  }];
}

- (void)updateChatsCounter {
  self.firebase = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@/Recent", kFirebaseUrl]];
  FQuery *query = [[self.firebase queryOrderedByChild:@"userId"] queryEqualToValue:[PFUser currentUser].objectId];
  [query observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
    if (snapshot.value != [NSNull null]) {
      NSInteger unread = 0;
      for (NSDictionary *recent in [snapshot.value allValues]) {
        unread += [recent[@"counter"] integerValue];
      }
      self.chatsButtonItem.badgeValue = [@(unread)stringValue];
      [UIApplication sharedApplication].applicationIconBadgeNumber = [PFInstallation currentInstallation].badge + unread;
      PFInstallation *currentInstallation = [PFInstallation currentInstallation];
      currentInstallation.badge = unread;
      [currentInstallation saveInBackground];
    }
  }];
}

- (RACSignal *)displayAlert {
  return [[self.alertManager displayAlert] then:^RACSignal *{
    return [self.karmaCard updateKarma];
  }];
}

- (RACSignal *)resetMeeting {
  self.currentMeeting = nil;
  self.currentMeetingViewController = nil;
  [[NDAMeetingManager sharedInstance] resetMeeting];
  return [[self hideMeetingCard] then:^RACSignal *{
    return [self loadMeeting];
  }];
}

- (RACSignal *)loadMeeting {
  if (![self.refreshControl isRefreshing]) {
    [JTProgressHUD showWithTransition:JTProgressHUDTransitionFade];
  }
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    [[[NDAMeetingManager sharedInstance] getMeeting] subscribeNext:^(NDAMeeting *meeting) {
      self.currentMeeting = meeting;
      [self clearView];
      self.refreshing = NO;
      if (!meeting) {
        DDLogVerbose(@"No meeting found");
        [self.countdownCard startCountdown];
      } else {
        DDLogVerbose(@"Got current meeting: %@", meeting);
        BOOL hasAccepted = [[NDAMeetingManager sharedInstance].userMeeting[kUserHasAcceptedKey] boolValue];
        BOOL hasRejected = [[NDAMeetingManager sharedInstance].userMeeting[kUserHasRejectedKey] boolValue];
        if (hasAccepted) {
          [self.countdownCard stopCountdown];
        } else {
          [self.countdownCard startCountdown];
        }
        if (!hasRejected) {
          self.meetingCard.meeting = meeting;
          if ([[PFUser currentUser][kUserHasUndecidedMeetingKey] boolValue]) {
            self.currentMeetingViewController = [[NDAMeetingViewController alloc] initWithMeeting:meeting];
            [self.navigationController pushViewController:self.currentMeetingViewController animated:YES];
          }
        }
      }
      [[self showMeetingCard] subscribeCompleted:^{
        DDLogVerbose(@"Showed meeting card");
        [self showPoptipsIfNeeded];
      }];
    } error:^(NSError *error) {
      [self clearView];
      self.refreshing = NO;
      DDLogError(@"Error occured while getting meeting: %@", error);
      if (!self.currentMeeting) {
        [self.countdownCard startCountdown];
      }
      [[self showMeetingCard] subscribeCompleted:^{
        DDLogVerbose(@"Showed meeting card");
        [self showPoptipsIfNeeded];
      }];
      [subscriber sendError:error];
    }];
    return nil;
  }];
}

- (void)clearView {
  if ([self.refreshControl isRefreshing]) {
    [self.refreshControl endRefreshing];
  }
  if ([JTProgressHUD isVisible]) {
    [JTProgressHUD hide];
  }
}

- (void)showPoptipsIfNeeded {
  PFUser *user = [PFUser currentUser];
  if (![user[kUserHasSeenTips] boolValue]) {
    [self showTips];
  }
}

#pragma mark Views

- (void)setUpScrollView {
  self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
  self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
  self.scrollView.alwaysBounceVertical = YES;

  self.refreshControl = [UIRefreshControl new];
  [self.refreshControl addTarget:self action:@selector(refreshMeeting) forControlEvents:UIControlEventValueChanged];
  [self.scrollView addSubview:self.refreshControl];

  [self.view addSubview:self.scrollView];
}

- (void)setUpCards {
  self.meetingCard = [[NDAMeetingCard alloc] initWithFrame:CGRectMake(kDashboardViewPadding, kDashboardViewPadding, CGRectGetWidth([UIScreen mainScreen].bounds) - kDashboardViewPadding * 2, kMeetingCardHeight)];
  self.meetingCard.accessibilityIdentifier = @"Meeting Card";
  self.meetingCard.rac_command = [[RACCommand alloc] initWithSignalBlock:^(id _) {
    if (self.currentMeeting) {
      if (!self.currentMeetingViewController || self.currentMeetingViewController.meeting != self.currentMeeting) {
        self.currentMeetingViewController = [[NDAMeetingViewController alloc] initWithMeeting:self.currentMeeting];
      }
      [NDAMeetingManager sharedInstance].userMeeting[kUserHasSeenKey] = @YES;
      [[NDAMeetingManager sharedInstance].userMeeting saveEventually];
      [self.navigationController pushViewController:self.currentMeetingViewController animated:YES];
    }
    return [RACSignal empty];
  }];
  [self.scrollView addSubview:self.meetingCard];

  self.karmaCard = [[NDAKarmaCard alloc] initWithFrame:CGRectMake(kDashboardViewPadding, kDashboardViewPadding, CGRectGetWidth([UIScreen mainScreen].bounds) - kDashboardViewPadding * 2, kKarmaCardHeight)];
  self.karmaCard.accessibilityIdentifier = @"Karma Card";
  [self.scrollView addSubview:self.karmaCard];

  self.countdownCard = [[NDACountdownCard alloc] initWithFrame:CGRectMake(kDashboardViewPadding, self.karmaCard.bottom + kDashboardCardSpacing, CGRectGetWidth([UIScreen mainScreen].bounds) - kDashboardViewPadding * 2, kCountdownCardHeight)];
  self.countdownCard.accessibilityIdentifier = @"Countdown Card";
  [self.scrollView addSubview:self.countdownCard];
}

- (void)fixScrollView {
  CGFloat cardsHeight = self.countdownCard.bottom + kDashboardViewPadding;
  if (cardsHeight > self.scrollView.height || self.scrollView.contentSize.height > self.scrollView.height) {
    self.scrollView.contentSize = CGSizeMake(self.scrollView.width, cardsHeight);
  }
}

- (void)showTips {
  self.refreshing = YES;

  self.popTip = [AMPopTip popTip];
  self.popTip.popoverColor = [UIColor nda_accentColor];
  self.popTip.actionAnimation = AMPopTipActionAnimationFloat;
  self.popTip.shouldDismissOnTapOutside = YES;
  self.popTip.shouldDismissOnTap = YES;

  self.tipsView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
  self.tipsView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.75f];
  self.tipsView.alpha = 0;
  [[[UIApplication sharedApplication] delegate].window addSubview:self.tipsView];
  [UIView animateWithDuration:0.4f animations:^{
    self.tipsView.alpha = 1;
  } completion:^(BOOL finished) {
    [self showPoptipForView:self.karmaCard];
  }];
}

- (void)showPoptipForView:(UIView *)view {
  NSMutableAttributedString *text;
  NSDictionary *lightFontAttributes = @{
    NSFontAttributeName : [UIFont fontWithName:kLightFontName size:[UIFont mediumTextFontSize]],
    NSForegroundColorAttributeName : [UIColor whiteColor]
  };
  NSDictionary *regularFontAttributes = @{
    NSFontAttributeName : [UIFont fontWithName:kRegularFontName size:[UIFont mediumTextFontSize]],
    NSForegroundColorAttributeName : [UIColor whiteColor]
  };

  if (view == self.karmaCard) {
    text = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"Это ваша карма. Вы получаете ", nil) attributes:lightFontAttributes];
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:@"+1" attributes:regularFontAttributes]];
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@" за согласие на встречу и ", nil) attributes:lightFontAttributes]];
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:@"-2" attributes:regularFontAttributes]];
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@" за отказ от нее.", nil) attributes:lightFontAttributes]];
  } else if (view == self.meetingCard) {
    text = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(self.currentMeeting ? @"Это ваше приглашение на встречу" : @"Здесь появится ваше первое приглашение на встречу ", nil) attributes:lightFontAttributes];
    if (!self.currentMeeting) {
      [text appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"%@ в полдень.", nil), [NSDate currentHour] > 12 ? NSLocalizedString(@"завтра", nil) : NSLocalizedString(@"сегодня", nil)] attributes:regularFontAttributes]];
    }
  }

  __weak typeof(self) weakSelf = self;
  self.popTip.dismissHandler = ^{
    [view removeFromSuperview];
    view.frame = [weakSelf.tipsView convertRect:view.frame toView:weakSelf.scrollView];
    [weakSelf.scrollView addSubview:view];

    if (view == weakSelf.karmaCard) {
      [weakSelf performSelector:@selector(showPoptipForView:) withObject:weakSelf.meetingCard afterDelay:weakSelf.popTip.animationOut];
    } else {
      [weakSelf.popTip hide];
      [UIView animateWithDuration:0.4f delay:weakSelf.popTip.animationOut options:0 animations:^{
        weakSelf.tipsView.alpha = 0;
      } completion:^(BOOL finished) {
        [weakSelf.tipsView removeFromSuperview];
        weakSelf.refreshing = NO;
        PFUser *user = [PFUser currentUser];
        user[kUserHasSeenTips] = @YES;
        [user saveEventually];
      }];
    }
  };

  [view removeFromSuperview];
  view.frame = [self.scrollView convertRect:view.frame toView:self.tipsView];
  [self.tipsView addSubview:view];

  [self.popTip showAttributedText:text direction:AMPopTipDirectionDown maxWidth:self.scrollView.width * 0.75f inView:self.tipsView fromFrame:view.frame];
}

#pragma mark Animations

- (RACSignal *)showMeetingCard {
  if (!self.meetingCard.hidden) {
    return [RACSignal empty];
  }
  self.scrollView.userInteractionEnabled = NO;
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    for (UIView *card in @[self.karmaCard, self.countdownCard]) {
      [UIView animateWithDuration:0.2f animations:^{
        card.top += kMeetingCardHeight + kDashboardCardSpacing;
      } completion:^(BOOL finished) {
        [self fixScrollView];
        [[self.meetingCard show] subscribeCompleted:^{
          self.scrollView.userInteractionEnabled = YES;
          [subscriber sendCompleted];
        }];
      }];
    }
    return nil;
  }];
}

- (RACSignal *)hideMeetingCard {
  if (self.meetingCard.hidden) {
    return [RACSignal empty];
  }
  self.scrollView.userInteractionEnabled = NO;
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    [[self.meetingCard hide] subscribeCompleted:^{
      for (UIView *card in @[self.karmaCard, self.countdownCard]) {
        [UIView animateWithDuration:0.2f animations:^{
          card.top -= kMeetingCardHeight + kDashboardCardSpacing;
        } completion:^(BOOL finished) {
          [self fixScrollView];
          self.scrollView.userInteractionEnabled = YES;
          [subscriber sendCompleted];
        }];
      }
    }];
    return nil;
  }];
}

#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
  self.refreshing = YES;
  [[[NDAMeetingManager sharedInstance] saveImageForMeeting:info[UIImagePickerControllerOriginalImage]] subscribeError:^(NSError *error) {
    DDLogError(@"Error occured while saving image for meeting: %@", error);
  } completed:^{
    DDLogVerbose(@"Saved image for meeting");
  }];
  [picker dismissViewControllerAnimated:YES completion:^{
    if (!info[UIImagePickerControllerEditedImage] && !info[UIImagePickerControllerOriginalImage]) {
      return;
    }
    if ([FSOpenInInstagram canSendInstagram]) {
      UIView *selfieView = [self selfieViewWithImage:info[UIImagePickerControllerEditedImage] ? : info[UIImagePickerControllerOriginalImage]];
      [self.instagrammer postImage:[UIImage convertViewToImage:selfieView] caption:NSLocalizedString(@"Одно знакомство в день! #neverdrinkalone @neverdrinkalone", nil) inView:self.view delegate:self];
    } else {
      UIImageWriteToSavedPhotosAlbum(info[UIImagePickerControllerOriginalImage], nil, nil, nil);
      PFUser *user = [PFUser currentUser];
      user[kCanPostSelfieKey] = @NO;
      [user removeObjectForKey:kLastNotificationKey];
      [user saveEventually];
      [[user karmaTransactionWithAmount:@(1) description:@"Saved a selfie"] subscribeNext:^(PFObject *karmaTransaction) {
        [[self.karmaCard updateKarma] subscribeError:^(NSError *error) {
          DDLogError(@"Error occured while updating karma: %@", error);
        } completed:^{
          [self.alertManager showNotificationWithText:@"Спасибо! +1 к карме" color:[UIColor nda_greenColor]];
        }];
      } error:^(NSError *error) {
        DDLogError(@"Error occured while performing a karma transaction: %@", error);
      }];
      [[SEGAnalytics sharedAnalytics] track:@"Saved a selfie" properties:nil options:@{
         @"meetingId" : self.currentMeeting.objectId
       }];
    }
    self.refreshing = NO;
  }];
}

- (UIView *)selfieViewWithImage:(UIImage *)image {
  UIImageView *selfieView = [[UIImageView alloc] initWithFrame:(CGRect) {CGPointZero, kSelfieViewSize }];
  selfieView.image = image;
  selfieView.contentMode = UIViewContentModeScaleAspectFill;
  UILabel *watermarkLabel = [UILabel new];
  watermarkLabel.textColor = [UIColor whiteColor];
  watermarkLabel.font = [UIFont fontWithName:kLightFontName size:70];
  watermarkLabel.text = @"@neverdrinkalone";
  watermarkLabel.layer.shadowColor = [UIColor blackColor].CGColor;
  watermarkLabel.layer.shadowRadius = 5;
  watermarkLabel.layer.shadowOpacity = 1;
  [watermarkLabel sizeToFit];
  [selfieView addSubview:watermarkLabel];
  watermarkLabel.right = selfieView.right - 10;
  watermarkLabel.bottom = selfieView.bottom - 10;
  return selfieView;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UIDocumentInteractionControllerDelegate

- (void)documentInteractionController:(UIDocumentInteractionController *)controller didEndSendingToApplication:(NSString *)application {
  PFUser *user = [PFUser currentUser];
  user[kCanPostSelfieKey] = @NO;
  [user removeObjectForKey:kLastNotificationKey];
  [user saveEventually];
  [[user karmaTransactionWithAmount:@(1) description:@"Posted a selfie"] subscribeNext:^(PFObject *karmaTransaction) {
    [[self.karmaCard updateKarma] subscribeError:^(NSError *error) {
      DDLogError(@"Error occured while updating karma: %@", error);
    } completed:^{
      [self.alertManager showNotificationWithText:@"Спасибо! +1 к карме" color:[UIColor nda_greenColor]];
    }];
  } error:^(NSError *error) {
    DDLogError(@"Error occured while performing a karma transaction: %@", error);
  }];
  [[SEGAnalytics sharedAnalytics] track:@"Posted a selfie" properties:nil options:@{
     @"meetingId" : self.currentMeeting.objectId
   }];
}

@end
