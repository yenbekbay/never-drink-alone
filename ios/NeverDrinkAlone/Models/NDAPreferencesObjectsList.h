#import "NDAConstants.h"
#import <Parse/Parse.h>

/**
 *  Used to represent lists of interests and meeting places in the respective
 *  `NDAPreferencesBrowsingViewController`.
 */
@interface NDAPreferencesObjectsList : NSObject

#pragma mark Properties

/**
 *  Contains all the objects of the list.
 */
@property (nonatomic) NSMutableArray *all;
/**
 *  Contains the objects to be displayed in the collection view with respect to the maximum allowed number of rows.
 */
@property (nonatomic) NSMutableArray *showing;
/**
 *  Contains the object that have already been shown in the collection view.
 */
@property (nonatomic) NSMutableArray *shown;
/**
 *  The maximum allowed number of rows in the collection view displaying the showing objects of the list.
 */
@property (nonatomic) NSUInteger maxRows;
/**
 *  Indicates what type of objects the list contains.
 */
@property (nonatomic) NDAPreferencesObjectsListType type;

#pragma mark Methods

/**
 *  Creates an objects list with given objects and type.
 *
 *  @param objects Array containing either NDAInterest or NDAMeetingPlace objects.
 *  @param type    Integer indicating the type of the objects in the list.
 *
 *  @return Newly created NDAPreferencesObjectsList.
 */
- (instancetype)initWithObjects:(NSArray *)objects type:(NDAPreferencesObjectsListType)type;
/**
 *  Sets currently showing objects as shown and adds next few objects to the showing array.
 */
- (void)showOthers;
/**
 *  Removes already shown objects completely from the list.
 *
 *  @param added Array containing either NDAInterest or NDAMeetingPlace objects.
 */
- (void)removeAddedObjects:(NSArray *)added;
/**
 *  Identifies objects in the list that have not been shown yet.
 *
 *  @return Array containing either NDAInterest or NDAMeetingPlace objects.
 */
- (NSArray *)notShownObjects;
/**
 *  The number of currently showing objects.
 *
 *  @return Integer representing the number of currently showing objects (must be less than the maximum allowed).
 */
- (NSInteger)showingCount;
/**
 *  Returns the object in the showing array for the row in the given index path.
 *
 *  @param indexPath Path for the cell in a collection view.
 *
 *  @return Either NDAInterest or NDAMeetingPlace object.
 */
- (id)showingObjectForIndexPath:(NSIndexPath *)indexPath;
/**
 *  Sets all shown objects as not shown and reinitiates the cycle.
 */
- (void)reset;
/**
 *  Removes the given object completely from the list by matching the object's properties.
 *
 *  @param object Either NDAInterest or NDAMeetingPlace object.
 */
- (void)removeObject:(PFObject *)object;
/**
 *  Adds the given object to the list.
 *
 *  @param object Either NDAInterest or NDAMeetingPlace object.
 */
- (void)addObject:(PFObject *)object;

@end
