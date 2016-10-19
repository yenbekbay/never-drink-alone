#import "NDAOnboardingViewController.h"

@interface NDAWalkthroughViewController : NDAOnboardingViewController

/**
 *  Create a walkthrough view with an action that will execute after the exit button is tapped.
 *
 *  @param completionHandler Block which gets called when the skip button is tapped.
 *
 *  @return Newly created walthrought view controller.
 */
- (instancetype)initWithCompletionHandler:(dispatch_block_t)completionHandler;

@end
