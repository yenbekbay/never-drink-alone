#import "NDAPermissionsViewController.h"

#import "JLLocationPermission.h"
#import "JLNotificationPermission.h"
#import "NDAConstants.h"
#import "NDAFirstProfileConfigurationViewController.h"
#import "UIColor+NDATints.h"
#import "UIFont+NDASizes.h"
#import "UIImage+NDAHelpers.h"
#import "UILabel+NDAHelpers.h"
#import "UIView+AYUtils.h"
#import <Parse/Parse.h>

static CGFloat const kPermissionsViewPadding = 20;
static CGFloat const kPermissionsButtonHeight = 60;
static CGFloat const kPermissionsButtonSpacing = 30;
static CGFloat const kPermissionsUnderButtonMargin = 5;
static UIEdgeInsets const kContinueButtonPadding = {
  5, 10, 5, 10
};

@interface NDAPermissionsViewController ()

/**
 *  Label containting a short introduction to the user.
 */
@property (nonatomic) UILabel *introductionLabel;
/**
 *  Button asking the user for the location permission.
 */
@property (nonatomic) UIButton *allowLocationButton;
/**
 *  Label containing the explanation for the need of the user's location.
 */
@property (nonatomic) UILabel *allowLocationLabel;
/**
 *  Button asking the user for the notifications permission.
 */
@property (nonatomic) UIButton *allowNotificationsButton;
/**
 *  Label containing the explanation for the need of notifications.
 */
@property (nonatomic) UILabel *allowNotificationsLabel;
/**
 *  Button allowing the user to continue to the next screen.
 */
@property (nonatomic) UIButton *continueButton;
/**
 *  Timer that gets initialized when the allow notification button is tapped.
 */
@property (nonatomic) NSTimer *notificationsPermissionTimer;

@end

@implementation NDAPermissionsViewController

#pragma mark Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor whiteColor];
  self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
  [self setUpIntroductionLabel];
  [self setUpAllowLocation];
  [self setUpAllowNotifications];
  [self setUpContinueButton];
  [self fixLayout];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.navigationController.navigationBarHidden = YES;
  [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}

#pragma mark Private

- (void)setUpIntroductionLabel {
  self.introductionLabel = [[UILabel alloc] initWithFrame:CGRectMake(kPermissionsViewPadding, 0, self.view.width - kPermissionsViewPadding * 2, 0)];
  self.introductionLabel.textColor = [UIColor nda_textColor];
  self.introductionLabel.font = [UIFont fontWithName:kRegularFontName size:[UIFont largeTextFontSize]];
  self.introductionLabel.textAlignment = NSTextAlignmentCenter;
  self.introductionLabel.numberOfLines = 0;
  self.introductionLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Привет, %@! Прежде чем мы начнем, нам нужно получить несколько разрешений.", nil), [PFUser currentUser][kUserFirstNameKey]];
  [self.introductionLabel setFrameToFitWithHeightLimit:0];

  [self.view addSubview:self.introductionLabel];
}

- (void)setUpAllowLocation {
  self.allowLocationButton = [[UIButton alloc] initWithFrame:CGRectMake(kPermissionsViewPadding, self.introductionLabel.bottom + kPermissionsButtonSpacing, self.view.width - kPermissionsViewPadding * 2, kPermissionsButtonHeight)];
  [self stylizeButton:self.allowLocationButton];
  [self.allowLocationButton setTitle:NSLocalizedString(@"Включить геолокацию", nil) forState:UIControlStateNormal];
  [self.allowLocationButton addTarget:self action:@selector(allowLocationButtonTapped) forControlEvents:UIControlEventTouchUpInside];
  if ([[JLLocationPermission sharedInstance] authorizationStatus] == JLPermissionAuthorized) {
    [self setButtonActive:self.allowLocationButton];
  }

  self.allowLocationLabel = [[UILabel alloc] initWithFrame:CGRectMake(kPermissionsViewPadding, self.allowLocationButton.bottom + kPermissionsUnderButtonMargin, self.view.width - kPermissionsViewPadding * 2, 0)];
  [self stylizeLabel:self.allowLocationLabel];
  self.allowLocationLabel.text = NSLocalizedString(@"Мы покажем вам места, которые находятся возле вашего текущего местоположения.", nil);
  [self.allowLocationLabel setFrameToFitWithHeightLimit:0];

  [self.view addSubview:self.allowLocationButton];
  [self.view addSubview:self.allowLocationLabel];
}

