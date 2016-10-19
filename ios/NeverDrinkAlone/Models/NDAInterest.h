#import <Parse/Parse.h>

/**
 *  Extends the parse class `Interest`, used to display interests in `NDAInterestsViewController`
 *  and to subsequently create interest-user pairs as one of the user's preferences.
 *
 *  @discussion The list of interests is imported from interests.json file.
 */
@interface NDAInterest : PFObject<PFSubclassing>

#pragma mark Properties

/**
 *  The name (description) of the object.
 */
@property (copy, nonatomic) NSString *name;
/**
 *  Contains a list of NDAInterest objects that carry interests similar or related in meaning to this one.
 */
@property (nonatomic) NSArray *similarInterests;

#pragma mark Methods

/**
 *  Creates an interest with a given name (description) and a list of similar or related interests.
 *
 *  @param name             String representing the short description of the interest.
 *  @param similarInterests Array containing a list of interests similar or related to meaning to this one.
 *
 *  @return Newly created NDAInterest object.
 */
- (instancetype)initWithName:(NSString *)name similarInterests:(NSArray *)similarInterests;
/**
 *  Width and height of a NDAPreferencesObjectCell if the object is to be placed inside it.
 *
 *  @return Size of the NDAPreferencesObjectCell with the object contents and padding around it.
 */
- (CGSize)sizeForCell;

@end
