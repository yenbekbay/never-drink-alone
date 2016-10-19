#import "NDAMeetingUserInfoView.h"

#import "NDAConstants.h"
#import "NDAProgressView.h"
#import "NSDate+NDAHelpers.h"
#import "NSString+NDAHelpers.h"
#import "UIFont+NDASizes.h"
#import "UIImage+ImageEffects.h"
#import "UIImage+NDAHelpers.h"
#import "UIView+AYUtils.h"
#import <SDWebImage/UIImageView+WebCache.h>

static CGSize const kUserInfoIconSize = {
  20, 20
};
static CGFloat const kUserInfoIconSpacing = 5;
static CGFloat const kTranslationAnimationDistance = 40;

@interface NDAMeetingUserInfoView ()

@property (nonatomic) NDAProgressView *progressView;
@property (nonatomic) UIImageView *backdropView;
@property (nonatomic) UIImageView *profilePictureView;
@property (nonatomic) UIView *profilePictureViewBorder;
@property (nonatomic) UILabel *nameLabel;
@property (nonatomic) UIView *topBorder;
@property (nonatomic) UIView *bottomBorder;
@property (nonatomic) UIImageView *educationIcon;
@property (nonatomic) UILabel *educationLabel;
@property (nonatomic) UIImageView *jobIcon;
@property (nonatomic) UILabel *jobLabel;
@property (nonatomic) UIImageView *biographyIcon;
@property (nonatomic) UILabel *biographyLabel;

@end

@implementation NDAMeetingUserInfoView

#pragma mark Initialization

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (!self) {
    return nil;
  }

  self.clipsToBounds = YES;
  [self setUpProgressView];

  return self;
}

#pragma mark Setters

- (void)setUser:(PFUser *)user {
  _user = user;
  [self setUpImageViews];
  [self setUpNameLabel];
  [self setUpDetailLabels];
  [self fixLayout];
  [self loadImages];
}

#pragma mark Private

- (void)setUpProgressView {
  self.progressView = [[NDAProgressView alloc] initWithFrame:self.frame];
  [self addSubview:self.progressView];
}

- (void)setUpImageViews {
  self.backdropView = [[UIImageView alloc] initWithFrame:self.frame];
  self.backdropView.clipsToBounds = YES;
  self.backdropView.contentMode = UIViewContentModeScaleAspectFill;
  self.profilePictureView = [[UIImageView alloc] initWithFrame:CGRectMake((self.width - kProfileSmallPictureSize) / 2, CGRectGetHeight([UIApplication sharedApplication].statusBarFrame), kProfileSmallPictureSize, kProfileSmallPictureSize)];
  self.profilePictureView.clipsToBounds = YES;
  self.profilePictureView.layer.cornerRadius = kProfileSmallPictureSize / 2;
  self.profilePictureView.userInteractionEnabled = YES;
  self.profilePictureView.contentMode = UIViewContentModeScaleAspectFill;
  UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(profilePictureViewTapped)];
  [self.profilePictureView addGestureRecognizer:tapGestureRecognizer];

  self.profilePictureViewBorder = [[UIView alloc] initWithFrame:CGRectMake(self.profilePictureView.left - 1 / [UIScreen mainScreen].scale, self.profilePictureView.top - 1 / [UIScreen mainScreen].scale, self.profilePictureView.width + 2 / [UIScreen mainScreen].scale, self.profilePictureView.height + 2 / [UIScreen mainScreen].scale)];
  self.profilePictureViewBorder.clipsToBounds = YES;
  self.profilePictureViewBorder.layer.cornerRadius = CGRectGetWidth(self.profilePictureViewBorder.frame) / 2;
  self.profilePictureViewBorder.backgroundColor = [UIColor whiteColor];
  self.profilePictureViewBorder.alpha = 0.75f;

  [self insertSubview:self.backdropView belowSubview:self.progressView];
  [self insertSubview:self.profilePictureViewBorder belowSubview:self.progressView];
  [self insertSubview:self.profilePictureView belowSubview:self.progressView];
}

- (void)setUpNameLabel {
  self.nameLabel = [UILabel new];
  self.nameLabel.font = [UIFont fontWithName:kRegularFontName size:[UIFont largeTextFontSize]];
  self.nameLabel.textColor = [UIColor whiteColor];
  if (self.user[kUserBirthdayKey]) {
    self.nameLabel.text = [NSString stringWithFormat:@"%@ %@, %@", self.user[kUserFirstNameKey], self.user[kUserLastNameKey], @([self.user[kUserBirthdayKey] ageFromDate])];
  } else {
    self.nameLabel.text = [NSString stringWithFormat:@"%@ %@", self.user[kUserFirstNameKey], self.user[kUserLastNameKey]];
  }

  CGSize nameLabelSize = [self.nameLabel.text sizeWithFont:self.nameLabel.font width:self.width - kMeetingViewPadding * 2];
  self.nameLabel.frame = CGRectMake((self.width - nameLabelSize.width) / 2, self.profilePictureView.bottom + kMeetingUserInfoSpacing, nameLabelSize.width, nameLabelSize.height);
  [self insertSubview:self.nameLabel belowSubview:self.progressView];
}

