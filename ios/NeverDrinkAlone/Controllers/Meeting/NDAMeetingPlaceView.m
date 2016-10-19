#import "NDAMeetingPlaceView.h"

#import "NDAConstants.h"
#import "UIColor+NDATints.h"
#import "UIFont+NDASizes.h"
#import "UIView+AYUtils.h"

@interface NDAMeetingPlaceView ()

/**
 *  Label with the name of the meeting place.
 */
@property (nonatomic) UILabel *nameLabel;
/**
 *  Label with the address of the meeting place.
 */
@property (nonatomic) UILabel *addressLabel;
@property (nonatomic) UIImageView *iconView;

@end

@implementation NDAMeetingPlaceView

#pragma mark Initialization

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (!self) {
    return nil;
  }

  self.clipsToBounds = YES;
  self.layer.cornerRadius = kMeetingPlaceCellCornerRadius;
  self.backgroundColor = [UIColor nda_lightGrayColor];

  self.nameLabel = [UILabel new];
  self.nameLabel.font = [UIFont fontWithName:kRegularFontName size:[UIFont mediumTextFontSize]];
  self.nameLabel.textColor = [UIColor nda_primaryColor];

  self.addressLabel = [UILabel new];
  self.addressLabel.font = [UIFont fontWithName:kItalicFontName size:[UIFont mediumTextFontSize]];
  self.addressLabel.textColor = [UIColor nda_darkGrayColor];

  self.iconView = [[UIImageView alloc] initWithFrame:CGRectMake(self.width - kMeetingPlaceCellPadding.right - kMeetingPlaceViewDisclosureIconSize.width, (self.height - kMeetingPlaceViewDisclosureIconSize.height) / 2, kMeetingPlaceViewDisclosureIconSize.width, kMeetingPlaceViewDisclosureIconSize.height)];
  self.iconView.tintColor = [UIColor nda_darkGrayColor];
  self.iconView.image = [[UIImage imageNamed:@"DisclosureIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

  [self addSubview:self.nameLabel];
  [self addSubview:self.addressLabel];
  //[self addSubview:self.iconView];

  return self;
}

#pragma mark Setters

- (void)setMeetingPlace:(NDAMeetingPlace *)meetingPlace {
  _meetingPlace = meetingPlace;

  self.nameLabel.text = meetingPlace.name;
  self.nameLabel.frame = CGRectMake(kMeetingPlaceCellPadding.left, kMeetingPlaceCellPadding.top, (self.width - kMeetingPlaceCellPadding.left - kCellIconSpacing - kMeetingPlaceViewDisclosureIconSize.width - kMeetingPlaceCellPadding.right), [self.meetingPlace sizeForName].height);
  self.addressLabel.text = meetingPlace.address;
  self.addressLabel.frame = CGRectMake(kMeetingPlaceCellPadding.left, kMeetingPlaceCellPadding.top + self.nameLabel.height, self.nameLabel.width, [self.meetingPlace sizeForAddress].height);
}

@end
