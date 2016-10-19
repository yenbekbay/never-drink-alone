@interface NDAWeekdayPickerCell : UICollectionViewCell

#pragma mark Properties

/**
 *  Circular view containing the weekday label.
 */
@property (nonatomic) UIView *weekdayWrapper;
/**
 *  Label with a short string for the weekday.
 */
@property (nonatomic) UILabel *weekdayLabel;
/**
 *  The weekday number for the cell.
 */
@property (nonatomic) NSInteger weekday;
/**
 *  Range of weekdays (e.g. Mon-Fri)
 */
@property (nonatomic) NSRange range;
/**
 *  Indicates whether or not the date is currently being selected.
 */
@property (nonatomic, getter = isActive) BOOL active;

#pragma mark Methods

/**
 *  Animate the cell' size increasing and going back to normal when the cell is selected.
 */
- (void)scaleAnimation;

@end
