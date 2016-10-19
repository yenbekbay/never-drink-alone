typedef NS_ENUM (NSInteger, NDAPreferencesObjectsListType) {
  NDAPreferencesObjectsListInterests = 0,
  NDAPreferencesObjectsListMeetingPlaces = 1
};

typedef void (^NDADismissHandler)(void);

extern CGFloat const kBigButtonHeight;
extern CGFloat const kMediumButtonHeight;
extern CGFloat const kSmallButtonHeight;
extern CGFloat const kButtonIconSpacing;
extern CGFloat const kCellIconSpacing;
extern CGFloat const kMediumButtonCornerRadius;

extern CGFloat const kKeyboardTriggerOffset;
extern CGFloat const kFloatingLabelSpacing;

extern NSString *const kReloadMeetingNotification;
extern NSString *const kRefreshNotification;

extern NSString *const kRegularFontName;
extern NSString *const kItalicFontName;
extern NSString *const kLightFontName;
extern NSString *const kSemiboldFontName;

extern NSString *const kFirebaseUrl;
extern NSUInteger const kUserBiographyCharsLimit;

#pragma mark Walkthrough

extern CGFloat const kOnboardingBottomHeight;
extern CGFloat const kOnboardingSkipButtonWidth;

#pragma mark Authorization

extern CGFloat const kAuthorizationViewPadding;

extern NSString *const kUserFirstNameKey;
extern NSString *const kUserLastNameKey;
extern NSString *const kUserEducationKey;
extern NSString *const kUserJobKey;
extern NSString *const kUserBirthdayKey;
extern NSString *const kUserGenderKey;
extern NSString *const kUserBiographyKey;
extern NSString *const kUserPictureKey;
extern NSString *const kUserKarmaKey;
extern NSString *const kUserIndustryKey;
extern NSString *const kUserKey;
extern NSString *const kInterestKey;
extern NSString *const kMeetingPlaceKey;
extern NSString *const kTimeSlotKey;
extern NSString *const kMeetingKey;
extern NSString *const kMatchKey;
extern NSString *const kUserHasSeenKey;
extern NSString *const kUserHasAcceptedKey;
extern NSString *const kUserHasRejectedKey;
extern NSString *const kUserHasMeetingScheduledKey;
extern NSString *const kUserHasUndecidedMeetingKey;
extern NSString *const kConfirmedKey;
extern NSString *const kCancelledKey;
extern NSString *const kActiveKey;
extern NSString *const kInterestedInKey;
extern NSString *const kIsAdministratorKey;
extern NSString *const kLastNotificationKey;
extern NSString *const kCanPostSelfieKey;
extern NSString *const kReloadKey;
extern NSString *const kSelfieKey;
extern NSString *const kImagesKey;
extern NSString *const kUserDidFinishRegistrationKey;
extern NSString *const kUserHasSeenTips;
extern NSInteger const kUserInitialKarma;

extern CGFloat const kProfileHugePictureSize;
extern CGFloat const kProfileBigPictureSize;
extern CGFloat const kProfileSmallPictureSize;

#pragma mark Profile Configuration

extern CGFloat const kProfileConfigurationViewPadding;
extern CGFloat const kProfileConfigurationSpacing;
extern CGFloat const kProfileConfigurationContinueButtonTopMargin;
extern UIEdgeInsets const kProfileConfigurationContinueButtonPadding;
extern UIEdgeInsets const kProfileConfigurationTextFieldPadding;
extern CGFloat const kProfileConfigurationKeyboardTopMargin;

#pragma mark Adding Preferences

extern CGFloat const kSearchBarTopMargin;
extern CGFloat const kSearchBarHeight;
extern CGSize const kSearchIconSize;
extern UIEdgeInsets const kSearchTextFieldPadding;
extern CGFloat const kPreferencesViewPadding;
extern CGFloat const kPreferencesCollectionViewTopMargin;
extern CGSize const kRefreshButtonSize;
extern CGFloat const kRefreshButtonTopMargin;

extern NSString *const kPreferencesObjectCellReuseIdentifier;
extern CGFloat const kPreferencesObjectCellSpacing;

extern UIEdgeInsets const kInterestCellPadding;
extern CGSize const kInterestCellPlusIconSize;
extern CGSize const kInterestCellCheckIconSize;
extern CGFloat const kInterestCellCornerRadius;

extern NSString *const kLocationLoadedNotification;

extern NSString *const kFoursquareClientId;
extern NSString *const kFoursquareClientSecret;
extern NSString *const kFoursquareCoffeeShopId;
extern NSString *const kFoursquareFoodId;
extern NSInteger const kMeetingPlacesNDArbyRadius;
extern NSInteger const kMeetingPlacesCityRadius;

extern UIEdgeInsets const kMeetingPlaceCellPadding;
extern CGSize const kMeetingPlaceCellPlusIconSize;
extern CGSize const kMeetingPlaceCellCheckIconSize;
extern CGFloat const kMeetingPlaceCellCornerRadius;

extern CGFloat const kTimeSlotsCollectionViewTopMargin;

extern UIEdgeInsets const kTimeSlotCellPadding;
extern CGSize const kTimeSlotCellPlusIconSize;
extern CGSize const kTimeSlotCellCheckIconSize;
extern CGFloat const kTimeSlotCellCornerRadius;
extern CGFloat const kTimeSlotCellHeight;

extern CGFloat const kAlmatyCoordinatesLatitude;
extern CGFloat const kAlmatyCoordinatesLongitude;

#pragma mark Dashboard

extern CGFloat const kDashboardCardCornerRadius;

#pragma mark Meeting

extern CGFloat const kMeetingViewPadding;
extern CGFloat const kMeetingUserInfoViewHeight;
extern CGFloat const kMeetingUserInfoSpacing;
extern CGFloat const kMeetingUserInfoBorderWidth;
extern CGSize const kMeetingCutoutSize;

extern CGSize const kMeetingPlaceViewDisclosureIconSize;

extern CGFloat const kMeetingDetailsViewSpacing;

extern CGFloat const kBackdropBlurRadius;
extern CGFloat const kBackdropBlurDarkeningRatio;
extern CGFloat const kBackdropBlurSaturationDeltaFactor;

#pragma mark Chats

extern CGFloat const kChatsCellHeight;

#pragma mark Modal Views

extern CGFloat const kModalViewBlurRadius;
extern CGFloat const kModalViewBlurDarkeningRatio;
extern CGFloat const kModalViewBlurSaturationDeltaFactor;
extern NSTimeInterval const kModalViewAnimationDuration;
