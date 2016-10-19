#import <AMPopTip/AMPopTip.h>

@protocol NDADashboardViewControllerDelegate <NSObject>
@required
- (UINavigationController *)navigationController;
- (UINavigationItem *)navigationItem;
- (void)switchView;
@end

@interface NDADashboardViewController : UIViewController

/**
 * To access the parent page controller's propeties and methods.
 */
@property (assign, nonatomic) id<NDADashboardViewControllerDelegate> delegate;

@end
