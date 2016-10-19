#import "UIImagePickerController+NDABugFix.h"

#import "NDAConstants.h"
#import "UIColor+NDATints.h"
#import "UIFont+NDASizes.h"

@implementation UIImagePickerController (NDABugFix)

- (void)viewDidLoad {
  [super viewDidLoad];
  [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
  navigationController.navigationBar.titleTextAttributes = @{
    NSFontAttributeName : [UIFont fontWithName:kRegularFontName size:[UIFont navigationBarTitleFontSize]],
    NSForegroundColorAttributeName : [UIColor whiteColor]
  };
  navigationController.navigationBar.translucent = NO;
  navigationController.navigationBar.shadowImage = [UIImage new];
  navigationController.navigationBar.barTintColor = [UIColor nda_primaryColor];
  navigationController.navigationBar.tintColor = [UIColor whiteColor];
  [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
}

@end
