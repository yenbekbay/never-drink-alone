@class NDAOnboardingViewController;

@interface NDAOnboardingContentViewController : UIViewController

#pragma mark Properties

/**
 * The parent delegate controlling the view.
 */
@property (nonatomic) NDAOnboardingViewController *delegate;
/**
 *  Color of the title label text.
 */
@property (nonatomic) UIColor *titleColor;
/**
 *  Color of the subtitle label text.
 */
@property (nonatomic) UIColor *subtitleColor;
/**
 *  Size of the title label font.
 */
@property (nonatomic) CGFloat titleFontSize;
/**
 *  Size of the subtitle label font.
 */
@property (nonatomic) CGFloat subtitleFontSize;
/**
 *  Color of the continue button.
 */
@property (nonatomic) UIColor *continueButtonColor;
/**
 *  Action that will execute before the view appears.
 */
@property (copy, nonatomic) dispatch_block_t viewWillAppearBlock;
/**
 *  Action that will execute as soon as the view appears.
 */
@property (copy, nonatomic) dispatch_block_t viewDidAppearBlock;

#pragma mark Methods

/**
 *  Create a page for onboarding view controller with given title, subtitle, and image.
 *
 *  @param titleText    The text displayed as a title under the icon image.
 *  @param subtitleText The text displayed as a smaller subtitle under the title.
 *  @param image        The image for the icon.
 *  @param showButton   Whether or not to show the button which will call the skip handler of the onboarding view controller.
 *
 *  @return Newly created onboarding content view controller.
 */
- (instancetype)initWithTitleText:(NSString *)titleText subtitleText:(NSString *)subtitleText image:(UIImage *)image showButton:(BOOL)showButton;
/**
 *  Change the alpha channel for all the elements on the page.
 *
 *  @param newAlpha The value for the new alpha.
 */
- (void)updateAlpha:(CGFloat)newAlpha;

@end
