#import "NDALogInViewController.h"

#import "JLNotificationPermission.h"
#import "JTProgressHUD.h"
#import "NDAConstants.h"
#import <Analytics/Analytics.h>
#import <Parse/Parse.h>
#import <UITextField_Shake/UITextField+Shake.h>

@implementation NDALogInViewController

#pragma mark Lifecycle

- (void)viewDidLoad {
  self.action = NSLocalizedString(@"Войти", nil);
  [super viewDidLoad];
}

#pragma mark Public

- (void)actionButtonTapped {
  if (self.emailTextField.text.length == 0 || self.passwordTextField.text.length == 0) {
    [self.alertManager showNotificationWithText:NSLocalizedString(@"Пожалуйста, заполните все поля", nil)];
    return;
  }
  [self.view endEditing:YES];
  [JTProgressHUD showWithTransition:JTProgressHUDTransitionFade];
  [PFUser logInWithUsernameInBackground:self.emailTextField.text password:self.passwordTextField.text block:^(PFUser *user, NSError *logInError) {
    [JTProgressHUD hide];
    if (!logInError) {
      DDLogVerbose(@"User logged in with email");
      [[SEGAnalytics sharedAnalytics] identify:user.objectId traits:@{
         kUserFirstNameKey : user[kUserFirstNameKey],
         kUserLastNameKey : user[kUserLastNameKey],
         @"email" : user.email
       }];
      if ([[UIApplication sharedApplication] currentUserNotificationSettings].types != UIUserNotificationTypeNone) {
        [self goToDashboard];
        [[JLNotificationPermission sharedInstance] authorizeWithTitle:NSLocalizedString(@"Разрешите нам посылать вам push-уведомления", nil) message:nil cancelTitle:NSLocalizedString(@"Отказать", nil) grantTitle:NSLocalizedString(@"Разрешить", nil) completion:nil];
      } else {
        DDLogVerbose(@"Set the user to current installation");
        PFInstallation *installation = [PFInstallation currentInstallation];
        installation[kUserKey] = [PFUser currentUser];
        [installation saveEventually];
        [self goToDashboard];
      }
    } else {
      DDLogError(@"Error occured while logging in with email: %@", logInError);
      [self.alertManager showNotificationWithText:[self stringForError:logInError]];
      if (logInError.code == kPFErrorObjectNotFound || logInError.code == kPFErrorUserWithEmailNotFound) {
        [self.emailTextField shake:2 withDelta:5 speed:0.1f];
        [self.passwordTextField shake:2 withDelta:5 speed:0.1f];
      }
    }
  }];
}

@end
