#import "NDAPreferencesViewController.h"
#import <Foundation/Foundation.h>

/**
 *  Providese an interface for managing preferences for the user.
 */
@interface NDAPreferencesManager : NSObject

#pragma mark Properties

/**
 *  The first add preferences view controller for easy access.
 */
@property (weak, nonatomic) NDAPreferencesViewController *firstViewController;
/**
 *  Add preferences view controller currently visible in the navigation controller.
 */
@property (weak, nonatomic) NDAPreferencesViewController *currentViewController;

#pragma mark Methods

/**
 *  Access the shared add preferences manager object.
 *
 *  @return The shared add preferences manager object.
 */
+ (instancetype)sharedInstance;
/**
 *  Show the next add preferences view controller with the given navigation controller.
 *
 *  @param navigationController Navigation controller to push the view controller in.
 */
- (void)pushNextViewController:(UINavigationController *)navigationController;

@end
