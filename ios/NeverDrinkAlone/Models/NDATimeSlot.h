#import <Parse/Parse.h>

/**
 *  Extends the parse class `TimeSlot`, used to display time slots in `NDAFreeTimesViewController`
 *  and to subsequently create timeSlot-user pairs as one of the user's preferences.
 *
 *  @discussion Time slots are one hour long and are created for hours 9 to 22 for every day of the week.
 */
@interface NDATimeSlot : PFObject<PFSubclassing>

#pragma mark Properties

/**
 *  Number from 0 to 6 indicating the day of the week for the time slot (MON - SUN).
 */
@property (nonatomic) NSNumber *weekday;
/**
 *  Number from 0 to 23 indicating the hour the time slot starts at.
 */
@property (nonatomic) NSNumber *startingHour;

#pragma mark Methods

- (instancetype)initWithWeekday:(NSNumber *)weekday startingHour:(NSNumber *)startingHour;
/**
 *  Width and height of a NDAPreferencesObjectCell if the object is to be placed inside it.
 *
 *  @return Size of the NDAPreferencesObjectCell with the object contents and padding around it.
 */
- (CGSize)sizeForCell;
/**
 *  Date for the closest date matching the properties of the time slot.
 *
 *  @return Date object with weekday and starting hour same as in the time slot.
 */
- (NSDate *)date;

@end
