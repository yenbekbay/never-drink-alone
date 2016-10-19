#import "NDAInterestsViewController.h"

#import "NDAConstants.h"
#import "NDAInterest.h"
#import "NDAInterestCell.h"
#import "NDAPreferencesObjectsList.h"
#import "PFUser+NDAHelpers.h"
#import "UIView+AYUtils.h"

@implementation NDAInterestsViewController

#pragma mark Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  self.searchBar.placeholder = NSLocalizedString(@"Искать интересы и навыки", nil);
  [self initData];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  NSString *progress = [[PFUser currentUser][kUserDidFinishRegistrationKey] boolValue] ? @"1/3" : @"3/5";
  self.navigationItem.title = [NSString localizedStringWithFormat:@"Интересы (%@)", progress];
}

#pragma mark Private

- (void)initData {
  self.loadingInProgress = YES;
  [self reloadAvailableObjectsCollectionView];
  PFQuery *interestsQuery = [NDAInterest query];
  interestsQuery.limit = 1000;
  [interestsQuery findObjectsInBackgroundWithBlock:^(NSArray *interests, NSError *error) {
    interests = [[self sortedAlphabetically:interests] mutableCopy];
    self.availableObjects = [[NDAPreferencesObjectsList alloc] initWithObjects:interests type:NDAPreferencesObjectsListInterests];
    self.searchedObjects = [[NDAPreferencesObjectsList alloc] initWithObjects:interests type:NDAPreferencesObjectsListInterests];
    self.loadingInProgress = NO;
    [self reloadAvailableObjectsCollectionView];
    [self reloadAddedObjectsCollectionView];
  }];
  [[[PFUser currentUser] getInterests] subscribeNext:^(NSArray *addedInterests) {
    self.addedObjects = [[self.addedObjects arrayByAddingObjectsFromArray:addedInterests] mutableCopy];
    [self reloadAddedObjectsCollectionView];
    [self reloadAvailableObjectsCollectionView];
  }];
  PFUser *user = [PFUser currentUser];
  if ([PFUser currentUser][kUserIndustryKey]) {
    [PFCloud callFunctionInBackground:@"getCodeForIndustry" withParameters:@{ @"industry" : user[kUserIndustryKey] } block:^(NSString *industryCode, NSError *industryCodeError) {
      if (!industryCodeError) {
        PFQuery *interestQuery = [NDAInterest query];
        [interestQuery whereKey:@"code" equalTo:industryCode];
        [interestQuery getFirstObjectInBackgroundWithBlock:^(PFObject *interestObject, NSError *interestError) {
          DDLogVerbose(@"User industry: %@", interestObject);
          self.addedObjects = [[self.addedObjects arrayByAddingObject:interestObject] mutableCopy];
          [self reloadAddedObjectsCollectionView];
          [self reloadAvailableObjectsCollectionView];
        }];
      } else {
        DDLogError(@"Error occured while getting a code for industry: %@", industryCodeError);
      }
    }];
  }
}

- (CGSize)sizeForCollectionViewWithObjects:(NSArray *)objects {
  CGSize collectionViewSize = CGSizeMake(CGRectGetWidth([UIScreen mainScreen].bounds) - kPreferencesViewPadding * 2, kPreferencesObjectCellSpacing);

  NSUInteger rows = 0;
  CGFloat currentRowWidth = 0;
  CGFloat limit = CGRectGetWidth([UIScreen mainScreen].bounds) - kPreferencesViewPadding * 2;

  for (NDAInterest *interest in objects) {
    CGFloat interestWidth = [interest sizeForCell].width + kInterestCellPadding.left;
    if (currentRowWidth == 0 || currentRowWidth + interestWidth > limit) {
      rows++;
      currentRowWidth = 10 + interestWidth;
      collectionViewSize.height += [interest sizeForCell].height + kPreferencesObjectCellSpacing;
    } else {
      currentRowWidth += interestWidth;
    }
  }

  return collectionViewSize;
}

- (void)reloadAddedObjectsCollectionView {
  self.addedObjects = [[self sortedAlphabetically:self.addedObjects] mutableCopy];
  [super reloadAddedObjectsCollectionView];
}

- (NSArray *)sortedAlphabetically:(NSArray *)objects {
  return [objects sortedArrayUsingComparator:^(NDAInterest *i1, NDAInterest *i2) {
    return [i1.name compare:i2.name];
  }];
}

#pragma mark UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
  // User typed something, check our datasource for text that looks the same
  if (searchText.length > 0) {
    // Search and reload data source
    self.searchBarActive = YES;
    NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@", searchText];
    self.searchedObjects.all = [[self.availableObjects.all filteredArrayUsingPredicate:searchPredicate] mutableCopy];
    [self.availableObjectsCollectionView reloadData];
    [self updateRefreshButton:self.searchedObjects];
    [self reloadAvailableObjectsCollectionView];
    [self fixAddedObjectsCollectionViewLayout];
  } else {
    // If there is no input, set the search bar as inactive
    self.searchBarActive = NO;
  }
}

#pragma mark UICollectionViewDataSource

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  NDAInterestCell *cell = (NDAInterestCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];

  if (!cell) {
    return nil;
  }
  cell.nameLabel.frame = CGRectMake(kInterestCellPadding.left, kInterestCellPadding.top, cell.width - kInterestCellPadding.left - kCellIconSpacing - kInterestCellCheckIconSize.width - kInterestCellPadding.right, cell.height - kInterestCellPadding.top - kInterestCellPadding.bottom);
  return cell;
}

@end
