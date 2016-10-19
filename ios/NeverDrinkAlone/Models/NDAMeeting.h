#import "NDAMeetingPlace.h"
#import "NDATimeSlot.h"
#import "NDAMatch.h"
#import <Parse/Parse.h>

/**
 *  Extends the parse class `Meeting`, contains the information about the users engaged in the meeting,
 *  the venue for the meeting, and the time slot the meeting is supposed to occur at.
 */
@interface NDAMeeting : PFObject<PFSubclassing>

#pragma mark Properties

/**
 *  Match of two people engaging in the meeting
 */
@property (nonatomic) NDAMatch *match;
/**
 *  The place the meeting will be happening at.
 */
@property (nonatomic) NDAMeetingPlace *meetingPlace;
/**
 *  The time span of the meeting.
 */
@property (nonatomic) NDATimeSlot *timeSlot;

#pragma mark Methods

/**
 *  Creates a new meeting with given match, meeting place and time span.
 *
 *  @param match        Match of two users engaging in the meeting
 *  @param meetingPlace Place the meeting will be happening at.
 *  @param timeSlot     Period of time containing the starting time of the meeting.
 *
 *  @return Newly created meeting.
 */
- (instancetype)initWithMatch:(NDAMatch *)match meetingPlace:(NDAMeetingPlace *)meetingPlace timeSlot:(NDATimeSlot *)timeSlot;

@end
