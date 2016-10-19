#import <Parse/Parse.h>

/**
 *  Extends the parse class `Match` and is used to represent pairs of users that are engaged in a meeting.
 */
@interface NDAMatch : PFObject<PFSubclassing>

#pragma mark Properties

/**
 *  First user in the meeting.
 */
@property (nonatomic) PFUser *firstUser;
/**
 *  Second user in the meeting.
 */
@property (nonatomic) PFUser *secondUser;
/**
 *  Contains mutual interests of two users.
 */
@property (nonatomic) NSArray *interests;

#pragma mark Methods

/**
 *  Creates a new match with given users.
 *
 *  @param firstUser    First user engaging in the meeting
 *  @param secondUser   Second user engaging in the meeting
 *  @param interests    Mutual interests of two users.
 *
 *  @return Newly created match.
 */
- (instancetype)initWithFirstUser:(PFUser *)firstUser secondUser:(PFUser *)secondUser interests:(NSArray *)interests;

@end
