#import "NDAMeetingPlaceCell.h"

#import "NDAConstants.h"
#import "NDAMeetingPlace.h"
#import "UIFont+NDASizes.h"

@implementation NDAMeetingPlaceCell

#pragma mark Initialization

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (!self) {
    return nil;
  }

  self.layer.cornerRadius = kMeetingPlaceCellCornerRadius;

  self.nameLabel = [UILabel new];
  self.nameLabel.font = [UIFont fontWithName:kRegularFontName size:[UIFont mediumTextFontSize]];
  self.nameLabel.textColor = [UIColor whiteColor];

  self.addressLabel = [UILabel new];
  self.addressLabel.font = [UIFont fontWithName:kItalicFontName size:[UIFont mediumTextFontSize]];
  self.addressLabel.textColor = [UIColor whiteColor];

  [self.contentView addSubview:self.nameLabel];
  [self.contentView addSubview:self.addressLabel];

  return self;
}

#pragma mark Setters

- (void)setObject:(PFObject *)object {
  [super setObject:object];
  NDAMeetingPlace *meetingPlace = (NDAMeetingPlace *)object;
  self.nameLabel.text = meetingPlace.name;
  if (meetingPlace.address) {
    self.addressLabel.text = [NSString stringWithFormat:@"%@, %@", [meetingPlace distanceString], meetingPlace.address];
  } else {
    self.addressLabel.text = [meetingPlace distanceString];
  }
}

- (void)setAdded:(BOOL)added {
  [super setAdded:added];
  CGSize sizeForCell = [(NDAMeetingPlace *)self.object sizeForCell];
  if (self.isAdded) {
    self.iconView.frame = CGRectMake(sizeForCell.width - kMeetingPlaceCellPadding.right - kMeetingPlaceCellCheckIconSize.width, (sizeForCell.height - kMeetingPlaceCellCheckIconSize.height) / 2, kMeetingPlaceCellCheckIconSize.width, kMeetingPlaceCellCheckIconSize.height);
  } else {
    self.iconView.frame = CGRectMake(sizeForCell.width - kMeetingPlaceCellPadding.right - kMeetingPlaceCellCheckIconSize.width + (kMeetingPlaceCellCheckIconSize.width - kMeetingPlaceCellPlusIconSize.width) / 2, (sizeForCell.height - kMeetingPlaceCellPlusIconSize.height) / 2,  kMeetingPlaceCellPlusIconSize.width, kMeetingPlaceCellPlusIconSize.height);
  }
}

@end