- (void)setUpDetailLabels {
  self.topBorder = [[UIView alloc] initWithFrame:CGRectMake((self.width - kMeetingUserInfoBorderWidth) / 2, self.nameLabel.bottom + kMeetingUserInfoSpacing, kMeetingUserInfoBorderWidth, 1 / [UIScreen mainScreen].scale)];
  self.topBorder.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.75f];

  self.educationLabel = [UILabel new];
  self.educationLabel.text = self.user[kUserEducationKey];
  self.educationIcon = [UIImageView new];

  self.jobLabel = [UILabel new];
  self.jobLabel.text = self.user[kUserJobKey];
  self.jobIcon = [UIImageView new];

  self.biographyLabel = [UILabel new];
  self.biographyLabel.text = self.user[kUserBiographyKey];
  self.biographyIcon = [UIImageView new];

  for (UILabel *label in @[self.educationLabel, self.jobLabel, self.biographyLabel]) {
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont fontWithName:kItalicFontName size:[UIFont mediumTextFontSize]];
    label.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.75f];
  }

  for (UIImageView *icon in @[self.educationIcon, self.jobIcon, self.biographyIcon]) {
    NSString *iconImageName;
    if (icon == self.educationIcon) {
      iconImageName = @"CapIcon";
    } else if (icon == self.jobIcon) {
      iconImageName = @"BriefcaseIcon";
    } else {
      if (self.user[kUserGenderKey]) {
        iconImageName = [self.user[kUserGenderKey] integerValue] == 0 ? @"MaleUserIcon" : @"FemaleUserIcon";
      } else {
        iconImageName = @"MaleUserIcon";
      }
    }
    icon.image = [[UIImage imageNamed:iconImageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    icon.tintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.75f];
  }

  CGSize educationLabelSize = [self.educationLabel.text sizeWithFont:self.educationLabel.font width:self.width - kMeetingViewPadding * 2 - kUserInfoIconSize.width - kUserInfoIconSpacing];
  self.educationLabel.frame = CGRectMake((kUserInfoIconSize.width + kUserInfoIconSpacing + self.width - educationLabelSize.width) / 2, self.topBorder.bottom + kMeetingUserInfoSpacing, educationLabelSize.width, educationLabelSize.height);
  self.educationIcon.frame = CGRectMake(self.educationLabel.left - kUserInfoIconSize.width - kUserInfoIconSpacing, self.topBorder.bottom + kMeetingUserInfoSpacing, kUserInfoIconSize.width, kUserInfoIconSize.height);

  CGSize jobLabelSize = [self.jobLabel.text sizeWithFont:self.jobLabel.font width:self.width - kMeetingViewPadding * 2 - kUserInfoIconSize.width - kUserInfoIconSpacing];
  self.jobLabel.frame = CGRectMake((kUserInfoIconSize.width + kUserInfoIconSpacing + self.width - jobLabelSize.width) / 2, self.educationLabel.bottom + kMeetingUserInfoSpacing, jobLabelSize.width, jobLabelSize.height);
  self.jobIcon.frame = CGRectMake(self.jobLabel.left - kUserInfoIconSize.width - kUserInfoIconSpacing, self.educationLabel.bottom + kMeetingUserInfoSpacing, kUserInfoIconSize.width, kUserInfoIconSize.height);

  CGSize biographyLabelSize = [self.biographyLabel.text sizeWithFont:self.biographyLabel.font width:self.width - kMeetingViewPadding * 2 - kUserInfoIconSize.width - kUserInfoIconSpacing];
  self.biographyLabel.frame = CGRectMake((kUserInfoIconSize.width + kUserInfoIconSpacing + self.width - biographyLabelSize.width) / 2, self.jobLabel.bottom + kMeetingUserInfoSpacing, biographyLabelSize.width, biographyLabelSize.height);
  self.biographyIcon.frame = CGRectMake(self.biographyLabel.left - kUserInfoIconSize.width - kUserInfoIconSpacing, self.jobLabel.bottom + kMeetingUserInfoSpacing, kUserInfoIconSize.width, kUserInfoIconSize.height);

  self.bottomBorder = [[UIView alloc] initWithFrame:CGRectMake((self.width - kMeetingUserInfoBorderWidth) / 2, self.biographyLabel.bottom + kMeetingUserInfoSpacing, kMeetingUserInfoBorderWidth, 1 / [UIScreen mainScreen].scale)];
  self.bottomBorder.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.75f];

  for (UIView *view in @[self.topBorder, self.educationLabel, self.educationIcon, self.jobLabel, self.jobIcon, self.biographyLabel, self.biographyIcon, self.bottomBorder]) {
    [self insertSubview:view belowSubview:self.progressView];
  }
}

