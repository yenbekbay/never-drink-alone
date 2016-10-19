#import "NDALocationManager.h"

#import "CLLocation+NDAHelpers.h"
#import "LMGeocoder.h"
#import "NDAConstants.h"
#import "NDAMacros.h"

@interface NDALocationManager ()

/**
 *  Provides methods for getting the current location.
 */
@property (nonatomic) CLLocationManager *locationManager;

@end

@implementation NDALocationManager

#pragma mark Initialization

- (instancetype)init {
  self = [super init];
  if (!self) {
    return nil;
  }

  self.locationManager = [CLLocationManager new];
  self.locationManager.delegate = self;
  self.locationManager.distanceFilter = kCLDistanceFilterNone;
  self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;

  return self;
}

+ (NDALocationManager *)sharedInstance {
  static NDALocationManager *sharedInstance = nil;
  static dispatch_once_t oncePredicate;
  dispatch_once(&oncePredicate, ^{
    sharedInstance = [NDALocationManager new];
  });
  return sharedInstance;
}

#pragma mark Public

- (CLLocationDistance)distanceFromLocation:(CLLocation *)location {
  if (!self.currentLocation) {
    return -1;
  }
  return [self.currentLocation distanceFromLocation:location];
}

- (RACSignal *)getCurrentLocation {
  if (self.currentLocation) {
    return [RACSignal return :self.currentLocation];
  }
  CLLocation *almaty = [[CLLocation alloc] initWithLatitude:kAlmatyCoordinatesLatitude longitude:kAlmatyCoordinatesLongitude];

  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    [[[[self requestWhenInUseAuthorization] then:^RACSignal *{
      return [self updateCurrentLocation];
    }] catchTo:[RACSignal return :almaty]] subscribeNext:^(CLLocation *location) {
      if (location == almaty) {
        self.currentLocation = location;
        [subscriber sendNext:self.currentLocation];
        [subscriber sendCompleted];
        return;
      }
      [[LMGeocoder sharedInstance] reverseGeocodeCoordinate:location.coordinate service:kLMGeocoderGoogleService completionHandler:^(NSArray *results, NSError *error) {
        LMAddress *address = results[0];
        if (address && !error) {
          if (![address.locality isEqualToString:@"Almaty"]) {
            self.currentLocation = almaty;
          } else {
            self.currentLocation = location;
          }
        } else {
          self.currentLocation = almaty;
        }
        [subscriber sendNext:self.currentLocation];
        [subscriber sendCompleted];
      }];
    }];
    return nil;
  }];
}

#pragma mark Private

- (RACSignal *)requestWhenInUseAuthorization {
  if (TARGET_IPHONE_SIMULATOR) {
    return [RACSignal return :@YES];
  }
  if ([self needsAuthorization]) {
    [self.locationManager requestWhenInUseAuthorization];
    return [self didAuthorize];
  } else {
    return [self authorized];
  }
}

- (RACSignal *)updateCurrentLocation {
  if (TARGET_IPHONE_SIMULATOR) {
    return [RACSignal return :[[CLLocation alloc] initWithLatitude:43.2775f longitude:76.8958f]];
  }

  RACSignal *currentLocationUpdated = [[[self didUpdateLocations] map:^id (NSArray *locations) {
    return locations.lastObject;
  }] filter:^BOOL (CLLocation *location) {
    return !location.isStale;
  }];

  RACSignal *locationUpdateFailed = [[[self didFailWithError] map:^id (NSError *error) {
    return [RACSignal error:error];
  }] switchToLatest];

  return [[[[RACSignal merge:@[currentLocationUpdated, locationUpdateFailed]] take:1] initially:^{
    [self.locationManager startUpdatingLocation];
  }] finally:^{
    [self.locationManager stopUpdatingLocation];
  }];
}

- (BOOL)authorizationStatusEqualTo:(CLAuthorizationStatus)status {
  return [CLLocationManager authorizationStatus] == status;
}

- (BOOL)needsAuthorization {
  return [self authorizationStatusEqualTo:kCLAuthorizationStatusNotDetermined];
}

- (RACSignal *)didAuthorize {
  return [[[[self didChangeAuthorizationStatus] ignore:@(kCLAuthorizationStatusNotDetermined)] map:^id (NSNumber *status) {
    return @(status.integerValue == kCLAuthorizationStatusAuthorizedWhenInUse);
  }] take:1];
}

- (RACSignal *)authorized {
  BOOL authorized = [self authorizationStatusEqualTo:kCLAuthorizationStatusAuthorizedWhenInUse] || [self authorizationStatusEqualTo:kCLAuthorizationStatusAuthorizedAlways];

  return [RACSignal return :@(authorized)];
}

#pragma mark CLLocationManagerDelegate

- (RACSignal *)didUpdateLocations {
  return [[self rac_signalForSelector:@selector(locationManager:didUpdateLocations:) fromProtocol:@protocol(CLLocationManagerDelegate)] reduceEach:^id (CLLocationManager *manager, NSArray *locations) {
    return locations;
  }];
}

- (RACSignal *)didFailWithError {
  return [[self rac_signalForSelector:@selector(locationManager:didFailWithError:) fromProtocol:@protocol(CLLocationManagerDelegate)] reduceEach:^id (CLLocationManager *manager, NSError *error) {
    return error;
  }];
}

- (RACSignal *)didChangeAuthorizationStatus {
  return [[self rac_signalForSelector:@selector(locationManager:didChangeAuthorizationStatus:) fromProtocol:@protocol(CLLocationManagerDelegate)] reduceEach:^id (CLLocationManager *manager, NSNumber *status) {
    return status;
  }];
}

@end
