#import "NDAPreferencesViewController.h"

#import "CRGradientNavigationBar.h"
#import "NDAConstants.h"
#import "NDAPreferencesManager.h"
#import "UIColor+NDAHelpers.h"
#import "UIColor+NDATints.h"
#import "UIFont+NDASizes.h"
#import "UIImage+NDAHelpers.h"
#import "UIView+AYUtils.h"

@implementation NDAPreferencesViewController

#pragma mark Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
  [self setUpScrollView];
  [self setUpContinueButton];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.navigationController.navigationBarHidden = NO;
  [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
  [(CRGradientNavigationBar *)self.navigationController.navigationBar setBarTintGradientColors:@[
     [UIColor nda_primaryColor],
     [UIColor nda_complementaryColor]
   ]];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
  return UIStatusBarStyleLightContent;
}

#pragma mark Private

- (void)setUpScrollView {
  self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, self.view.height - kBigButtonHeight)];
  self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
  self.scrollView.backgroundColor = [UIColor whiteColor];
  [self.view addSubview:self.scrollView];
}

- (void)setUpContinueButton {
  self.continueButton = [[NDAIconButton alloc] initWithFrame:CGRectMake(0, self.scrollView.bottom, self.view.width, kBigButtonHeight)];
  self.continueButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
  self.continueButton.adjustsImageWhenHighlighted = NO;
  [self.continueButton setTitle:[self titleForContinueButton] forState:UIControlStateNormal];
  self.continueButton.titleLabel.font = [UIFont fontWithName:kLightFontName size:[UIFont bigButtonFontSize]];
  [self.continueButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  [self.continueButton setImage:[[UIImage imageNamed:@"ArrowIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
  self.continueButton.tintColor = [UIColor whiteColor];
  [self.continueButton addTarget:self action:@selector(continueToNextScreen) forControlEvents:UIControlEventTouchUpInside];
  [self.continueButton setBackgroundImage:[UIImage imageWithColor:[UIColor nda_greenColor]] forState:UIControlStateNormal];
  [self.continueButton setBackgroundImage:[UIImage imageWithColor:[[UIColor nda_greenColor] darkerColor:0.1f]] forState:UIControlStateHighlighted];

  [self.view addSubview:self.continueButton];
}

- (NSString *)titleForContinueButton {
  return NSLocalizedString(@"Дальше", nil);
}

- (void)continueToNextScreen {
  [[NDAPreferencesManager sharedInstance] pushNextViewController:self.navigationController];
}

#pragma mark FSQCollectionViewDelegateAlignedLayout

- (FSQCollectionViewAlignedLayoutSectionAttributes *)collectionView:(UICollectionView *)collectionView layout:(FSQCollectionViewAlignedLayout *)collectionViewLayout attributesForSectionAtIndex:(NSInteger)sectionIndex {
  return [FSQCollectionViewAlignedLayoutSectionAttributes withHorizontalAlignment:FSQCollectionViewHorizontalAlignmentCenter verticalAlignment:FSQCollectionViewVerticalAlignmentCenter];
}

- (FSQCollectionViewAlignedLayoutCellAttributes *)collectionView:(UICollectionView *)collectionView layout:(FSQCollectionViewAlignedLayout *)collectionViewLayout attributesForCellAtIndexPath:(NSIndexPath *)indexPath {
  // 5 is the default spacing, and we take a half because neighbouring cells' spacing adds up
  CGFloat spacing = (kPreferencesObjectCellSpacing - 5) / 2;

  return [FSQCollectionViewAlignedLayoutCellAttributes withInsets:UIEdgeInsetsMake(spacing, spacing, spacing, spacing) shouldBeginLine:NO shouldEndLine:NO startLineIndentation:NO];
}

@end