- (void)fixLayout {
  CGFloat diff = (self.height - kMeetingCutoutSize.height - self.bottomBorder.bottom) / 2;
  for (UIView *view in @[self.profilePictureView, self.profilePictureViewBorder, self.nameLabel, self.topBorder, self.educationLabel, self.educationIcon, self.jobLabel, self.jobIcon, self.biographyLabel, self.biographyIcon, self.bottomBorder]) {
    view.top += diff;
  }
}

- (void)loadImages {
  if (self.user[kUserPictureKey]) {
    PFObject *userPicture = self.user[kUserPictureKey];
    [userPicture fetchIfNeededInBackgroundWithBlock:^(PFObject *fetchedUserPicture, NSError *error) {
      if (!error) {
        [self setProfilePictureImage:fetchedUserPicture];
      } else {
        DDLogError(@"Error occured while fetching user picture: %@", error);
      }
    }];
  }
}

- (void)profilePictureViewTapped {
  [self.meetingDelegate displayImageForImageView:self.profilePictureView];
}

#pragma mark Setters

- (void)setProfilePictureImage:(PFObject *)userPicture {
  PFFile *imageFile = userPicture[@"imageFile"];

  if (imageFile) {
    [imageFile getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
      if (!error) {
        UIImage *image = [UIImage imageWithData:imageData];
        self.profilePictureView.image = image;
        UIImage *blurredImage = [image applyBlurWithRadius:kBackdropBlurRadius tintColor:[UIColor colorWithWhite:0 alpha:kBackdropBlurDarkeningRatio] saturationDeltaFactor:kBackdropBlurSaturationDeltaFactor maskImage:nil];
        self.backdropView.image = blurredImage;
        self.progressView.progress = 1;
      } else {
        DDLogError(@"Error occured while getting user picture image: %@", error);
      }
    }];
  } else {
    NSURL *imageUrl = [NSURL URLWithString:userPicture[@"imageUrl"]];
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    [manager downloadImageWithURL:imageUrl options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
      CGFloat progress = (float)receivedSize / (float)expectedSize;
      if (progress < 1) {
        self.progressView.progress = progress;
      }
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
      if (!error) {
        self.profilePictureView.image = image;
        UIImage *blurredImage = [image applyBlurWithRadius:kBackdropBlurRadius tintColor:[UIColor colorWithWhite:0 alpha:kBackdropBlurDarkeningRatio] saturationDeltaFactor:kBackdropBlurSaturationDeltaFactor maskImage:nil];
        self.backdropView.image = blurredImage;
        self.progressView.progress = 1;
      } else {
        DDLogError(@"Error occured while downloading user picture image: %@", error);
      }
    }];
  }
}

#pragma mark Public

- (void)shrink {
  [UIView animateWithDuration:0.2f animations:^{
    CGRect containerFrame = self.frame;
    CGFloat heightDiff = -(CGRectGetMaxY(self.bottomBorder.frame) - CGRectGetMinY(self.topBorder.frame));
    containerFrame.size.height += heightDiff;
    [self.meetingDelegate userInfoViewChangedHeight:heightDiff];
    for (UIView *view in @[self.topBorder, self.educationLabel, self.educationIcon, self.jobLabel, self.jobIcon, self.biographyLabel, self.biographyIcon, self.bottomBorder]) {
      view.alpha = 0;
      view.top -= kTranslationAnimationDistance;
      self.frame = containerFrame;
    }
  }];
}

- (void)expand {
  [UIView animateWithDuration:0.2f animations:^{
    CGRect containerFrame = self.frame;
    CGFloat heightDiff = CGRectGetMaxY(self.bottomBorder.frame) - CGRectGetMinY(self.topBorder.frame);
    containerFrame.size.height += heightDiff;
    [self.meetingDelegate userInfoViewChangedHeight:heightDiff];
    for (UIView *view in @[self.topBorder, self.educationLabel, self.educationIcon, self.jobLabel, self.jobIcon, self.biographyLabel, self.biographyIcon, self.bottomBorder]) {
      view.alpha = 1;
      view.top += kTranslationAnimationDistance;
      self.frame = containerFrame;
    }
  }];
}

@end
