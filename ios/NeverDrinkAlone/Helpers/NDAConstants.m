#import "NDAConstants.h"

CGFloat const kBigButtonHeight = 60;
CGFloat const kMediumButtonHeight = 44;
CGFloat const kSmallButtonHeight = 26;
CGFloat const kButtonIconSpacing = 10;
CGFloat const kCellIconSpacing = 5;
CGFloat const kMediumButtonCornerRadius = 5;

CGFloat const kKeyboardTriggerOffset = 20;
CGFloat const kFloatingLabelSpacing = 15;

NSString *const kReloadMeetingNotification = @"reloadMeeting";
NSString *const kRefreshNotification = @"refreshMeetingIfNeeded";

NSString *const kRegularFontName = @"OpenSans";
NSString *const kItalicFontName = @"OpenSans-Italic";
NSString *const kLightFontName = @"OpenSans-Light";
NSString *const kSemiboldFontName = @"OpenSans-Semibold";

NSString *const kFirebaseUrl = @"https://neverdrinkalone.firebaseio.com";
NSUInteger const kUserBiographyCharsLimit = 50;

#pragma mark Walkthrough

CGFloat const kOnboardingBottomHeight = 42;
CGFloat const kOnboardingSkipButtonWidth = 100;

#pragma mark Authorization

CGFloat const kAuthorizationViewPadding = 20;

NSString *const kUserFirstNameKey = @"firstName";
NSString *const kUserLastNameKey = @"lastName";
NSString *const kUserEducationKey = @"education";
NSString *const kUserJobKey = @"job";
NSString *const kUserBirthdayKey = @"birthday";
NSString *const kUserGenderKey = @"gender";
NSString *const kUserBiographyKey = @"biography";
NSString *const kUserPictureKey = @"picture";
NSString *const kUserKarmaKey = @"karma";
NSString *const kUserIndustryKey = @"industry";
NSString *const kUserKey = @"user";
NSString *const kInterestKey = @"interest";
NSString *const kMeetingPlaceKey = @"meetingPlace";
NSString *const kTimeSlotKey = @"timeSlot";
NSString *const kMeetingKey = @"meeting";
NSString *const kMatchKey = @"match";
NSString *const kUserHasSeenKey = @"hasSeen";
NSString *const kUserHasAcceptedKey = @"hasAccepted";
NSString *const kUserHasRejectedKey = @"hasRejected";
NSString *const kUserHasMeetingScheduledKey = @"hasMeetingScheduled";
NSString *const kUserHasUndecidedMeetingKey = @"hasUndecidedMeeting";
NSString *const kConfirmedKey = @"confirmed";
NSString *const kCancelledKey = @"cancelled";
NSString *const kActiveKey = @"active";
NSString *const kInterestedInKey = @"interestedIn";
NSString *const kIsAdministratorKey = @"isAdministrator";
NSString *const kLastNotificationKey = @"lastNotification";
NSString *const kCanPostSelfieKey = @"canPostSelfie";
NSString *const kReloadKey = @"reload";
NSString *const kSelfieKey = @"selfie";
NSString *const kImagesKey = @"images";
NSString *const kUserDidFinishRegistrationKey = @"didFinishRegistration";
NSString *const kUserHasSeenTips = @"hasSeenTips";
NSInteger const kUserInitialKarma = 10;

CGFloat const kProfileHugePictureSize = 300;
CGFloat const kProfileBigPictureSize = 200;
CGFloat const kProfileSmallPictureSize = 100;

#pragma mark Profile Configuration

CGFloat const kProfileConfigurationViewPadding = 20;
CGFloat const kProfileConfigurationSpacing = 10;
CGFloat const kProfileConfigurationContinueButtonTopMargin = 20;
UIEdgeInsets const kProfileConfigurationContinueButtonPadding = {
  5, 20, 5, 20
};
UIEdgeInsets const kProfileConfigurationTextFieldPadding = {
  10, 0, 10, 0
};
CGFloat const kProfileConfigurationKeyboardTopMargin = 20;

