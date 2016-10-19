#import "NDAMeeting.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface NDAMeetingManager : NSObject

#pragma mark Properties

/**
 *  The active meeting object for the current user.
 */
@property (nonatomic) NDAMeeting *meeting;
/**
 *  The user meeting object containing the user, the meeting, and the properties
 *  associated with the interactions of the user with the meeting.
 */
@property (nonatomic) PFObject *userMeeting;

#pragma mark Methods

/**
 *  Access the shared meeting manager object.
 *
 *  @return The shared meeting manager object.
 */
+ (instancetype)sharedInstance;
/**
 *  Retrieves the active meeting for the current user.
 */
- (RACSignal *)getMeeting;
/**
 *  Looks for the common interests for the users engaged in the active meeting.
 */
- (RACSignal *)getCommonInterests;
/**
 *  Fetches the active user meeting for the current user.
 */
- (RACSignal *)getUserMeeting;
/**
 *  Fetches all user meetings associated with the active meeting (two at most).
 */
- (RACSignal *)getUserMeetings;
/**
 *  Fetches the other user engaged in the meeting (apart from the current user).
 */
- (RACSignal *)getMeetingUser;
/**
 *  Send a signal to the server indicating that the status of the meeting has changed.
 *  @discussion The server will take appropriate actions and send the users notifications if needed.
 */
- (RACSignal *)updateMeetingStatus;
/**
 *  Call a function in the server to notify the other user engaged in the meeting of the updated meeting status.
 *  @discussed Should be called when the meeting is cancelled, for example.
 */
- (RACSignal *)notifySecondUser;
/**
 *  Save an image for the meeting (a selfie taken at the end of the meeting for example).
 *  The image will serve as proof that the meeting has happened and will result in increase of karma for both users.
 *
 *  @param image The image to save for the meeting.
 */
- (RACSignal *)saveImageForMeeting:(UIImage *)image;
/**
 *  Call a function in the server to indicate that the user has missed the active meeting.
 *
 *  @param user The user that has missed the meeting.
 */
- (RACSignal *)userMissedMeeting:(PFUser *)user;
/**
 *  Resets the active meeting and updates the info for the users engaged in the meeting.
 *  Useful when the meeting is over or a new meeting is found.
 */
- (void)resetMeeting;

@end