- (void)setUpAllowNotifications {
  self.allowNotificationsButton = [[UIButton alloc] initWithFrame:CGRectMake(kPermissionsViewPadding, self.allowLocationLabel.bottom + kPermissionsButtonSpacing, self.view.width - kPermissionsViewPadding * 2, kPermissionsButtonHeight)];
  [self stylizeButton:self.allowNotificationsButton];
  [self.allowNotificationsButton setTitle:NSLocalizedString(@"Включить уведомления", nil) forState:UIControlStateNormal];
  [self.allowNotificationsButton addTarget:self action:@selector(allowNotificationsButtonTapped) forControlEvents:UIControlEventTouchUpInside];
  if ([[UIApplication sharedApplication] currentUserNotificationSettings].types != UIUserNotificationTypeNone) {
    [self setButtonActive:self.allowNotificationsButton];
    PFInstallation *installation = [PFInstallation currentInstallation];
    DDLogVerbose(@"Set the user to current installation");
    installation[kUserKey] = [PFUser currentUser];
    [installation saveEventually];
  }

  self.allowNotificationsLabel = [[UILabel alloc] initWithFrame:CGRectMake(kPermissionsViewPadding, self.allowNotificationsButton.bottom + kPermissionsUnderButtonMargin, self.view.width - kPermissionsViewPadding * 2, 0)];
  [self stylizeLabel:self.allowNotificationsLabel];
  self.allowNotificationsLabel.text = NSLocalizedString(@"Мы будем оповещать вас о новых встречах с интересными людьми.", nil);
  [self.allowNotificationsLabel setFrameToFitWithHeightLimit:0];

  [self.view addSubview:self.allowNotificationsButton];
  [self.view addSubview:self.allowNotificationsLabel];
}

- (void)setUpContinueButton {
  self.continueButton = [UIButton new];
  [self.continueButton setTitle:@"Продолжить" forState:UIControlStateNormal];
  self.continueButton.layer.cornerRadius = kMediumButtonCornerRadius;
  self.continueButton.clipsToBounds = YES;
  self.continueButton.titleLabel.font = [UIFont fontWithName:kRegularFontName size:[UIFont mediumButtonFontSize]];
  [self.continueButton setTitleColor:[UIColor nda_textColor] forState:UIControlStateNormal];
  [self.continueButton addTarget:self action:@selector(continueToNextScreen) forControlEvents:UIControlEventTouchUpInside];
  [self.continueButton setBackgroundImage:[UIImage imageWithColor:[UIColor nda_lightGrayColor]] forState:UIControlStateHighlighted];
  CGSize continueButtonSize = [self.continueButton.titleLabel.text sizeWithAttributes:@{ NSFontAttributeName : self.continueButton.titleLabel.font }];
  self.continueButton.frame = CGRectMake((self.view.width - kContinueButtonPadding.left - continueButtonSize.width - kContinueButtonPadding.right) / 2, self.allowNotificationsLabel.bottom + kPermissionsButtonSpacing, kContinueButtonPadding.left + continueButtonSize.width + kContinueButtonPadding.right, kContinueButtonPadding.top + continueButtonSize.height + kContinueButtonPadding.bottom);

  [self.view addSubview:self.continueButton];

  [self setContinueButtonEnabled:[[UIApplication sharedApplication] currentUserNotificationSettings].types != UIUserNotificationTypeNone];
}