#pragma mark Adding Preferences

CGFloat const kSearchBarTopMargin = 20;
CGFloat const kSearchBarHeight = 30;
CGSize const kSearchIconSize = {
  14, 14
};
UIEdgeInsets const kSearchTextFieldPadding = {
  5, 0, 5, 5
};
CGFloat const kPreferencesViewPadding = 10;
CGFloat const kPreferencesCollectionViewTopMargin = 20;
CGSize const kRefreshButtonSize = {
  220, 40
};
CGFloat const kRefreshButtonTopMargin = 20;

NSString *const kPreferencesObjectCellReuseIdentifier = @"PreferencesObjectCell";
CGFloat const kPreferencesObjectCellSpacing = 10;

UIEdgeInsets const kInterestCellPadding = {
  5, 10, 5, 10
};
CGSize const kInterestCellPlusIconSize = {
  8, 8
};
CGSize const kInterestCellCheckIconSize = {
  11, 8
};
CGFloat const kInterestCellCornerRadius = 15;

NSString *const kLocationLoadedNotification = @"locationLoaded";

NSString *const kFoursquareClientId = @"TJYHYMUOFKGQWVWOK3B5JISNEYMHTH5S42QTCQMCFZHB0WW0";
NSString *const kFoursquareClientSecret = @"M0HCMM5AXU35NU0SPMQY3IIJI2OPA2FT0YIM4AZ12QJ0IN0X";
NSString *const kFoursquareCoffeeShopId = @"4bf58dd8d48988d1e0931735";
NSString *const kFoursquareFoodId = @"4d4b7105d754a06374d81259";
NSInteger const kMeetingPlacesNDArbyRadius = 10000;
NSInteger const kMeetingPlacesCityRadius = 15000;

UIEdgeInsets const kMeetingPlaceCellPadding = {
  5, 12, 5, 12
};
CGSize const kMeetingPlaceCellPlusIconSize = {
  10, 10
};
CGSize const kMeetingPlaceCellCheckIconSize = {
  14, 10
};
CGFloat const kMeetingPlaceCellCornerRadius = 10;

CGFloat const kTimeSlotsCollectionViewTopMargin = 10;

UIEdgeInsets const kTimeSlotCellPadding = {
  10, 15, 10, 15
};
CGSize const kTimeSlotCellPlusIconSize = {
  12, 12
};
CGSize const kTimeSlotCellCheckIconSize = {
  17, 12
};
CGFloat const kTimeSlotCellCornerRadius = 10;
CGFloat const kTimeSlotCellHeight = 70;

CGFloat const kAlmatyCoordinatesLatitude = 43.2564f;
CGFloat const kAlmatyCoordinatesLongitude = 76.9444f;

#pragma mark Dashboard

CGFloat const kDashboardCardCornerRadius = 10;

#pragma mark Meeting

CGFloat const kMeetingViewPadding = 20;
CGFloat const kMeetingUserInfoViewHeight = 300;
CGFloat const kMeetingUserInfoSpacing = 10;
CGFloat const kMeetingUserInfoBorderWidth = 20;
CGSize const kMeetingCutoutSize = {
  25, 15
};

CGSize const kMeetingPlaceViewDisclosureIconSize = {
  10, 19
};

CGFloat const kBackdropBlurRadius = 14;
CGFloat const kBackdropBlurDarkeningRatio = 0.2f;
CGFloat const kBackdropBlurSaturationDeltaFactor = 1.4f;

#pragma mark Chats

CGFloat const kChatsCellHeight = 70;

#pragma mark Modal Views

CGFloat const kModalViewBlurRadius = 8;
CGFloat const kModalViewBlurDarkeningRatio = 0.25f;
CGFloat const kModalViewBlurSaturationDeltaFactor = 1.4f;
NSTimeInterval const kModalViewAnimationDuration = 0.4f;
