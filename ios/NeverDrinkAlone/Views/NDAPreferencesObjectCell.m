#import "NDAPreferencesObjectCell.h"

#import "NDAConstants.h"
#import "UIColor+NDATints.h"
#import <pop/POP.h>

@implementation NDAPreferencesObjectCell

#pragma mark Initialization

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (!self) {
    return nil;
  }

  _iconView = [UIImageView new];
  self.iconView.tintColor = [UIColor whiteColor];

  [self.contentView addSubview:self.iconView];

  return self;
}

- (void)prepareForReuse {
  [super prepareForReuse];
  self.added = NO;
}

#pragma mark Setters

- (void)setAdded:(BOOL)added {
  _added = added;
  if (self.isAdded) {
    self.backgroundColor = [UIColor nda_accentColor];
    self.iconView.image = [[UIImage imageNamed:@"CheckIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  } else {
    self.backgroundColor = [UIColor nda_primaryColor];
    self.iconView.image = [[UIImage imageNamed:@"PlusIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  }
}

#pragma mark Animations

- (void)scaleToSmall {
  POPBasicAnimation *scaleAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerScaleXY];

  scaleAnimation.toValue = [NSValue valueWithCGSize:CGSizeMake(0.95f, 0.95f)];
  [self.layer pop_addAnimation:scaleAnimation forKey:@"layerScaleSmallAnimation"];
}

- (void)scaleAnimation {
  POPSpringAnimation *scaleAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerScaleXY];

  scaleAnimation.velocity = [NSValue valueWithCGSize:CGSizeMake(3.f, 3.f)];
  scaleAnimation.toValue = [NSValue valueWithCGSize:CGSizeMake(1.f, 1.f)];
  scaleAnimation.springBounciness = 5.f;
  [self.layer pop_addAnimation:scaleAnimation forKey:@"layerScaleSpringAnimation"];
}

- (void)scaleToDefault {
  POPBasicAnimation *scaleAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerScaleXY];

  scaleAnimation.toValue = [NSValue valueWithCGSize:CGSizeMake(1.f, 1.f)];
  [self.layer pop_addAnimation:scaleAnimation forKey:@"layerScaleDefaultAnimation"];
}

@end
