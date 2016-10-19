#import "NDASettingsMenuView.h"

#import "NDASettingsMenuViewCell.h"
#import "UIView+AYUtils.h"
#import <pop/POP.h>

@interface NDASettingsMenuView () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, getter = isAnimating) BOOL animating;
@property (nonatomic) NSArray *images;
@property (nonatomic) NSArray *titles;

@end

@implementation NDASettingsMenuView

- (instancetype)initWithFrame:(CGRect)frame images:(NSArray *)images titles:(NSArray *)titles {
  self = [super initWithFrame:frame];
  if (!self) {
    return nil;
  }

  self.images = images;
  self.titles = titles;

  self.backgroundColor = [UIColor clearColor];
  [self setUpTableView];

  return self;
}

- (void)setUpTableView {
  self.tableView = [[UITableView alloc] initWithFrame:self.bounds];
  self.tableView.backgroundColor = [UIColor clearColor];
  self.tableView.scrollEnabled = NO;
  self.tableView.tableFooterView = [UIView new];
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  [self.tableView registerClass:[NDASettingsMenuViewCell class] forCellReuseIdentifier:NSStringFromClass([NDASettingsMenuViewCell class])];
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  [self addSubview:self.tableView];
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
  self.animating = YES;
  [super willMoveToWindow:newWindow];
}

#pragma mark UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  NDASettingsMenuViewCell *cell = (NDASettingsMenuViewCell *)[tableView dequeueReusableCellWithIdentifier:NSStringFromClass([NDASettingsMenuViewCell class])];

  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  cell.backgroundColor = [UIColor clearColor];
  cell.separatorInset = UIEdgeInsetsZero;
  cell.preservesSuperviewLayoutMargins = NO;
  cell.layoutMargins = UIEdgeInsetsZero;

  if (self.images.count > (NSUInteger)indexPath.row) {
    cell.iconImageView.image = [self.images[(NSUInteger)indexPath.row] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  }
  cell.titleLabel.text = self.titles[(NSUInteger)indexPath.row];

  return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return (NSInteger)self.titles.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return self.height / self.titles.count;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  NDASettingsMenuViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
  [self scaleAnimation:cell];
  if (self.delegate) {
    [self.delegate menuView:self didSelectRowAtIndexPath:indexPath];
  }
}

- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
  NDASettingsMenuViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
  [self scaleToSmall:cell];
  cell.titleLabel.alpha = 0.75f;
  cell.iconImageView.alpha = 0.75f;
}

- (void)tableView:(UITableView *)tableView didUnhighlightRowAtIndexPath:(NSIndexPath *)indexPath {
  NDASettingsMenuViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
  [self scaleToDefault:cell];
  cell.titleLabel.alpha = 1;
  cell.iconImageView.alpha = 1;
}

#pragma mark Animations

- (void)scaleToSmall:(NDASettingsMenuViewCell *)cell {
  POPBasicAnimation *scaleAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
  scaleAnimation.toValue = [NSValue valueWithCGSize:CGSizeMake(0.95f, 0.95f)];
  [cell.layer pop_addAnimation:scaleAnimation forKey:@"layerScaleSmallAnimation"];
}

- (void)scaleAnimation:(NDASettingsMenuViewCell *)cell {
  POPSpringAnimation *scaleAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
  scaleAnimation.velocity = [NSValue valueWithCGSize:CGSizeMake(3, 3)];
  scaleAnimation.toValue = [NSValue valueWithCGSize:CGSizeMake(1, 1)];
  scaleAnimation.springBounciness = 18;
  [cell.layer pop_addAnimation:scaleAnimation forKey:@"layerScaleSpringAnimation"];
}

- (void)scaleToDefault:(NDASettingsMenuViewCell *)cell {
  POPBasicAnimation *scaleAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
  scaleAnimation.toValue = [NSValue valueWithCGSize:CGSizeMake(1, 1)];
  [cell.layer pop_addAnimation:scaleAnimation forKey:@"layerScaleDefaultAnimation"];
}

@end
