#import "NDAFreeTimesViewController.h"

#import "NDAAlertManager.h"
#import "NDAConstants.h"
#import "NDATimeSlot.h"
#import "NDATimeSlotCell.h"
#import "NDAWeekdayPickerCell.h"
#import "PFUser+NDAHelpers.h"
#import "UIView+AYUtils.h"
#import <FSQCollectionViewAlignedLayout/FSQCollectionViewAlignedLayout.h>

static NSInteger const kTimeSlotsFirstHour = 9;
static NSInteger const kTimeSlotsLastHour = 22;
static CGFloat const kWeekdayPickerCellSpacing = 5;
static CGFloat const kWeekdayRangePickerCellSize = 100;

@interface NDAFreeTimesViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

/**
 *  Collection view with days of the week starting from today.
 */
@property (nonatomic) UICollectionView *weekdayPickerCollectionView;
/**
 *  Collection view with available one-hour time slots throughout the day -- from 8:00 to 22:00.
 */
@property (nonatomic) UICollectionView *timeSlotsCollectionView;
/**
 *  Contaisn the available time slots for the time slots collection view.
 */
@property (nonatomic) NSMutableArray *timeSlots;
/**
 *  Indicates the selected day of the week from the weekday picker. By default, it's today.
 */
@property (nonatomic) NSInteger activeWeekday;
/**
 *  Indicates the selected range of weekdays form the weekday. By default, it's Mon-Fri.
 */
@property (nonatomic) NSRange activeRange;
/**
 *  Indicates whether or not to use the range (e.g. Mon-Fri) instaead of explicitly using weekdays.
 */
@property (nonatomic) BOOL useRange;
/**
 *  Contains ranges of weekdays (max two) added by the user.
 */
@property (nonatomic) NSMutableArray *addedRanges;
/**
 *  Alert manager to display notifications.
 */
@property (nonatomic) NDAAlertManager *alertManager;

@end

@implementation NDAFreeTimesViewController

#pragma mark Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  self.useRange = YES;
  self.alertManager = [NDAAlertManager new];
  [self initData];
  [self setUpCollectionViews];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  NSString *progress = [[PFUser currentUser][kUserDidFinishRegistrationKey] boolValue] ? @"3/3" : @"5/5";
  self.navigationItem.title = [NSString localizedStringWithFormat:@"Свободные часы (%@)", progress];
}

#pragma mark Private

- (void)initData {
  self.timeSlots = [NSMutableArray new];
  for (NSUInteger weekday = 0; weekday < 7; weekday++) {
    [self.timeSlots addObject:[NSMutableArray new]];
    for (NSUInteger startingHour = kTimeSlotsFirstHour; startingHour < kTimeSlotsLastHour + 1; startingHour++) {
      NDATimeSlot *timeSlot = [[NDATimeSlot alloc] initWithWeekday:@(weekday) startingHour:@(startingHour)];
      [self.timeSlots[weekday] addObject:timeSlot];
    }
  }
  if (self.useRange) {
    self.activeRange = NSMakeRange(0, 5);
  } else {
    self.activeWeekday = 0;
  }
  self.addedObjects = [NSMutableArray new];
  self.addedRanges = [NSMutableArray new];
  [[[PFUser currentUser] getTimeSlots] subscribeNext:^(NSArray *addedTimeSlots) {
    self.addedObjects = [addedTimeSlots mutableCopy];
    if (self.addedObjects.count > 0) {
      self.addedRanges = [@[@0, @5] mutableCopy];
    }
    [self reloadTimeSlotsCollectionView];
  }];
}

- (void)setUpCollectionViews {
  FSQCollectionViewAlignedLayout *weekdayPickerCollectionViewLayout = [FSQCollectionViewAlignedLayout new];

  self.weekdayPickerCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(kPreferencesViewPadding, kPreferencesViewPadding, self.view.width - kPreferencesViewPadding * 2,  (self.useRange ? kWeekdayRangePickerCellSize : [self sizeForWeekdayPickerCell]) + kPreferencesObjectCellSpacing * 2) collectionViewLayout:weekdayPickerCollectionViewLayout];
  [self.weekdayPickerCollectionView registerClass:[NDAWeekdayPickerCell class] forCellWithReuseIdentifier:kPreferencesObjectCellReuseIdentifier];

  FSQCollectionViewAlignedLayout *timeSlotsCollectionViewLayout = [FSQCollectionViewAlignedLayout new];
  self.timeSlotsCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(kPreferencesViewPadding, self.weekdayPickerCollectionView.bottom + kTimeSlotsCollectionViewTopMargin, 0, 0) collectionViewLayout:timeSlotsCollectionViewLayout];
  [self.timeSlotsCollectionView registerClass:[NDATimeSlotCell class] forCellWithReuseIdentifier:kPreferencesObjectCellReuseIdentifier];

  for (UICollectionView *collectionView in @[self.weekdayPickerCollectionView, self.timeSlotsCollectionView]) {
    collectionView.dataSource = self;
    collectionView.delegate = self;
    collectionView.backgroundColor = [UIColor whiteColor];
  }

  [self.scrollView addSubview:self.weekdayPickerCollectionView];
  [self.scrollView addSubview:self.timeSlotsCollectionView];

  [self reloadTimeSlotsCollectionView];
}

