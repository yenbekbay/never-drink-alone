#import "NDASearchablePreferencesViewController.h"

#import "DAKeyboardControl.h"
#import "NDAConstants.h"
#import "NDAIconButton.h"
#import "NDAInterest.h"
#import "NDAInterestCell.h"
#import "NDAInterestsViewController.h"
#import "NDAMeetingPlace.h"
#import "NDAMeetingPlaceCell.h"
#import "NDAMeetingPlacesViewController.h"
#import "NDAPreferencesObjectCell.h"
#import "UIColor+NDATints.h"
#import "UIFont+NDASizes.h"
#import "UIImage+NDAHelpers.h"
#import "UIView+AYUtils.h"
#import <FSQCollectionViewAlignedLayout/FSQCollectionViewAlignedLayout.h>

@implementation NDASearchablePreferencesViewController

#pragma mark Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setUpSearchBar];
  [self setUpCollectionViews];
  [self setUpRefreshButton];
  self.addedObjects = [NSMutableArray new];
}

#pragma mark Private

- (void)setUpSearchBar {
  self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(kPreferencesViewPadding, kSearchBarTopMargin, self.view.width - kPreferencesViewPadding * 2, kSearchBarHeight)];
  self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
  self.searchBar.tintColor = [UIColor nda_darkGrayColor];
  self.searchBar.barTintColor = [UIColor nda_lightGrayColor];
  self.searchBar.delegate = self;
  [self.searchBar setImage:[[UIImage imageNamed:@"SearchIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
  [[UIImageView appearanceWhenContainedIn:[UISearchBar class], nil] setTintColor:[UIColor nda_darkGrayColor]];

  UITextField *searchField = [self.searchBar valueForKey:@"_searchField"];
  searchField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Искать интересы и навыки", nil) attributes:@{ NSForegroundColorAttributeName : [UIColor nda_darkGrayColor] }];
  searchField.textColor = [UIColor nda_textColor];
  searchField.font = [UIFont fontWithName:kRegularFontName size:[UIFont smallTextFontSize]];

  [self.scrollView addSubview:self.searchBar];

  self.view.keyboardTriggerOffset = kKeyboardTriggerOffset;
  [self.view addKeyboardPanningWithFrameBasedActionHandler:nil constraintBasedActionHandler:nil];
}

- (void)setUpCollectionViews {
  FSQCollectionViewAlignedLayout *availableObjectsCollectionViewLayout = [FSQCollectionViewAlignedLayout new];

  self.availableObjectsCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(kPreferencesViewPadding, self.searchBar.bottom + kPreferencesCollectionViewTopMargin - 15 / 2, 0, 0) collectionViewLayout:availableObjectsCollectionViewLayout];

  FSQCollectionViewAlignedLayout *addedObjectsCollectionViewLayout = [FSQCollectionViewAlignedLayout new];
  self.addedObjectsCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(kPreferencesViewPadding, self.availableObjectsCollectionView.bottom + kRefreshButtonTopMargin + kRefreshButtonSize.height + kPreferencesCollectionViewTopMargin, 0, 0) collectionViewLayout:addedObjectsCollectionViewLayout];

  for (UICollectionView *collectionView in @[self.availableObjectsCollectionView, self.addedObjectsCollectionView]) {
    collectionView.dataSource = self;
    collectionView.delegate = self;
    collectionView.backgroundColor = [UIColor whiteColor];
    if ([self class] == [NDAInterestsViewController class]) {
      [collectionView registerClass:[NDAInterestCell class] forCellWithReuseIdentifier:kPreferencesObjectCellReuseIdentifier];
    } else {
      [collectionView registerClass:[NDAMeetingPlaceCell class] forCellWithReuseIdentifier:kPreferencesObjectCellReuseIdentifier];
    }
  }

  self.nothingFoundLabel = [[UILabel alloc] initWithFrame:CGRectMake(kPreferencesViewPadding, self.availableObjectsCollectionView.top, self.view.width - kPreferencesViewPadding * 2, 30)];
  self.nothingFoundLabel.text = NSLocalizedString(@"К сожалению, ничего не найдено", nil);
  self.nothingFoundLabel.textColor = [UIColor nda_darkGrayColor];
  self.nothingFoundLabel.font = [UIFont fontWithName:kRegularFontName size:[UIFont mediumTextFontSize]];
  self.nothingFoundLabel.textAlignment = NSTextAlignmentCenter;
  self.nothingFoundLabel.hidden = YES;

  self.spinner = [[UIActivityIndicatorView alloc] initWithFrame:self.nothingFoundLabel.frame];
  self.spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;

  [self.scrollView addSubview:self.availableObjectsCollectionView];
  [self.scrollView addSubview:self.addedObjectsCollectionView];
  [self.scrollView addSubview:self.nothingFoundLabel];
  [self.scrollView addSubview:self.spinner];
}

