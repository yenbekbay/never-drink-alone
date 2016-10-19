#import "NDAMainPageViewController.h"

#import "CRGradientNavigationBar.h"
#import "NDADashboardViewController.h"
#import "NDASettingsViewController.h"
#import "UIColor+NDATints.h"
#import "UIImage+NDAHelpers.h"
#import "UIView+AYUtils.h"

@interface NDAMainPageViewController () <UIPageViewControllerDelegate, UIPageViewControllerDataSource, UIScrollViewDelegate,  NDADashboardViewControllerDelegate, NDASettingsViewControllerDelegate>

@property (nonatomic) NDADashboardViewController *dashboardViewController;
@property (nonatomic) NDASettingsViewController *settingsViewController;
@property (nonatomic) UIScrollView *pageScrollView;

@end

@implementation NDAMainPageViewController

#pragma mark Initialization

- (instancetype)init {
  self = [super initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
  if (!self) {
    return nil;
  }

  self.delegate = self;
  self.dataSource = self;

  return self;
}

#pragma mark Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor nda_spaceGrayColor];
  self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
  self.dashboardViewController = [NDADashboardViewController new];
  self.dashboardViewController.delegate = self;
  self.settingsViewController = [NDASettingsViewController new];
  self.settingsViewController.delegate = self;
  self.currentPageIndex = 1;
  [self syncScrollView];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.navigationController.navigationBarHidden = NO;
  [(CRGradientNavigationBar *)self.navigationController.navigationBar setBarTintGradientColors:@[
     [UIColor clearColor],
     [UIColor clearColor]
   ]];
  self.navigationController.navigationBar.barTintColor = [UIColor nda_spaceGrayColor];
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  self.navigationController.navigationBar.barTintColor = [UIColor clearColor];
}

#pragma mark Public

- (void)switchView {
  __weak __typeof(& *self) weakSelf = self;
  if (self.currentPageIndex == 0) {
    [self setViewControllers:@[self.dashboardViewController] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:^(BOOL complete) {
      __strong __typeof(&*weakSelf) strongSelf = weakSelf;
      if (complete && strongSelf) {
        [strongSelf updateCurrentPageIndex:1];
      }
    }];
  } else {
    [self setViewControllers:@[self.settingsViewController] direction:UIPageViewControllerNavigationDirectionReverse animated:YES completion:^(BOOL complete) {
      __strong __typeof(&*weakSelf) strongSelf = weakSelf;
      if (complete && strongSelf) {
        [strongSelf updateCurrentPageIndex:0];
      }
    }];
  }
}

- (void)updateCurrentPageIndex:(NSUInteger)currentPageIndex {
  _currentPageIndex = currentPageIndex;
}

#pragma mark Private

- (void)syncScrollView {
  for (UIView *view in self.view.subviews) {
    if ([view isKindOfClass:[UIScrollView class]]) {
      self.pageScrollView = (UIScrollView *)view;
      self.pageScrollView.delegate = self;
    }
  }
}

#pragma mark Setters

- (void)setCurrentPageIndex:(NSUInteger)currentPageIndex {
  _currentPageIndex = currentPageIndex;
  [self setViewControllers:@[@[self.settingsViewController, self.dashboardViewController][_currentPageIndex]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
  if ([viewController isKindOfClass:[NDASettingsViewController class]]) {
    return nil;
  }
  return self.settingsViewController;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
  if ([viewController isKindOfClass:[NDADashboardViewController class]]) {
    return nil;
  }
  return self.dashboardViewController;
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {
  if (completed) {
    _currentPageIndex = (NSUInteger)[self indexOfController:[pageViewController.viewControllers lastObject]];
  }
}

- (NSInteger)indexOfController:(UIViewController *)viewController {
  if ([viewController isKindOfClass:[NDASettingsViewController class]]) {
    return 0;
  } else {
    return 1;
  }
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  if (_currentPageIndex == 0 && scrollView.contentOffset.x < scrollView.width) {
    scrollView.contentOffset = CGPointMake(scrollView.width, 0);
  }
  if (_currentPageIndex == 1 && scrollView.contentOffset.x > scrollView.width) {
    scrollView.contentOffset = CGPointMake(scrollView.width, 0);
  }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity
  targetContentOffset:(inout CGPoint *)targetContentOffset {
  if (_currentPageIndex == 0 && scrollView.contentOffset.x <= scrollView.width) {
    *targetContentOffset = CGPointMake(scrollView.width, 0);
  }
  if (_currentPageIndex == 1 && scrollView.contentOffset.x >= scrollView.width) {
    *targetContentOffset = CGPointMake(scrollView.width, 0);
  }
}

@end