- (void)reloadTimeSlotsCollectionView {
  [self.timeSlotsCollectionView.collectionViewLayout invalidateLayout];
  [self.timeSlotsCollectionView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, (NSUInteger)self.timeSlotsCollectionView.numberOfSections)]];

  self.timeSlotsCollectionView.size = [self sizeForCollectionViewWithObjects:self.timeSlots[(NSUInteger)self.activeWeekday]];
  self.scrollView.contentSize = CGSizeMake(self.view.width, self.timeSlotsCollectionView.bottom + kPreferencesViewPadding);
}

- (CGSize)sizeForCollectionViewWithObjects:(NSArray *)objects {
  return CGSizeMake(self.view.width - kPreferencesViewPadding * 2, (kPreferencesObjectCellSpacing + (kTimeSlotCellHeight + kPreferencesObjectCellSpacing) * objects.count));
}

- (NSString *)titleForContinueButton {
  return NSLocalizedString(@"Завершить", nil);
}

#pragma mark UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
  return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  if (collectionView == self.weekdayPickerCollectionView) {
    return self.useRange ? 2 : 7;
  } else {
    return (NSInteger)[self.timeSlots[(NSUInteger)self.activeWeekday] count];
  }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath remainingLineSpace:(CGFloat)remainingLineSpace {
  if (collectionView == self.weekdayPickerCollectionView) {
    if (self.useRange) {
      return CGSizeMake(kWeekdayRangePickerCellSize, kWeekdayRangePickerCellSize);
    } else {
      CGFloat calculatedSize = [self sizeForWeekdayPickerCell];
      return CGSizeMake(calculatedSize, calculatedSize);
    }
  } else {
    return CGSizeMake(self.view.width - kPreferencesViewPadding * 2 - kPreferencesObjectCellSpacing * 2, kTimeSlotCellHeight);
  }
}

- (CGFloat)sizeForWeekdayPickerCell {
  return (self.view.width - kPreferencesViewPadding * 2 - kWeekdayPickerCellSpacing) / 7 - kWeekdayPickerCellSpacing - 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  if (collectionView == self.weekdayPickerCollectionView) {
    NDAWeekdayPickerCell *cell = (NDAWeekdayPickerCell *)[collectionView dequeueReusableCellWithReuseIdentifier:kPreferencesObjectCellReuseIdentifier forIndexPath:indexPath];
    if (self.useRange) {
      if (indexPath.row == 0) {
        cell.range = NSMakeRange(0, 5);
      } else {
        cell.range = NSMakeRange(5, 2);
      }
    } else {
      cell.weekday = indexPath.row;
    }
    cell.weekdayLabel.frame = CGRectMake(0, 0, cell.width, [cell.weekdayLabel.text sizeWithAttributes:@{ NSFontAttributeName : cell.weekdayLabel.font }].height);
    cell.weekdayWrapper.frame = cell.bounds;
    cell.weekdayWrapper.layer.cornerRadius = cell.weekdayWrapper.height / 2;
    cell.weekdayLabel.frame = cell.weekdayWrapper.bounds;
    if (self.useRange) {
      cell.active = NSEqualRanges(self.activeRange, cell.range);
    } else {
      cell.active = self.activeWeekday == cell.weekday;
    }
    return cell;
  } else {
    NDATimeSlotCell *cell = (NDATimeSlotCell *)[collectionView dequeueReusableCellWithReuseIdentifier:kPreferencesObjectCellReuseIdentifier forIndexPath:indexPath];
    if (self.useRange) {
      NSInteger row = NSEqualRanges(self.activeRange, NSMakeRange(0, 5)) ? 0 : 5;
      cell.object = self.timeSlots[(NSUInteger)row][(NSUInteger)indexPath.row];
    } else {
      cell.object = self.timeSlots[(NSUInteger)self.activeWeekday][(NSUInteger)indexPath.row];
    }
    cell.timeFrameLabel.frame = CGRectMake(kTimeSlotCellPadding.left, kTimeSlotCellPadding.top, cell.width - kTimeSlotCellPadding.left - kCellIconSpacing - kTimeSlotCellCheckIconSize.width - kTimeSlotCellPadding.right, cell.height - kTimeSlotCellPadding.top - kTimeSlotCellPadding.bottom);
    cell.added = [self.addedObjects containsObject:cell.object];
    return cell;
  }
}