- (void)setUpRefreshButton {
  self.refreshButton = [[NDAIconButton alloc] initWithFrame:CGRectMake((self.view.width - kRefreshButtonSize.width) / 2, self.availableObjectsCollectionView.bottom + kRefreshButtonTopMargin, kRefreshButtonSize.width, kRefreshButtonSize.height)];
  self.refreshButton.adjustsImageWhenHighlighted = NO;
  self.refreshButton.layer.cornerRadius = kMediumButtonCornerRadius;
  self.refreshButton.clipsToBounds = YES;
  [self.refreshButton setTitle:NSLocalizedString(@"Показать другие", nil) forState:UIControlStateNormal];
  self.refreshButton.titleLabel.font = [UIFont fontWithName:kRegularFontName size:[UIFont mediumButtonFontSize]];
  [self.refreshButton setTitleColor:[UIColor nda_primaryColor] forState:UIControlStateNormal];
  [self.refreshButton setImage:[[UIImage imageNamed:@"RefreshIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
  self.refreshButton.tintColor = [UIColor nda_primaryColor];
  [self.refreshButton addTarget:self action:@selector(refresh) forControlEvents:UIControlEventTouchUpInside];
  [self.refreshButton setBackgroundImage:[UIImage imageWithColor:[UIColor nda_lightGrayColor]] forState:UIControlStateHighlighted];

  [self.scrollView addSubview:self.refreshButton];
}

- (void)refresh {
  if (self.isSearchBarActive) {
    [self.searchedObjects showOthers];
    [self updateRefreshButton:self.searchedObjects];
  } else {
    if (self.availableObjects.notShownObjects.count <= 0) {
      [self.availableObjects reset];
    } else {
      [self.availableObjects showOthers];
    }
  }
  [self reloadAvailableObjectsCollectionView];
  [self reloadAddedObjectsCollectionView];
}

#pragma mark Public

- (void)updateRefreshButton:(NDAPreferencesObjectsList *)objectsList {
  if (objectsList.notShownObjects.count <= 0) {
    [self setRefreshButtonEnabled:NO];
  } else {
    [self setRefreshButtonEnabled:YES];
  }
}

- (CGSize)sizeForCollectionViewWithObjects:(NSArray *)objects {
  return CGSizeZero;
}

- (void)reloadAvailableObjectsCollectionView {
  [self.availableObjectsCollectionView.collectionViewLayout invalidateLayout];
  [self.availableObjectsCollectionView reloadData];

  NDAPreferencesObjectsList *objectsList = self.isSearchBarActive ? self.searchedObjects : self.availableObjects;
  if (self.isLoadingInProgress) {
    self.nothingFoundLabel.hidden = YES;
    [self.spinner startAnimating];
    self.availableObjectsCollectionView.size = self.spinner.size;
  } else {
    if (objectsList.showingCount > 0) {
      self.nothingFoundLabel.hidden = YES;
      self.availableObjectsCollectionView.size = [self sizeForCollectionViewWithObjects:objectsList.showing];
    } else {
      self.nothingFoundLabel.hidden = NO;
      self.availableObjectsCollectionView.size = self.nothingFoundLabel.size;
    }
  }
  self.refreshButton.top = self.availableObjectsCollectionView.bottom + kRefreshButtonTopMargin;
}

- (void)reloadAddedObjectsCollectionView {
  [self.addedObjectsCollectionView.collectionViewLayout invalidateLayout];
  [self.addedObjectsCollectionView reloadData];

  [self fixAddedObjectsCollectionViewLayout];
}

- (void)fixAddedObjectsCollectionViewLayout {
  self.addedObjectsCollectionView.top = self.availableObjectsCollectionView.bottom + kRefreshButtonTopMargin + kRefreshButtonSize.height + kPreferencesCollectionViewTopMargin;
  self.addedObjectsCollectionView.size = [self sizeForCollectionViewWithObjects:self.addedObjects];

  self.scrollView.contentSize = CGSizeMake(self.view.width, self.addedObjectsCollectionView.bottom + kPreferencesViewPadding);
}

#pragma mark Setters

- (void)setRefreshButtonEnabled:(BOOL)enabled {
  self.refreshButton.enabled = enabled;
  self.refreshButton.alpha = enabled ? 1 : 0.5f;
}

- (void)setLoadingInProgress:(BOOL)loadingInProgress {
  _loadingInProgress = loadingInProgress;
  if (!self.isLoadingInProgress) {
    [self.spinner stopAnimating];
  }
}

#pragma mark UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
  self.searchBarActive = NO;
  [self.searchBar resignFirstResponder];
  self.searchBar.text  = @"";
  self.searchedObjects.all = nil;
  [self setRefreshButtonEnabled:YES];
  [self.availableObjects removeAddedObjects:self.addedObjects];
  [self reloadAvailableObjectsCollectionView];
  [self reloadAddedObjectsCollectionView];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
  [self.view endEditing:YES];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
  [self.searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
  // This method gets called when the Search button on the keyboard is pressed
  [self.searchBar setShowsCancelButton:NO animated:YES];
}

#pragma mark UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
  return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  if (collectionView == self.availableObjectsCollectionView) {
    if (self.isSearchBarActive) {
      return [self.searchedObjects showingCount];
    } else {
      return [self.availableObjects showingCount];
    }
  } else {
    return (NSInteger)self.addedObjects.count;
  }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath remainingLineSpace:(CGFloat)remainingLineSpace {
  PFObject *object;

  if (collectionView == self.availableObjectsCollectionView) {
    if (self.isSearchBarActive) {
      object = [self.searchedObjects showingObjectForIndexPath:indexPath];
    } else {
      object = [self.availableObjects showingObjectForIndexPath:indexPath];
    }
  } else {
    object = self.addedObjects[(NSUInteger)indexPath.row];
  }
  CGSize sizeForCell;
  if ([object isKindOfClass:[NDAInterest class]]) {
    sizeForCell = [(NDAInterest *)object sizeForCell];
  } else if ([object isKindOfClass:[NDAMeetingPlace class]]) {
    sizeForCell = [(NDAMeetingPlace *)object sizeForCell];
  }
  return sizeForCell;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  NDAPreferencesObjectCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kPreferencesObjectCellReuseIdentifier forIndexPath:indexPath];

  if (cell) {
    if (collectionView == self.availableObjectsCollectionView) {
      if (self.isSearchBarActive) {
        cell.object = [self.searchedObjects showingObjectForIndexPath:indexPath];
      } else {
        cell.object = [self.availableObjects showingObjectForIndexPath:indexPath];
      }
      cell.added = [self.addedObjects containsObject:cell.object];
    } else {
      cell.object = self.addedObjects[(NSUInteger)indexPath.row];
      cell.added = YES;
    }
  }
  return cell;
}

#pragma mark UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  NDAPreferencesObjectCell *cell = (NDAPreferencesObjectCell *)[collectionView cellForItemAtIndexPath:indexPath];
  [cell scaleAnimation];
  cell.added = !cell.isAdded;
  if (cell.isAdded) {
    [self.addedObjects addObject:cell.object];
    [self.searchedObjects removeObject:cell.object];
    [self.availableObjects removeObject:cell.object];
  } else {
    [self.addedObjects removeObject:cell.object];
    if (self.isSearchBarActive && collectionView != self.addedObjectsCollectionView) {
      [self.searchedObjects addObject:cell.object];
    } else {
      [self.availableObjects addObject:cell.object];
    }
  }
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
  NDAPreferencesObjectCell *cell = (NDAPreferencesObjectCell *)[collectionView cellForItemAtIndexPath:indexPath];
  [cell scaleToSmall];
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
  NDAPreferencesObjectCell *cell = (NDAPreferencesObjectCell *)[collectionView cellForItemAtIndexPath:indexPath];
  [cell scaleToDefault];
}

@end
