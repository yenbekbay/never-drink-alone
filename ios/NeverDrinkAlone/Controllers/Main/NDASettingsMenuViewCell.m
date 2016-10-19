#import "NDASettingsMenuViewCell.h"
#import "NDAConstants.h"
#import "UIFont+NDASizes.h"
#import "UIView+AYUtils.h"

static CGSize const kMenuViewCellIconSize = {
  40, 40
};
static CGFloat const kMenuViewCellIconSpacing = 10;

@implementation NDASettingsMenuViewCell

#pragma mark Initialization

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (!self) {
    return nil;
  }

  self.titleLabel = [UILabel new];
  self.titleLabel.font = [UIFont fontWithName:kLightFontName size:[UIFont menuButtonFontSize]];
  self.titleLabel.textColor = [UIColor whiteColor];
  self.titleLabel.textAlignment = NSTextAlignmentCenter;
  [self.contentView addSubview:self.titleLabel];

  self.iconImageView = [UIImageView new];
  [self.contentView addSubview:self.iconImageView];

  return self;
}

#pragma mark Lifecycle

- (void)prepareForReuse {
  self.titleLabel.text = @"";
  self.iconImageView.image = nil;
  self.titleLabel.alpha = 1;
  self.iconImageView.alpha = 1;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  [self.titleLabel sizeToFit];
  if (self.iconImageView.image) {
    CGFloat totalWidth = kMenuViewCellIconSize.width + kMenuViewCellIconSpacing + self.titleLabel.width;
    self.iconImageView.frame = CGRectMake((self.width - totalWidth) / 2, (self.height - kMenuViewCellIconSize.height) / 2, kMenuViewCellIconSize.width, kMenuViewCellIconSize.height);
    self.titleLabel.left = self.iconImageView.right + kMenuViewCellIconSpacing;
    self.titleLabel.centerY = self.iconImageView.centerY;
  } else {
    self.titleLabel.centerX = self.width / 2;
    self.titleLabel.centerY = self.height / 2;
  }
}

@end
