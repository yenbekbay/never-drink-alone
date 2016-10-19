#import "NDATimeSlotCell.h"

#import "NDAConstants.h"
#import "NDATimeSlot.h"
#import "UIFont+NDASizes.h"

@implementation NDATimeSlotCell

#pragma mark Initialization

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (!self) {
    return nil;
  }

  self.layer.cornerRadius = kTimeSlotCellCornerRadius;

  self.timeFrameLabel = [UILabel new];
  self.timeFrameLabel.font = [UIFont fontWithName:kRegularFontName size:[UIFont timeSlotCellFontSize]];
  self.timeFrameLabel.textColor = [UIColor whiteColor];
  self.timeFrameLabel.textAlignment = NSTextAlignmentCenter;

  [self.contentView addSubview:self.timeFrameLabel];

  return self;
}

#pragma mark Setters

- (void)setObject:(PFObject *)object {
  [super setObject:object];
  NDATimeSlot *timeSlot = (NDATimeSlot *)object;
  self.timeFrameLabel.text = [NSString stringWithFormat:@"%@:00 - %@:00", timeSlot.startingHour, @([timeSlot.startingHour integerValue] + 1)];
}

- (void)setAdded:(BOOL)added {
  [super setAdded:added];
  CGSize sizeForCell = [(NDATimeSlot *)self.object sizeForCell];
  if (self.isAdded) {
    self.iconView.frame = CGRectMake(sizeForCell.width - kTimeSlotCellPadding.right - kTimeSlotCellCheckIconSize.width, (sizeForCell.height - kTimeSlotCellCheckIconSize.height) / 2, kTimeSlotCellCheckIconSize.width, kTimeSlotCellCheckIconSize.height);
  } else {
    self.iconView.frame = CGRectMake(sizeForCell.width - kTimeSlotCellPadding.right - kTimeSlotCellCheckIconSize.width + (kTimeSlotCellCheckIconSize.width - kTimeSlotCellPlusIconSize.width) / 2, (sizeForCell.height - kTimeSlotCellPlusIconSize.height) / 2, kTimeSlotCellPlusIconSize.width, kTimeSlotCellPlusIconSize.height);
  }
}

@end