#pragma mark UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  if (collectionView == self.weekdayPickerCollectionView) {
    NDAWeekdayPickerCell *cell = (NDAWeekdayPickerCell *)[collectionView cellForItemAtIndexPath:indexPath];
    if (!cell.active) {
      NSInteger activeRow;
      if (self.useRange) {
        activeRow = NSEqualRanges(self.activeRange, NSMakeRange(0, 5)) ? 0 : 1;
      } else {
        activeRow = self.activeWeekday;
      }
      NDAWeekdayPickerCell *activeCell = (NDAWeekdayPickerCell *)[collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:activeRow inSection:0]];
      activeCell.active = NO;
      cell.active = YES;
      [cell scaleAnimation];
      if (self.useRange) {
        self.activeRange = cell.range;
      } else {
        self.activeWeekday = cell.weekday;
      }
      [self reloadTimeSlotsCollectionView];
    }
  } else {
    NDATimeSlotCell *cell = (NDATimeSlotCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell scaleAnimation];
    cell.added = !cell.isAdded;
    if (self.useRange) {
      if (![self.addedRanges containsObject:@(self.activeRange.location)]) {
        [self.addedRanges addObject:@(self.activeRange.location)];
      }
      for (NSUInteger i = self.activeRange.location; i < self.activeRange.location + self.activeRange.length; i++) {
        NDATimeSlot *timeSlot = self.timeSlots[i][(NSUInteger)indexPath.row];
        if (![self.addedObjects containsObject:timeSlot]) {
          [self.addedObjects addObject:timeSlot];
        } else {
          [self.addedObjects removeObject:timeSlot];
        }
      }
    } else {
      if (cell.isAdded) {
        [self.addedObjects addObject:cell.object];
      } else {
        [self.addedObjects removeObject:cell.object];
      }
    }
  }
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
  if (collectionView == self.timeSlotsCollectionView) {
    NDAPreferencesObjectCell *cell = (NDAPreferencesObjectCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell scaleToSmall];
  }
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
  if (collectionView == self.timeSlotsCollectionView) {
    NDAPreferencesObjectCell *cell = (NDAPreferencesObjectCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell scaleToDefault];
  }
}

- (void)continueToNextScreen {
  if (self.useRange && [self.addedRanges count] < 2) {
    BOOL addedWeekdays = [self.addedRanges containsObject:@0];
    BOOL addedWeekends = [self.addedRanges containsObject:@5];
    NSInteger activeRow = NSEqualRanges(self.activeRange, NSMakeRange(0, 5)) ? 0 : 1;
    if (activeRow == 0 && !addedWeekdays) {
      [self.alertManager showNotificationWithText:NSLocalizedString(@"Пожалуйста, добавьте свободные часы для будней", nil)];
    } else if (activeRow == 1 && !addedWeekends) {
      [self.alertManager showNotificationWithText:NSLocalizedString(@"Пожалуйста, добавьте свободные часы для выходных", nil)];
    } else {
      if (activeRow == 0 && !addedWeekends) {
        [self.alertManager showNotificationWithText:NSLocalizedString(@"Пожалуйста, добавьте свободные часы для выходных", nil)];
      } else if (activeRow == 1 && !addedWeekdays) {
        [self.alertManager showNotificationWithText:NSLocalizedString(@"Пожалуйста, добавьте свободные часы для будней", nil)];
      }
      NDAWeekdayPickerCell *activeCell = (NDAWeekdayPickerCell *)[self.weekdayPickerCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:activeRow inSection:0]];
      NDAWeekdayPickerCell *cell = (NDAWeekdayPickerCell *)[self.weekdayPickerCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:(activeRow == 0 ? 1 : 0) inSection:0]];
      activeCell.active = NO;
      cell.active = YES;
      self.activeRange = cell.range;
      [self reloadTimeSlotsCollectionView];
    }
  } else {
    [super continueToNextScreen];
  }
}

#pragma mark FSQCollectionViewDelegateAlignedLayout

- (FSQCollectionViewAlignedLayoutCellAttributes *)collectionView:(UICollectionView *)collectionView layout:(FSQCollectionViewAlignedLayout *)collectionViewLayout attributesForCellAtIndexPath:(NSIndexPath *)indexPath {
  CGFloat spacing;

  if (collectionView == self.weekdayPickerCollectionView) {
    spacing = 0;
  } else {
    // 5 is the default spacing, and we take a half because neighbouring cells' spacing adds up
    spacing = (kPreferencesObjectCellSpacing - 5) / 2;
  }
  return [FSQCollectionViewAlignedLayoutCellAttributes withInsets:UIEdgeInsetsMake(spacing, spacing, spacing, spacing) shouldBeginLine:NO shouldEndLine:NO startLineIndentation:NO];
}

@end