- (void)fixLayout {
  CGFloat totalHeight = self.continueButton.bottom - self.introductionLabel.top;
  CGFloat diff = (self.view.height - totalHeight) / 2;

  for (UIView *view in @[self.introductionLabel, self.allowLocationButton, self.allowLocationLabel, self.allowNotificationsButton, self.allowNotificationsLabel, self.continueButton]) {
    view.top += diff;
  }
}

- (void)stylizeButton:(UIButton *)button {
  [button setTitleColor:[UIColor nda_greenColor] forState:UIControlStateNormal];
  button.titleLabel.font = [UIFont fontWithName:kRegularFontName size:[UIFont mediumButtonFontSize]];
  button.clipsToBounds = YES;
  button.layer.cornerRadius = kPermissionsButtonHeight / 2;
  button.layer.borderColor = [UIColor nda_greenColor].CGColor;
  button.layer.borderWidth = 1;
}

- (void)stylizeLabel:(UILabel *)label {
  label.numberOfLines = 0;
  label.textAlignment = NSTextAlignmentCenter;
  label.textColor = [UIColor nda_darkGrayColor];
  label.font = [UIFont fontWithName:kRegularFontName size:[UIFont mediumTextFontSize]];
}

- (void)setButtonActive:(UIButton *)button {
  [button setBackgroundImage:[UIImage imageWithColor:[UIColor nda_greenColor]] forState:UIControlStateNormal];
  [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  [button setUserInteractionEnabled:NO];
  if (button == self.allowLocationButton) {
    [button setTitle:@"Геолокация включена" forState:UIControlStateNormal];
  } else if (button == self.allowNotificationsButton) {
    [button setTitle:@"Уведомления включены" forState:UIControlStateNormal];
  }
}

- (void)setContinueButtonEnabled:(BOOL)enabled {
  self.continueButton.enabled = enabled;
  self.continueButton.alpha = enabled ? 1.0f : 0.5f;
}

#pragma mark Button methods

- (void)allowLocationButtonTapped {
  [[JLLocationPermission sharedInstance] authorizeWithTitle:NSLocalizedString(@"Разрешите нам использовать ваше местоположение по геолокации", nil) message:nil cancelTitle:NSLocalizedString(@"Отказать", nil) grantTitle:NSLocalizedString(@"Разрешить", nil) completion:^(bool granted, NSError *error) {
    if (!error) {
      DDLogVerbose(@"User gave permission for geolocation");
      [self setButtonActive:self.allowLocationButton];
    } else {
      DDLogError(@"Error occured while getting permission for geolocation: %@", error);
    }
  }];
}

- (void)allowNotificationsButtonTapped {
  if ([[UIApplication sharedApplication] currentUserNotificationSettings].types == UIUserNotificationTypeNone) {
    self.notificationsPermissionTimer = [NSTimer scheduledTimerWithTimeInterval:0.5f target:self selector:@selector(checkNotificationsPermission) userInfo:nil repeats:YES];
  }
  [[JLNotificationPermission sharedInstance] authorizeWithTitle:NSLocalizedString(@"Разрешите нам посылать вам push-уведомления", nil) message:nil cancelTitle:NSLocalizedString(@"Отказать", nil) grantTitle:NSLocalizedString(@"Разрешить", nil) completion:nil];
}

- (void)checkNotificationsPermission {
  if ([[UIApplication sharedApplication] currentUserNotificationSettings].types != UIUserNotificationTypeNone) {
    DDLogVerbose(@"User gave permission for nofitications");
    [self.notificationsPermissionTimer invalidate];
    [self setButtonActive:self.allowNotificationsButton];
    [self setContinueButtonEnabled:YES];
    PFInstallation *installation = [PFInstallation currentInstallation];
    installation[kUserKey] = [PFUser currentUser];
    [installation saveEventually];
  }
}

- (void)continueToNextScreen {
  [self.navigationController pushViewController:[NDAFirstProfileConfigurationViewController new] animated:YES];
}

@end
