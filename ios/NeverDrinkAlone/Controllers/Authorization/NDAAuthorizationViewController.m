#import "NDAAuthorizationViewController.h"

#import "CRGradientNavigationBar.h"
#import "JLNotificationPermission.h"
#import "JTProgressHUD.h"
#import "NDAAlertManager.h"
#import "NDAConstants.h"
#import "NDALogInViewController.h"
#import "NDAMacros.h"
#import "NDAMainPageViewController.h"
#import "NDAPermissionsViewController.h"
#import "NDASignUpViewController.h"
#import "PFUser+NDAHelpers.h"
#import "UIColor+NDAHelpers.h"
#import "UIColor+NDATints.h"
#import "UIFont+NDASizes.h"
#import "UIImage+ImageEffects.h"
#import "UIImage+NDAHelpers.h"
#import "UILabel+NDAHelpers.h"
#import "UIView+AYUtils.h"
#import <Analytics/Analytics.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <IOSLinkedInAPI/LIALinkedInApplication.h>
#import <Parse/Parse.h>
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import <PFLinkedInUtils/PFLinkedInUtils.h>

static CGFloat const kAuthorizationButtonHeight = 50;
static CGFloat const kAuthorizationLogoTopMargin = 50;
static CGFloat const kAuthorizationLogoWidth = 100;
static CGFloat const kAuthorizatonTaglineTopMargin = 10;
static CGFloat const kAuthorizationTaglineWidth = 300;
static CGFloat const kAuthorizationButtonCornerRadius = 10;
static CGFloat const kAuthorizationButtonPadding = 20;
static CGFloat const kAuthorizationButtonSpacing = 10;
static CGSize const kAuthorizationButtonIconSize = {
  25, 25
};
static CGFloat const kAuthorizationNoticeLabelTopMargin = 20;
static UIEdgeInsets const kAuthorizationSeparatorLabelPadding = {
  5, 10, 5, 10
};

#define SHOW_NOTICE 0

@interface NDAAuthorizationViewController ()

/**
 *  Image view containing the background image.
 */
@property (nonatomic) UIImageView *backgroundView;
/**
 *  Image view containing the app's verbal logo.
 */
@property (nonatomic) UIImageView *logoView;
/**
 *  Label with the app's motto/tagline.
 */
@property (nonatomic) UILabel *tagline;
/**
 *  Label informing the user about the terms of service and privacy policy.
 */
@property (nonatomic) UILabel *noticeLabel;
/**
 *  Button initializing the login with email.
 */
@property (nonatomic) UIButton *loginButton;
/**
 *  Button initializing the signup with email.
 */
@property (nonatomic) UIButton *signupButton;
/**
 *  Label for the separator.
 */
@property (nonatomic) UILabel *separatorLabel;
/**
 *  Thin border to the left side of the separator label.
 */
@property (nonatomic) UIView *separatorLeftBorder;
/**
 *  Thin border to the right side of the separator label.
 */
@property (nonatomic) UIView *separatorRightBorder;
/**
 *  Button initializing the login/signup process with Facebook.
 */
@property (nonatomic) UIButton *facebookButton;
/**
 *  Button initializing the login/signup process with LinkedIn.
 */
@property (nonatomic) UIButton *linkedInButton;
/**
 *  Used to display notifications and alerts.
 */
@property (nonatomic) NDAAlertManager *alertManager;

@end

@implementation NDAAuthorizationViewController

#pragma mark Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor whiteColor];
  self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
  self.alertManager = [NDAAlertManager new];
  [self setUpBackgroundView];
  [self setUpLogoView];
#if SHOW_NOTICE
  [self setUpNoticeLabel];
#endif
  [self setUpEmailButtons];
  [self setUpSeparator];
  [self setUpSocialButtons];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.navigationController.navigationBarHidden = YES;
  [(CRGradientNavigationBar *)self.navigationController.navigationBar setBarTintGradientColors:@[
     [UIColor nda_primaryColor],
     [UIColor nda_complementaryColor]
   ]];
}

#pragma mark Private

