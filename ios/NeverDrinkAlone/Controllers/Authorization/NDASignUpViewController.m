#import "NDASignUpViewController.h"

#import "JTProgressHUD.h"
#import "NDAConstants.h"
#import "PFUser+NDAHelpers.h"
#import <Analytics/Analytics.h>
#import <Parse/Parse.h>
#import <UITextField_Shake/UITextField+Shake.h>

@implementation NDASignUpViewController

#pragma mark Lifecycle

- (void)viewDidLoad {
  self.action = NSLocalizedString(@"Зарегистрироваться", nil);
  [super viewDidLoad];
}

#pragma mark Public

- (void)actionButtonTapped {
  if (self.emailTextField.text.length == 0 || self.passwordTextField.text.length == 0 || self.firstNameTextField.text.length == 0 || self.lastNameTextField.text.length == 0) {
    [self.alertManager showNotificationWithText:NSLocalizedString(@"Пожалуйста, заполните все поля", nil)];
    return;
  }
  [self.view endEditing:YES];

  PFUser *user = [PFUser user];
  user.username = self.emailTextField.text;
  user.password = self.passwordTextField.text;
  user.email = self.emailTextField.text;
  user[kUserFirstNameKey] = self.firstNameTextField.text;
  user[kUserLastNameKey] = self.lastNameTextField.text;
  [user setDefaults];
  [[SEGAnalytics sharedAnalytics] identify:user.objectId traits:@{
     kUserFirstNameKey : user[kUserFirstNameKey],
     kUserLastNameKey : user[kUserLastNameKey],
     @"email" : user.email
   }];

  [JTProgressHUD showWithTransition:JTProgressHUDTransitionFade];
  [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
    [JTProgressHUD hide];
    if (!error) {
      DDLogVerbose(@"User signed up and logged in with email");
      [self continueRegistration];
    } else {
      DDLogError(@"Error occured while signing up with email: %@", error);
      [self.alertManager showNotificationWithText:[self stringForError:error]];
      if (error.code == kPFErrorUsernameTaken || error.code == kPFErrorUserEmailTaken || error.code == kPFErrorInvalidEmailAddress) {
        [self.emailTextField shake:2 withDelta:5 speed:0.1f];
      }
    }
  }];
}

@end
