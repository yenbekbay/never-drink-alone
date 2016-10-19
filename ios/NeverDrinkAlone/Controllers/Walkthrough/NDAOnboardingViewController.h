#import "NDAOnboardingContentViewController.h"

@interface NDAOnboardingViewController : UIViewController

#pragma mark Properties

/**
 *  Contains the view controllers for the pages.
 */
@property (nonatomic) NSArray *viewControllers;
/**
 *  Currently visible content view controller.
 */
@property (nonatomic) NDAOnboardingContentViewController *currentPage;
/**
 *  Next content view controller in the queue.
 */
@property (nonatomic) NDAOnboardingContentViewController *upcomingPage;
/**
 *  The color for the background behind the view controllers.
 */
@property (nonatomic) UIColor *backgroundColor;
/**
 *  Whether or not there should be fading of the view controllers on swipe.
 */
@property (nonatomic) BOOL shouldFadeTransitions;
/**
 *  Whether or not the last page should fade away on exit.
 */
@property (nonatomic) BOOL fadePageControlOnLastPage;
/**
 *  Whether or not there should be a button that will allow skipping.
 */
@property (nonatomic) BOOL allowSkipping;
/**
 *  The action that will execute when the skip button is pressed.
 */
@property (strong, nonatomic) dispatch_block_t skipHandler;
/**
 *  Whether or not moving between pages by swiping should be allowed.
 */
@property (nonatomic) BOOL swipingEnabled;
/**
 *  Whether or not the bullets for page control should be hidden.
 */
@property (nonatomic) BOOL hidePageControl;
/**
 *  The page control of the tutorial view controller.
 */
@property (nonatomic) UIPageControl *pageControl;
/**
 *  Color for the page control background.
 */
@property (nonatomic) UIColor *pageControlColor;
/**
 *  The button which allows exiting the view.
 */
@property (nonatomic) UIButton *skipButton;
/**
 *  The text on the skip button.
 */
@property (nonatomic) NSString *skipButtonText;
/**
 *  The color of the title label text.
 */
@property (nonatomic) UIColor *titleColor;
/**
 *  The color of the subtitle label text.
 */
@property (nonatomic) UIColor *subtitleColor;
/**
 *  The size of the title label font.
 */
@property (nonatomic) CGFloat titleFontSize;
/**
 *  The size of the subtitle label font.
 */
@property (nonatomic) CGFloat subtitleFontSize;
/**
 *  The color of the button displayed on the last page.
 */
@property (nonatomic) UIColor *continueButtonColor;

#pragma mark Methods

/**
 *  Creates an onboarding view controller with the given contents.
 *
 *  @param contents Array with the view controllers for the pages.
 *
 *  @return Newly created onboarding view controller.
 */
- (instancetype)initWithContents:(NSArray *)contents;
/**
 *  Manually scrolls to the next page.
 */
- (void)moveNextPage;
/**
 *  Perform the completion handler.
 */
- (void)performCompletionHandler;

@end