- (void)setUpBackgroundView {
  self.backgroundView = [[UIImageView alloc] initWithFrame:self.view.bounds];
  self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self.backgroundView.image = [[UIImage imageNamed:@"AuthorizationBackground.jpg"] applyBlurWithRadius:kBackdropBlurRadius tintColor:[UIColor colorWithWhite:0 alpha:kBackdropBlurDarkeningRatio] saturationDeltaFactor:kBackdropBlurSaturationDeltaFactor maskImage:nil];
  [self.view addSubview:self.backgroundView];
}

- (void)setUpLogoView {
  UIImage *logo = [UIImage imageNamed:@"Logo"];
  CGFloat ratio = logo.size.height / logo.size.width;

  self.logoView = [[UIImageView alloc] initWithFrame:CGRectMake((self.view.width - kAuthorizationLogoWidth) / 2, CGRectGetHeight([UIApplication sharedApplication].statusBarFrame) + (IS_IPHONE_4_OR_LESS ? 20 : kAuthorizationLogoTopMargin), kAuthorizationLogoWidth, kAuthorizationLogoWidth * ratio)];
  self.logoView.image = [logo imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  self.logoView.tintColor = [UIColor whiteColor];

  self.tagline = [[UILabel alloc] initWithFrame:CGRectMake((self.view.width - kAuthorizationTaglineWidth) / 2, self.logoView.bottom + kAuthorizatonTaglineTopMargin, kAuthorizationTaglineWidth, 0)];
  self.tagline.textColor = [UIColor whiteColor];
  self.tagline.font = [UIFont fontWithName:kRegularFontName size:[UIFont mediumTextFontSize]];
  self.tagline.numberOfLines = 0;
  self.tagline.textAlignment = NSTextAlignmentCenter;
  self.tagline.text = NSLocalizedString(@"Одно деловое знакомство в день с самыми интересными людьми в Алматы!", nil);
  [self.tagline setFrameToFitWithHeightLimit:0];

  [self.view addSubview:self.logoView];
  [self.view addSubview:self.tagline];
}

- (void)setUpNoticeLabel {
  self.noticeLabel = [[UILabel alloc] initWithFrame:CGRectMake(kAuthorizationViewPadding, 0, self.view.width - kAuthorizationViewPadding * 2, 0)];
  self.noticeLabel.textColor = [UIColor whiteColor];
  self.noticeLabel.font = [UIFont fontWithName:kRegularFontName size:[UIFont extraSmallTextFontSize]];
  self.noticeLabel.numberOfLines = 0;
  self.noticeLabel.textAlignment = NSTextAlignmentCenter;
  self.noticeLabel.text = NSLocalizedString(@"Регистрируясь, вы соглашаетесь с нашим пользовательским соглашением и политикой конфиденциальности.", nil);
  [self.noticeLabel setFrameToFitWithHeightLimit:0];
  self.noticeLabel.top = self.view.height - kAuthorizationViewPadding - self.noticeLabel.height;

  [self.view addSubview:self.noticeLabel];
}

- (void)setUpEmailButtons {
  self.loginButton = [[UIButton alloc] initWithFrame:CGRectMake(kAuthorizationViewPadding, (self.noticeLabel ? (self.noticeLabel.top - kAuthorizationNoticeLabelTopMargin) : (self.view.height - kAuthorizationViewPadding)) - kAuthorizationButtonHeight, self.view.width - kAuthorizationViewPadding * 2, kAuthorizationButtonHeight)];
  self.loginButton.accessibilityIdentifier = @"Log In Button";
  [self.loginButton setTitle:@"Войти" forState:UIControlStateNormal];
  [self.loginButton addTarget:self action:@selector(loginButtonTapped) forControlEvents:UIControlEventTouchUpInside];

  self.signupButton = [[UIButton alloc] initWithFrame:CGRectMake(kAuthorizationViewPadding, self.loginButton.top - kAuthorizationButtonSpacing - kAuthorizationButtonHeight, self.view.width - kAuthorizationViewPadding * 2, kAuthorizationButtonHeight)];
  [self.signupButton setTitle:@"Зарегистрироваться" forState:UIControlStateNormal];
  self.signupButton.accessibilityIdentifier = @"Sign Up Button";
  [self.signupButton addTarget:self action:@selector(signupButtonTapped) forControlEvents:UIControlEventTouchUpInside];

  for (UIButton *button in @[self.loginButton, self.signupButton]) {
    button.tintColor = [UIColor whiteColor];
    button.titleLabel.font = [UIFont fontWithName:kLightFontName size:[UIFont authorizationButtonFontSize]];
    button.clipsToBounds = YES;
    button.layer.cornerRadius = kAuthorizationButtonCornerRadius;
    button.layer.borderColor = [UIColor whiteColor].CGColor;
    button.layer.borderWidth = 1;
    [button setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithWhite:1 alpha:0.1f]] forState:UIControlStateHighlighted];
    [self.view addSubview:button];
  }
}

