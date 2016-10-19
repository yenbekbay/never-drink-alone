#import <CoreLocation/CoreLocation.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

/**
 * Provides an interface for getting current location and calculating distances.
 */
@interface NDALocationManager : NSObject <CLLocationManagerDelegate>

#pragma mark Methods

/**
 *  Access the shared location manager object.
 *
 *  @return The shared location manager object.
 */
+ (NDALocationManager *)sharedInstance;
/**
 *  Performs a request to get the current location and throws a notification as soon as response is received.
 */
- (RACSignal *)getCurrentLocation;
/**
 *  Calculates the distance from the given location to the currnet location.
 *
 *  @param location Location to calculate the distance to.
 *
 *  @return Distance from the current location to the given location.
 */
- (CLLocationDistance)distanceFromLocation:(CLLocation *)location;

#pragma mark Properties

/**
 *  Current geographical location of the user.
 */
@property (nonatomic) CLLocation *currentLocation;

@end
