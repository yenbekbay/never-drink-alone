#import "NDANavigationController.h"

#import "NDAConstants.h"
#import "UIColor+NDATints.h"
#import "UIFont+NDASizes.h"
#import <IOSLinkedInAPI/LIALinkedInAuthorizationViewController.h>
#import <SafariServices/SafariServices.h>

@implementation NDANavigationController

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
}

- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
  if ([viewControllerToPresent isKindOfClass:[UINavigationController class]]) {
    UINavigationController *navigationController = (UINavigationController *)viewControllerToPresent;
    if ([navigationController.viewControllers[0] isKindOfClass:[LIALinkedInAuthorizationViewController class]]) {
      navigationController.navigationBar.titleTextAttributes = @{
        NSFontAttributeName : [UIFont fontWithName:kRegularFontName size:[UIFont navigationBarTitleFontSize]],
        NSForegroundColorAttributeName : [UIColor whiteColor]
      };
      navigationController.navigationBar.translucent = NO;
      navigationController.navigationBar.shadowImage = [UIImage new];
      navigationController.navigationBar.barTintColor = [UIColor nda_primaryColor];
      navigationController.navigationBar.tintColor = [UIColor whiteColor];
    }
  } else if ([viewControllerToPresent isKindOfClass:[SFSafariViewController class]] || [viewControllerToPresent.childViewControllers[0] isKindOfClass:[SFSafariViewController class]]) {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
  }
  [super presentViewController:viewControllerToPresent animated:flag completion:completion];
}

@end
