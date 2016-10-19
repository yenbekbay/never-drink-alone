#import <CoreLocation/CoreLocation.h>
#import <Parse/Parse.h>

/**
 *  Extends the parse class `MeetingPlace`, used to display venues in `NDAMeetingPlacesViewController`
 *  and to subsequently create meetingPlace-user pairs as one of the user's preferences.
 *
 *  @discussion The list of meeting places is fetched from Foursquare.
 */
@interface NDAMeetingPlace : PFObject<PFSubclassing>

#pragma mark Properties

/**
 *  The name (description) of the object.
 */
@property (copy, nonatomic) NSString *name;
/**
 *  Address of the meeting place loaded from Foursquare.
 */
@property (copy, nonatomic) NSString *address;
/**
 *  Location of the meeting place loaded from Foursquare.
 */
@property (nonatomic) PFGeoPoint *location;

#pragma mark Methods

/**
 *  Creates a meeting place (generally, a coffee shop) with a given name, address, and location from Foursquare.
 *
 *  @param name     String representing the name of the meeting place.
 *  @param address  String representing the address of the meeting place.
 *  @param location CLLocation object with the coordinates of the meeting place.
 *
 *  @return Newly created NDAMeetingPlace object.
 */
- (instancetype)initWithName:(NSString *)name address:(NSString *)address location:(PFGeoPoint *)location;
/**
 *  Calculates the distance from the meeting place to the user's current location.
 *
 *  @return Distance from the user's current location to the meeting place in meters.
 */
- (CLLocationDistance)distance;
/**
 *  Formats the distance to return a readable string with the distance to the meeting place in meters or in kilometers.
 *
 *  @return String with the distance to the meeting place in meters or in kilometers depending on how far
 *  the meeting place is located.
 */
- (NSString *)distanceString;
/**
 *  Returns the size of the name string if it was inside a NDAMeetingPlaceCell.
 *
 *  @return Size of the bounding box containing the name of the meeting place.
 */
- (CGSize)sizeForName;
/**
 *  Returns the size of the address string if it was inside a NDAMeetingPlaceCell.
 *
 *  @return Size of the bounding box containing the address of the meeting place.
 */
- (CGSize)sizeForAddress;
/**
 *  Width and height of a NDAPreferencesObjectCell if the object is to be placed inside it.
 *
 *  @return Size of the NDAPreferencesObjectCell with the object contents and padding around it.
 */
- (CGSize)sizeForCell;


@end
