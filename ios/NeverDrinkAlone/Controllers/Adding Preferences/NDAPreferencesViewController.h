#import "NDAIconButton.h"
#import <FSQCollectionViewAlignedLayout/FSQCollectionViewAlignedLayout.h>

@interface NDAPreferencesViewController : UIViewController <FSQCollectionViewDelegateAlignedLayout>

#pragma mark Properties

/**
 *  Scroll view that wraps everything except the continue button.
 */
@property (nonatomic) UIScrollView *scrollView;
/**
 *  Big button fixed at the bottom of the screen, allowing the user to proceed to the next screen.
 */
@property (nonatomic) NDAIconButton *continueButton;
/**
 *  Array carrying objects added by the user.
 */
@property (nonatomic) NSMutableArray *addedObjects;

#pragma mark Methods

- (void)continueToNextScreen;

@end
