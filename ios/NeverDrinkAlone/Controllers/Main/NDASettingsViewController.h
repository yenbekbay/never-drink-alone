@protocol NDASettingsViewControllerDelegate <NSObject>
@required
- (UINavigationController *)navigationController;
- (UINavigationItem *)navigationItem;
- (void)switchView;
@end

@interface NDASettingsViewController : UIViewController

/**
 * To access the parent page controller's propeties and methods.
 */
@property (assign, nonatomic) id<NDASettingsViewControllerDelegate> delegate;

@end
