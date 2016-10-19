#import "NDAAppDelegate.h"

#import "CRGradientNavigationBar.h"
#import "JLNotificationPermission.h"
#import "NDAAlertView.h"
#import "NDAAuthorizationViewController.h"
#import "NDAConstants.h"
#import "NDAMainPageViewController.h"
#import "NDAPermissionsViewController.h"
#import "NDAWalkthroughViewController.h"
#import "Secrets.h"
#import "UIColor+NDAHelpers.h"
#import "UIColor+NDATints.h"
#import "UIFont+NDASizes.h"
#import "UIImage+NDAHelpers.h"
#import <Analytics/Analytics.h>
#import <Crashlytics/Crashlytics.h>
#import <Fabric/Fabric.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <Parse/Parse.h>
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import <PFLinkedInUtils/PFLinkedInUtils.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

NSString *const kSeenWalkthroughKey = @"hasSeenWalkthrough";
NSString *const kTestUsername = @"yenbekbay";
NSString *const kTestPassword = @"oYhQTg4Q7M";

@interface NDAAppDelegate ()

@property (nonatomic) BOOL didEnterBackground;

@end

@implementation NDAAppDelegate

#pragma mark Lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [Fabric with:@[CrashlyticsKit]];
  [DDLog addLogger:[DDASLLogger sharedInstance]];
  [DDLog addLogger:[DDTTYLogger sharedInstance]];
  [SEGAnalytics setupWithConfiguration:[SEGAnalyticsConfiguration configurationWithWriteKey:kSegmentWriteKey]];
  [Parse setApplicationId:kParseApplicationId
                clientKey:kParseClientKey];
  [PFFacebookUtils initializeFacebookWithApplicationLaunchOptions:launchOptions];
  [PFLinkedInUtils initializeWithRedirectURL:@"http://neverdrinkaloneapp.com"
                   clientId:kLinkedInClientId
                   clientSecret:kLinkedInClientSecret
                   state:kLinkedInState
                   grantedAccess:@[@"r_basicprofile", @"r_emailaddress"]
                   presentingViewController:nil];
  if ([application currentUserNotificationSettings].types != UIUserNotificationTypeNone) {
    [[JLNotificationPermission sharedInstance] authorize:nil];
  }

  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  self.navigationController = [[NDANavigationController alloc] initWithNavigationBarClass:[CRGradientNavigationBar class] toolbarClass:nil];
  self.window.rootViewController = self.navigationController;

  if ([[NSProcessInfo processInfo].arguments containsObject:@"USE_TEST_ACCOUNT"]) {
    DDLogVerbose(@"Using test account");
    self.navigationController.viewControllers = @[[NDAAuthorizationViewController new]];
  } else {
    PFUser *user = [PFUser currentUser];
    if (user) {
      [[SEGAnalytics sharedAnalytics] identify:user.objectId traits:@{
         kUserFirstNameKey : user[kUserFirstNameKey],
         kUserLastNameKey : user[kUserLastNameKey],
         @"email" : user.email
       }];
      if ([user[kUserDidFinishRegistrationKey] boolValue]) {
        self.navigationController.viewControllers = @[[NDAMainPageViewController new]];
      } else {
        self.navigationController.viewControllers = @[[NDAPermissionsViewController new]];
      }
    } else {
#ifdef SNAPSHOT
      [PFUser logInWithUsernameInBackground:kTestUsername password:kTestPassword block:^(PFUser *testUser, NSError *error) {
        if (!error) {
          self.navigationController.viewControllers = @[[NDAMainPageViewController new]];
        } else {
          DDLogError(@"Error occured while logging in test user: %@", error);
        }
      }];
#else
      BOOL seenWalkthrough = [[NSUserDefaults standardUserDefaults] boolForKey:kSeenWalkthroughKey];
      if (seenWalkthrough) {
        self.navigationController.viewControllers = @[[NDAAuthorizationViewController new]];
      } else {
        __weak typeof(self) weakSelf = self;
        NDAWalkthroughViewController *walkthroughViewController =
          [[NDAWalkthroughViewController alloc] initWithCompletionHandler:^{
          [weakSelf.navigationController pushViewController:[NDAAuthorizationViewController new] animated:YES];
        }];
        self.navigationController.viewControllers = @[walkthroughViewController];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kSeenWalkthroughKey];
      }
#endif /* ifdef SNAPSHOT */
    }
  }

  // Set up appearance
  [application setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
  [self setUpAppearances];
  [self.window makeKeyAndVisible];

  return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
  return [[FBSDKApplicationDelegate sharedInstance] application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  [FBSDKAppEvents activateApp];
  if (self.didEnterBackground) {
    [[NSNotificationCenter defaultCenter] postNotificationName:kRefreshNotification object:nil];
    self.didEnterBackground = NO;
  }
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  self.didEnterBackground = YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  PFInstallation *installation = [PFInstallation currentInstallation];

  [installation setDeviceTokenFromData:deviceToken];
  if ([PFUser currentUser]) {
    DDLogVerbose(@"Set the user to current installation");
    installation[kUserKey] = [PFUser currentUser];
  }
  installation.channels = @[@"global"];
  [installation saveInBackground];
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
  DDLogError(@"Error occured while registering for remote notifications: %@", err);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
  self.didEnterBackground = NO;
  if ([userInfo[kReloadKey] boolValue]) {
    DDLogVerbose(@"Received a notification to reload current meeting");
    [[NSNotificationCenter defaultCenter] postNotificationName:kReloadMeetingNotification object:nil];
  } else {
    DDLogVerbose(@"Received a notification to refresh");
    [[NSNotificationCenter defaultCenter] postNotificationName:kRefreshNotification object:nil];
  }
}

#pragma mark Private

- (void)setUpAppearances {
  [CRGradientNavigationBar appearance].translucent = NO;
  [CRGradientNavigationBar appearance].tintColor = [UIColor whiteColor];
  [[CRGradientNavigationBar appearance] setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
  [CRGradientNavigationBar appearance].shadowImage = [UIImage new];
  [CRGradientNavigationBar appearance].barTintColor = [UIColor clearColor];
  [CRGradientNavigationBar appearance].titleTextAttributes = @{
    NSFontAttributeName : [UIFont fontWithName:kRegularFontName size:[UIFont navigationBarTitleFontSize]],
    NSForegroundColorAttributeName : [UIColor whiteColor]
  };
  [[UISwitch appearance] setTintColor:[UIColor nda_accentColor]];
  [[UISwitch appearance] setOnTintColor:[UIColor nda_accentColor]];
  [[UITextField appearance] setTintColor:[UIColor nda_accentColor]];
  [[UITextView appearance] setTintColor:[UIColor nda_accentColor]];
}

@end
