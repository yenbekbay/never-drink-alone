#import <Parse/Parse.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface PFUser (NDAHelpers)

@property (nonatomic) UIImage *profilePictureImage;

/**
 *  Returns full name of the user in the format "<first name> <last name>"
 *
 *  @return Full name of the user
 */
- (NSString *)fullName;
/**
 *  Set the default configuration to the user.
 */
- (void)setDefaults;
/**
 *  Retrieves the profile picture for the user. The image can be stored in Parse either as an image file or as a url
 *  to the image.
 */
- (RACSignal *)getProfilePicture;
/**
 *  Saves the image as a profile picture for the user.
 *
 *  @param image Image to save as a profile picture.
 */
- (RACSignal *)saveProfilePicture:(UIImage *)image;
/**
 *  Performs a transaction of karma for the user with the given amount and description.
 *
 *  @param amount      The amount of points to add or to subtract from the user's current karma.
 *  @param description The description (explanation) for the transaction.
 */
- (RACSignal *)karmaTransactionWithAmount:(NSNumber *)amount description:(NSString *)description;
/**
 *  Fetches the interests for the current user.
 */
- (RACSignal *)getInterests;
/**
 *  Fetches the meeting places for the current user.
 *
 *  @param completionBlock Block to execute when the meeting places are fetched or an error occurs.
 */
- (RACSignal *)getMeetingPlaces;
/**
 *  Fetched the time slots (free times) for the current user.
 */
- (RACSignal *)getTimeSlots;
/**
 *  Removes all data associated with current user. Useful when resetting the user.
 */
- (void)clearCache;

@end
