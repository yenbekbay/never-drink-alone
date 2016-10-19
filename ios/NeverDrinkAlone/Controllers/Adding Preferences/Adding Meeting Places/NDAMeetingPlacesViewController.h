#import "NDASearchablePreferencesViewController.h"

@interface NDAMeetingPlacesViewController : NDASearchablePreferencesViewController

/**
 *  Trigerred by a notification, loads NDArby venues through Foursquare.
 */
- (void)locationLoaded;

@end
