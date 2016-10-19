#import "NDAPreferencesViewController.h"

#import "NDAPreferencesObjectCell.h"
#import "NDAPreferencesObjectsList.h"

@interface NDASearchablePreferencesViewController : NDAPreferencesViewController <UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

#pragma mark Properties

/**
 *  Search bar that allows searching through interests.
 */
@property (nonatomic) UISearchBar *searchBar;
/**
 *  Boolean indicating whether or not the user is currently using the search bar.
 */
@property (nonatomic, getter = isSearchBarActive) BOOL searchBarActive;
/**
 *  Boolean indicating whether or not the results are being loaded (from Foursquare for meeting places).
 */
@property (nonatomic, getter = isLoadingInProgress) BOOL loadingInProgress;
/**
 *  Collection view that displays objects available for adding.
 *  The limit for rows is set in the NDAInterestsList class.
 *  If objects were shown once, they don't appear again after the refresh button is pressed,
 *  until no more unshown objects remain and the cycle restarts.
 */
@property (nonatomic) UICollectionView *availableObjectsCollectionView;
/**
 *  Collection view that displays objects added by the user.
 *  It first appears when the user adds at least one object and presses the refresh button.
 */
@property (nonatomic) UICollectionView *addedObjectsCollectionView;
/**
 *  When pressed, loads new interests and moves added interests to the respective collection view.
 */
@property (nonatomic) NDAIconButton *refreshButton;
/**
 *  Shown when there are no objects in the available objects list or when the search results are loading.
 */
@property (nonatomic) UILabel *nothingFoundLabel;
/**
 *  Shown when search is in progress (loading results from Foursquare for meeting places).
 */
@property (nonatomic) UIActivityIndicatorView *spinner;
/**
 *  Object that provides functionality for accessing methods associated with available objects.
 */
@property (nonatomic) NDAPreferencesObjectsList *availableObjects;
/**
 *  Object that provides functionality for accessing methods associated with the objects resulting from the search.
 */
@property (nonatomic) NDAPreferencesObjectsList *searchedObjects;

#pragma mark Methods

/**
 *  Either enables or disables the refresh button depending on the number of objects in the given objects list.
 *
 *  @param objectsList List of NDAInterest or NDAMeetingPlace objects.
 */
- (void)updateRefreshButton:(NDAPreferencesObjectsList *)objectsList;
/**
 *  Calculates the size for the collection view with given objects.
 *
 *  @param objects Array containing either NDAInterest or NDAMeetingPlace objects.
 *
 *  @return Predicted size of the collection view.
 */
- (CGSize)sizeForCollectionViewWithObjects:(NSArray *)objects;
/**
 *  Invalidates the layout and reloads the collection view of available objects.
 *  Adjusts the frames of the views with respect to the updated collection view.
 */
- (void)reloadAvailableObjectsCollectionView;
/**
 *  Invalidates the layout and reloads the collection view of added objects.
 *  Adjusts the frame of the collection view and the content size of the outer scroll view.
 */
- (void)reloadAddedObjectsCollectionView;
/**
 *  Adjusts the frame of the added objects' collection view and the content size of the outer scroll view.
 */
- (void)fixAddedObjectsCollectionViewLayout;

@end