- (void)setUpSeparator {
  self.separatorLabel = [UILabel new];
  self.separatorLabel.text = NSLocalizedString(@"или", nil);
  self.separatorLabel.textColor = [UIColor whiteColor];
  self.separatorLabel.font = [UIFont fontWithName:kRegularFontName size:[UIFont mediumTextFontSize]];
  self.separatorLabel.textAlignment = NSTextAlignmentCenter;
  CGSize separatorLabelSize = [self.separatorLabel.text sizeWithAttributes:@{ NSFontAttributeName : self.separatorLabel.font }];
  separatorLabelSize = CGSizeMake(kAuthorizationSeparatorLabelPadding.left + separatorLabelSize.width + kAuthorizationSeparatorLabelPadding.right, kAuthorizationSeparatorLabelPadding.top + separatorLabelSize.height + kAuthorizationSeparatorLabelPadding.bottom);
  self.separatorLabel.frame = CGRectMake((self.view.width - separatorLabelSize.width) / 2, self.signupButton.top - kAuthorizationButtonSpacing - separatorLabelSize.height, separatorLabelSize.width, separatorLabelSize.height);
  [self.view addSubview:self.separatorLabel];

  self.separatorLeftBorder = [[UIView alloc] initWithFrame:CGRectMake(kAuthorizationViewPadding, 0, self.separatorLabel.left - kAuthorizationViewPadding, 1)];
  self.separatorRightBorder = [[UIView alloc] initWithFrame:CGRectMake(self.separatorLabel.right, 0, self.view.width - kAuthorizationViewPadding - self.separatorLabel.right, 1)];
  for (UIView *border in @[self.separatorLeftBorder, self.separatorRightBorder]) {
    border.center = CGPointMake(border.center.x, self.separatorLabel.center.y);
    border.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:border];
  }
}

