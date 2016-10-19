#import "NDAMeetingPlacesViewController.h"

#import "Foursquare2.h"
#import "NDAConstants.h"
#import "NDALocationManager.h"
#import "NDAMeetingPlace.h"
#import "NDAMeetingPlaceCell.h"
#import "NDAPreferencesObjectsList.h"
#import "PFUser+NDAHelpers.h"
#import "UIView+AYUtils.h"
#import <Parse/Parse.h>

@implementation NDAMeetingPlacesViewController

#pragma mark Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  self.searchBar.placeholder = NSLocalizedString(@"Искать любимые места", nil);
  [self reloadAvailableObjectsCollectionView];
  [[[PFUser currentUser] getMeetingPlaces] subscribeNext:^(NSArray *addedMeetingPlaces) {
    self.addedObjects = [addedMeetingPlaces mutableCopy];
    [self reloadAddedObjectsCollectionView];
    [self reloadAvailableObjectsCollectionView];
  }];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  NSString *progress = [[PFUser currentUser][kUserDidFinishRegistrationKey] boolValue] ? @"2/3" : @"4/5";
  self.navigationItem.title = [NSString localizedStringWithFormat:@"Любимые места (%@)", progress];
}

#pragma mark Public

- (void)locationLoaded {
  CLLocation *location = [[NDALocationManager sharedInstance] currentLocation];

  [Foursquare2 venueSearchNearByLatitude:@(location.coordinate.latitude) longitude:@(location.coordinate.longitude) query:nil limit:nil intent:intentBrowse radius:@(kMeetingPlacesNDArbyRadius) categoryId:[@[kFoursquareCoffeeShopId, kFoursquareFoodId] componentsJoinedByString : @","] callback:^(BOOL success, id result) {
    if (success) {
      NSDictionary *dictionary = result;
      NSArray *venues = dictionary[@"response"][@"venues"];
      self.availableObjects = [[NDAPreferencesObjectsList alloc] initWithObjects:[self sortedByDistance:[self convertFoursquareVenues:venues]] type:NDAPreferencesObjectsListMeetingPlaces];
      self.loadingInProgress = NO;
      [self reloadAvailableObjectsCollectionView];
    }
  }];
}

#pragma mark Private

- (NSArray *)convertFoursquareVenues:(NSArray *)rawVenues {
  NSMutableArray *meetingPlaces = [NSMutableArray new];
  for (NSDictionary *venue  in rawVenues) {
    NSString *name = venue[@"name"];
    NSString *address = venue[@"location"][@"address"];
    PFGeoPoint *location = [PFGeoPoint geoPointWithLatitude:[venue[@"location"][@"lat"] doubleValue] longitude:[venue[@"location"][@"lng"] doubleValue]];
    NDAMeetingPlace *meetingPlace = [[NDAMeetingPlace alloc] initWithName:name address:address location:location];
    [meetingPlaces addObject:meetingPlace];
  }
  return meetingPlaces;
}

- (CGSize)sizeForCollectionViewWithObjects:(NSArray *)objects {
  CGSize collectionViewSize = CGSizeMake(self.view.width - kPreferencesViewPadding * 2, kPreferencesObjectCellSpacing);

  for (NDAMeetingPlace *meetingPlace in objects) {
    collectionViewSize.height += [meetingPlace sizeForCell].height + kPreferencesObjectCellSpacing;
  }
  return collectionViewSize;
}

- (void)reloadAvailableObjectsCollectionView {
  self.availableObjects.showing = [[self sortedByDistance:self.availableObjects.showing] mutableCopy];
  [super reloadAvailableObjectsCollectionView];
}

- (void)reloadAddedObjectsCollectionView {
  self.addedObjects = [[self sortedByDistance:self.addedObjects] mutableCopy];;
  [super reloadAddedObjectsCollectionView];
}

- (NSArray *)sortedByDistance:(NSArray *)objects {
  return [objects sortedArrayUsingComparator:^(NDAMeetingPlace *i1, NDAMeetingPlace *i2) {
    CLLocationDistance distance1 = i1.distance;
    CLLocationDistance distance2 = i2.distance;
    if (distance1 < distance2) {
      return NSOrderedAscending;
    } else if (distance1 > distance2) {
      return NSOrderedDescending;
    } else {
      return NSOrderedSame;
    }
  }];
}

#pragma mark UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
  if (!self.searchedObjects) {
    self.searchedObjects = [[NDAPreferencesObjectsList alloc] initWithObjects:nil type:NDAPreferencesObjectsListMeetingPlaces];
  } else {
    self.searchedObjects.all = nil;
  }
  // User typed something, check our datasource for text that looks the same
  if (searchText.length > 0) {
    self.searchBarActive = YES;
    self.loadingInProgress = YES;
    [self reloadAvailableObjectsCollectionView];
    CLLocation *location = nil;
    if ([[NDALocationManager sharedInstance] currentLocation]) {
      location = [[NDALocationManager sharedInstance] currentLocation];
    }
    // Search and reload data source
    [Foursquare2 venueSearchNearByLatitude:@(location.coordinate.latitude) longitude:@(location.coordinate.longitude) query:[searchText stringByReplacingOccurrencesOfString:@" " withString:@"%20"] limit:nil intent:intentBrowse radius:@(kMeetingPlacesCityRadius) categoryId:[@[kFoursquareCoffeeShopId, kFoursquareFoodId] componentsJoinedByString : @","] callback:^(BOOL success, id result) {
      if (success) {
        NSDictionary *dictionary = result;
        NSArray *venues = dictionary[@"response"][@"venues"];
        NSArray *convertedVenues = [self convertFoursquareVenues:venues];
        self.searchedObjects.all = [[convertedVenues filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL (id object, NSDictionary *bindings) {
          return ![self.addedObjects containsObject:object];
        }]] mutableCopy];
        self.loadingInProgress = NO;
        [self.availableObjectsCollectionView reloadData];
        [self updateRefreshButton:self.searchedObjects];
        [self reloadAvailableObjectsCollectionView];
        [self fixAddedObjectsCollectionViewLayout];
      }
    }];
  } else {
    // If there is no input, set the search bar as inactive
    self.searchBarActive = NO;
  }
}

#pragma mark UICollectionViewDataSource

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  NDAMeetingPlaceCell *cell = (NDAMeetingPlaceCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
  if (cell) {
    cell.nameLabel.frame = CGRectMake(kMeetingPlaceCellPadding.left, kMeetingPlaceCellPadding.top, cell.width - kMeetingPlaceCellPadding.left - kCellIconSpacing - kMeetingPlaceCellCheckIconSize.width - kMeetingPlaceCellPadding.right, [(NDAMeetingPlace *)cell.object sizeForName].height);
    cell.addressLabel.frame = CGRectMake(kMeetingPlaceCellPadding.left, kMeetingPlaceCellPadding.top + cell.nameLabel.height, cell.nameLabel.width, [(NDAMeetingPlace *)cell.object sizeForAddress].height);
  }
  return cell;
}

@end
