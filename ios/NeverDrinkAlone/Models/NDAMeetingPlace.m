#import "NDAMeetingPlace.h"

#import "NDAConstants.h"
#import "NDALocationManager.h"
#import "UIFont+NDASizes.h"

@implementation NDAMeetingPlace

@dynamic name;
@dynamic address;
@dynamic location;

- (instancetype)initWithName:(NSString *)name address:(NSString *)address location:(PFGeoPoint *)location {
  self = [super init];
  if (!self) {
    return nil;
  }

  self.name = name;
  self.location = location;
  self.address = address;

  return self;
}

- (CLLocationDistance)distance {
  return [[NDALocationManager sharedInstance] distanceFromLocation:[[CLLocation alloc] initWithLatitude:self.location.latitude longitude:self.location.longitude]];
}

- (NSString *)distanceString {
  CLLocationDistance distance = [self distance];

  if (distance / 1000 < 1) {
    return [NSString stringWithFormat:NSLocalizedString(@"~%d м", @"~{distance to theatre} {meters}"), (int)(distance + 0.5)];
  } else {
    return [NSString stringWithFormat:NSLocalizedString(@"~%.2f км", @"~{distance to theatre} {kilometers}"), distance / 1000];
  }
}

- (CGSize)sizeForCell {
  CGSize nameSize = [self sizeForName];
  CGSize addressSize = [self sizeForAddress];

  return CGSizeMake(CGRectGetWidth([UIScreen mainScreen].bounds) - kPreferencesViewPadding * 2 - kPreferencesObjectCellSpacing * 2, kMeetingPlaceCellPadding.top + nameSize.height + addressSize.height + kMeetingPlaceCellPadding.bottom);
}

- (CGSize)sizeForName {
  return [self.name sizeWithAttributes:@{ NSFontAttributeName : [UIFont fontWithName:kRegularFontName size:[UIFont mediumTextFontSize]] }];
}

- (CGSize)sizeForAddress {
  NSString *address = self.address;

  if (!address) {
    address = [self distanceString];
  }
  return [address sizeWithAttributes:@{ NSFontAttributeName : [UIFont fontWithName:kItalicFontName size:[UIFont mediumTextFontSize]] }];
}

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[self class]]) {
    return NO;
  }
  NDAMeetingPlace *meetingPlace = (NDAMeetingPlace *)object;
  if ([meetingPlace isDataAvailable]) {
    PFGeoPoint *location = meetingPlace.location;
    return self.location.latitude == location.latitude && self.location.longitude == location.longitude;
  } else {
    return self == object;
  }
}

#pragma mark PFSubclassing

+ (void)load {
  [self registerSubclass];
}

+ (NSString *)parseClassName {
  return @"MeetingPlace";
}

@end