- (void)setUpSocialButtons {
  self.facebookButton = [[UIButton alloc] initWithFrame:CGRectMake(kAuthorizationViewPadding, self.separatorLabel.top - kAuthorizationButtonSpacing - kAuthorizationButtonHeight, self.view.width - kAuthorizationViewPadding * 2, kAuthorizationButtonHeight)];
  self.facebookButton.accessibilityIdentifier = @"Facebook Button";
  [self.facebookButton setBackgroundImage:[UIImage imageWithColor:[UIColor nda_facebookColor]] forState:UIControlStateNormal];
  [self.facebookButton setBackgroundImage:[UIImage imageWithColor:[[UIColor nda_facebookColor] darkerColor:0.1f]] forState:UIControlStateHighlighted];
  [self.facebookButton setTitle:NSLocalizedString(@"Войти через Facebook", nil) forState:UIControlStateNormal];

  self.linkedInButton = [[UIButton alloc] initWithFrame:CGRectMake(kAuthorizationViewPadding, self.facebookButton.top - kAuthorizationButtonSpacing - kAuthorizationButtonHeight, self.view.width - kAuthorizationViewPadding * 2, kAuthorizationButtonHeight)];
  self.linkedInButton.accessibilityIdentifier = @"Linked In Button";
  [self.linkedInButton setBackgroundImage:[UIImage imageWithColor:[UIColor nda_linkedinColor]]
   forState:UIControlStateNormal];
  [self.linkedInButton setBackgroundImage:[UIImage imageWithColor:[[UIColor nda_linkedinColor] darkerColor:0.1f]]
   forState:UIControlStateHighlighted];
  [self.linkedInButton setTitle:NSLocalizedString(@"Войти через LinkedIn", nil) forState:UIControlStateNormal];

  for (UIButton *button in @[self.facebookButton, self.linkedInButton]) {
    UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake(kAuthorizationButtonPadding, (button.height - kAuthorizationButtonIconSize.height) / 2, kAuthorizationButtonIconSize.width, kAuthorizationButtonIconSize.height)];
    iconView.tintColor = [UIColor whiteColor];
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    if (button == self.linkedInButton) {
      iconView.image = [[UIImage imageNamed:@"LinkedInIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    } else {
      iconView.image = [[UIImage imageNamed:@"FacebookIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    [button addSubview:iconView];

    button.adjustsImageWhenHighlighted = NO;
    button.tintColor = [UIColor whiteColor];
    button.titleLabel.font = [UIFont fontWithName:kLightFontName size:[UIFont authorizationButtonFontSize]];
    button.clipsToBounds = YES;
    button.layer.cornerRadius = kAuthorizationButtonCornerRadius;
    button.titleEdgeInsets = UIEdgeInsetsMake(0, kAuthorizationButtonPadding + kAuthorizationButtonIconSize.width, 0, 0);
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(authorizationButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
  }
}

- (void)authorizationButtonTapped:(UIButton *)button {
  if (button == self.linkedInButton) {
    [PFLinkedInUtils logInWithBlock:^(PFUser *user, NSError *error) {
      if (!error || error.code == 351) {
        [self connectLinkedInWithUser:user];
      } else {
        DDLogError(@"Error occured while logging in through LinkedIn: %@", error);
        [self.alertManager showNotificationWithText:NSLocalizedString(@"Что-то пошло не так. Попробуйте чуть позже", nil)];
      }
    }];
  } else {
    [PFFacebookUtils logInInBackgroundWithReadPermissions:@[@"email"] block:^(PFUser *user, NSError *error) {
      if (!error) {
        [self connectFacebookWithUser:user];
      } else {
        DDLogError(@"Error occured while logging in through Facebook: %@", error);
        [self.alertManager showNotificationWithText:NSLocalizedString(@"Что-то пошло не так. Попробуйте чуть позже", nil)];
      }
    }];
  }
}

- (void)connectLinkedInWithUser:(PFUser *)user {
  if (!user) {
    DDLogVerbose(@"User cancelled the LinkedIn login");
  } else if (user.isNew) {
    NSString *fields = @":(first-name,last-name,email-address,headline,industry,picture-urls::(original))";
    NSDictionary *params = @{
      @"format" : @"json",
      @"oauth2_access_token" : [PFLinkedInUtils.linkedInHttpClient accessToken]
    };
    [JTProgressHUD showWithTransition:JTProgressHUDTransitionFade];
    [PFLinkedInUtils.linkedInHttpClient GET:[@"https://api.linkedin.com/v1/people/~" stringByAppendingString:fields] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
      DDLogVerbose(@"User signed up and logged in through LinkedIn: %@", responseObject);
      user.email = responseObject[@"emailAddress"];
      user[kUserFirstNameKey] = responseObject[@"firstName"];
      user[kUserLastNameKey] = responseObject[@"lastName"];
      user[kUserBiographyKey] = responseObject[@"headline"];
      user[kUserIndustryKey] = responseObject[@"industry"];
      if (responseObject[@"pictureUrls"]) {
        if ([responseObject[@"pictureUrls"][@"values"] count] > 0) {
          PFObject *userPicture = [PFObject objectWithClassName:@"UserPicture"];
          userPicture[@"imageUrl"] = responseObject[@"pictureUrls"][@"values"][0];
          user[kUserPictureKey] = userPicture;
        }
      }
      [user setDefaults];
      [user saveEventually];
      [[SEGAnalytics sharedAnalytics] identify:user.objectId traits:@{
         kUserFirstNameKey : user[kUserFirstNameKey],
         kUserLastNameKey : user[kUserLastNameKey],
         @"email" : user.email
       }];
      [JTProgressHUD hide];
      [self continueRegistration];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
      DDLogError(@"Error occured while signing up through LinkedIn: %@", error);
      [user deleteEventually];
      [JTProgressHUD hide];
      [self.alertManager showNotificationWithText:NSLocalizedString(@"Что-то пошло не так. Попробуйте чуть позже", nil)];
    }];
  } else {
    DDLogVerbose(@"User logged in through LinkedIn");
    [[SEGAnalytics sharedAnalytics] identify:user.objectId traits:@{
       kUserFirstNameKey : user[kUserFirstNameKey],
       kUserLastNameKey : user[kUserLastNameKey],
       @"email" : user.email
     }];
    if ([[UIApplication sharedApplication] currentUserNotificationSettings].types == UIUserNotificationTypeNone) {
      [self goToDashboard];
      [[JLNotificationPermission sharedInstance] authorizeWithTitle:NSLocalizedString(@"Разрешите нам посылать вам push-уведомления", nil) message:nil cancelTitle:NSLocalizedString(@"Отказать", nil) grantTitle:NSLocalizedString(@"Разрешить", nil) completion:nil];
    } else {
      DDLogVerbose(@"Set the user to current installation");
      PFInstallation *installation = [PFInstallation currentInstallation];
      installation[kUserKey] = [PFUser currentUser];
      [installation saveEventually];
      [self goToDashboard];
    }
  }
}

- (void)connectFacebookWithUser:(PFUser *)user {
  if (!user) {
    DDLogVerbose(@"User cancelled the Facebook login");
  } else if (user.isNew) {
    if ([FBSDKAccessToken currentAccessToken]) {
      [JTProgressHUD showWithTransition:JTProgressHUDTransitionFade];
      [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me?fields=first_name,last_name,email,picture.width(500).height(500)" parameters:nil] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        if (!error) {
          DDLogError(@"Error occured while signing up through Facebook: %@", error);
          user.email = result[@"email"];
          user[kUserFirstNameKey] = result[@"first_name"];
          user[kUserLastNameKey] = result[@"last_name"];
          PFObject *userPicture = [PFObject objectWithClassName:@"UserPicture"];
          userPicture[@"imageUrl"] = result[@"picture"][@"data"][@"url"];
          user[kUserPictureKey] = userPicture;
          [user setDefaults];
          [user saveEventually];
          [[SEGAnalytics sharedAnalytics] identify:user.objectId traits:@{
             kUserFirstNameKey : user[kUserFirstNameKey],
             kUserLastNameKey : user[kUserLastNameKey],
             @"email" : user.email
           }];
          [JTProgressHUD hide];
          [self continueRegistration];
        } else {
          DDLogVerbose(@"User signed up and logged in through Facebook");
          [user deleteEventually];
          [JTProgressHUD hide];
          [self.alertManager showNotificationWithText:NSLocalizedString(@"Что-то пошло не так. Попробуйте чуть позже", nil)];
        }
      }];
    } else {
      [self.alertManager showNotificationWithText:NSLocalizedString(@"Что-то пошло не так. Попробуйте чуть позже", nil)];
    }
  } else {
    DDLogVerbose(@"User logged in through Facebook");
    [[SEGAnalytics sharedAnalytics] identify:user.objectId traits:@{
       kUserFirstNameKey : user[kUserFirstNameKey],
       kUserLastNameKey : user[kUserLastNameKey],
       @"email" : user.email
     }];
    if ([[UIApplication sharedApplication] currentUserNotificationSettings].types == UIUserNotificationTypeNone) {
      [self goToDashboard];
      [[JLNotificationPermission sharedInstance] authorizeWithTitle:NSLocalizedString(@"Разрешите нам посылать вам push-уведомления", nil) message:nil cancelTitle:NSLocalizedString(@"Отказать", nil) grantTitle:NSLocalizedString(@"Разрешить", nil) completion:nil];
    } else {
      DDLogVerbose(@"Set the user to current installation");
      PFInstallation *installation = [PFInstallation currentInstallation];
      installation[kUserKey] = [PFUser currentUser];
      [installation saveEventually];
      [self goToDashboard];
    }
  }
}

- (void)loginButtonTapped {
  [self.navigationController pushViewController:[NDALogInViewController new] animated:YES];
}

- (void)signupButtonTapped {
  [self.navigationController pushViewController:[NDASignUpViewController new] animated:YES];
}

- (void)continueRegistration {
  [self.navigationController pushViewController:[NDAPermissionsViewController new] animated:YES];
}

- (void)goToDashboard {
  [self.navigationController pushViewController:[NDAMainPageViewController new] animated:YES];
}

@end
