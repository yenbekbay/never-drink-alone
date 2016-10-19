#import "NDAInterestCell.h"

#import "NDAInterest.h"
#import "NDAConstants.h"
#import "UIFont+NDASizes.h"

@implementation NDAInterestCell

#pragma mark Initialization

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (!self) {
    return nil;
  }

  self.layer.cornerRadius = kInterestCellCornerRadius;

  self.nameLabel = [UILabel new];
  self.nameLabel.font = [UIFont fontWithName:kRegularFontName size:[UIFont mediumTextFontSize]];
  self.nameLabel.textColor = [UIColor whiteColor];
  self.nameLabel.textAlignment = NSTextAlignmentCenter;
  self.nameLabel.numberOfLines = 0;

  [self.contentView addSubview:self.nameLabel];

  return self;
}

#pragma mark Setters

- (void)setObject:(PFObject *)object {
  [super setObject:object];
  self.nameLabel.text = [(NDAInterest *)object name];
}

- (void)setAdded:(BOOL)added {
  [super setAdded:added];
  CGSize sizeForCell = [(NDAInterest *)self.object sizeForCell];
  if (self.isAdded) {
    self.iconView.frame = CGRectMake(sizeForCell.width - kInterestCellPadding.right - kInterestCellCheckIconSize.width, (sizeForCell.height - kInterestCellCheckIconSize.height) / 2, kInterestCellCheckIconSize.width, kInterestCellCheckIconSize.height);
  } else {
    self.iconView.frame = CGRectMake(sizeForCell.width - kInterestCellPadding.right - kInterestCellCheckIconSize.width + (kInterestCellCheckIconSize.width - kInterestCellPlusIconSize.width) / 2, (sizeForCell.height - kInterestCellPlusIconSize.height) / 2, kInterestCellPlusIconSize.width, kInterestCellPlusIconSize.height);
  }
}

@end
