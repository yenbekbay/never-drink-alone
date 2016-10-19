#import <Parse/Parse.h>

@interface NDAPreferencesObjectCell : UICollectionViewCell

#pragma mark Properties

/**
 *  Image view containing the icon that indicates whether or not the object is added by the user.
 */
@property (nonatomic, readonly) UIImageView *iconView;
/**
 *  Indicates if the object is added by the user.
 */
@property (nonatomic, getter = isAdded) BOOL added;
/**
 *  NDAInterest or NDAMeetingPlace object for which the cell is created.
 */
@property (nonatomic) PFObject *object;

#pragma mark Methods

/**
 *  Animate the cell's size decreasing when the cell is highlighted.
 */
- (void)scaleToSmall;
/**
 *  Animate the cell' size increasing and going back to normal when the cell is selected.
 */
- (void)scaleAnimation;
/**
 *  Animate the cell's size going back to normal when the cell is unhighlighted.
 */
- (void)scaleToDefault;

@end
