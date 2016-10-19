#import "NDASettingsViewController.h"

#import "AYAppStore.h"
#import "AYFeedback.h"
#import "JTProgressHUD.h"
#import "NDAActionSheet.h"
#import "NDAAlertManager.h"
#import "NDAAuthorizationViewController.h"
#import "NDAConstants.h"
#import "NDAEditBiographyViewController.h"
#import "NDALoadingImageView.h"
#import "NDAMacros.h"
#import "NDAPreferencesManager.h"
#import "NDASettingsMenuView.h"
#import "NDASettingsViewButton.h"
#import "PFUser+NDAHelpers.h"
#import "UIColor+NDATints.h"
#import "UIFont+NDASizes.h"
#import "UIImage+NDAHelpers.h"
#import "UIImagePickerController+Edit.h"
#import "UILabel+NDAHelpers.h"
#import "UIView+AYUtils.h"
#import <MessageUI/MessageUI.h>
#import <MZFormSheetPresentationController/MZFormSheetPresentationViewController.h>
#import <Parse/Parse.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

static CGFloat const kSettingsViewPadding = 15;
static CGFloat const kSettingsNameLabelTopPadding = 15;
static UIEdgeInsets const kMenuSeparatorMargin = {
  20, 40, 15, 40
};
static CGFloat const kSettingsMenuViewItemHeight = 50;
static NSString *const kAppId = @"";

@interface NDASettingsViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, MFMailComposeViewControllerDelegate, NDASettingsMenuViewDelegate, NDAEditBiographyViewControllerDelegate>

@property (nonatomic) MFMailComposeViewController *mailComposeViewController;
@property (nonatomic) NDAAlertManager *alertManager;
@property (nonatomic) NDALoadingImageView *profilePictureImageView;
@property (nonatomic) NDASettingsMenuView *menuView;
@property (nonatomic) NDASettingsViewButton *rateButton;
@property (nonatomic) NDASettingsViewButton *shareButton;
@property (nonatomic) UILabel *biographyLabel;
@property (nonatomic) UILabel *nameLabel;
@property (nonatomic) UIView *menuSeparator;
@property (nonatomic) UIView *profilePictureImageViewBorder;

@end

@implementation NDASettingsViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.alertManager = [[NDAAlertManager alloc] initWithRootViewController:self];

  [self setUpProfilePicture];
  [self setUpLabels];
  [self setUpMenuSeparator];
  [self setUpMenuButtons];
  [self setUpBottomButtons];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.delegate.navigationItem.title = NSLocalizedString(@"Настройки", nil);

  UIButton *dashboardIcon = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
  [dashboardIcon setImage:[[UIImage imageNamed:@"CrossIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
  dashboardIcon.tintColor = [UIColor whiteColor];
  dashboardIcon.rac_command = [[RACCommand alloc] initWithSignalBlock:^(id _) {
    [self.delegate switchView];
    return [RACSignal empty];
  }];
  UIBarButtonItem *dashboardButtonItem = [[UIBarButtonItem alloc] initWithCustomView:dashboardIcon];
  [self.delegate.navigationItem setLeftBarButtonItem:dashboardButtonItem];
  [self.delegate.navigationItem setRightBarButtonItem:nil];
}

#pragma mark Private

- (void)setUpProfilePicture {
  CGFloat profilePictureSize = IS_IPHONE_4_OR_LESS ? 50 : kProfileSmallPictureSize;

  self.profilePictureImageView = [[NDALoadingImageView alloc] initWithFrame:CGRectMake((self.view.width - profilePictureSize) / 2, kSettingsViewPadding, profilePictureSize, profilePictureSize)];
  self.profilePictureImageView.spinnerStyle = UIActivityIndicatorViewStyleWhite;
  self.profilePictureImageView.contentMode = UIViewContentModeScaleAspectFill;
  self.profilePictureImageView.userInteractionEnabled = YES;
  self.profilePictureImageView.clipsToBounds = YES;
  self.profilePictureImageView.layer.cornerRadius = profilePictureSize / 2;

  self.profilePictureImageViewBorder = [[UIView alloc] initWithFrame:CGRectMake(self.profilePictureImageView.left - 1 / [UIScreen mainScreen].scale, self.profilePictureImageView.top - 1 / [UIScreen mainScreen].scale, self.profilePictureImageView.width + 2 / [UIScreen mainScreen].scale, self.profilePictureImageView.height + 2 / [UIScreen mainScreen].scale)];
  self.profilePictureImageViewBorder.clipsToBounds = YES;
  self.profilePictureImageViewBorder.layer.cornerRadius = self.profilePictureImageViewBorder.width / 2;
  self.profilePictureImageViewBorder.backgroundColor = [UIColor whiteColor];
  self.profilePictureImageViewBorder.alpha = 0.75f;

  UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(profilePictureTapped)];
  [self.profilePictureImageView addGestureRecognizer:tapGestureRecognizer];

  [self.profilePictureImageView startSpinning];
  [[[[PFUser currentUser] getProfilePicture] deliverOn:RACScheduler.mainThreadScheduler] subscribeNext:^(UIImage *image) {
    [self.profilePictureImageView stopSpinning];
    self.profilePictureImageView.image = image;
  } error:^(NSError *error) {
    DDLogError(@"Error occured while getting user profile picture: %@", error);
  }];

  [self.view addSubview:self.profilePictureImageViewBorder];
  [self.view addSubview:self.profilePictureImageView];
}

- (void)setUpLabels {
  self.nameLabel = [UILabel new];
  self.nameLabel.text = [NSString stringWithFormat:@"%@ %@", [PFUser currentUser][kUserFirstNameKey], [PFUser currentUser][kUserLastNameKey]];
  self.nameLabel.font = [UIFont fontWithName:kLightFontName size:[UIFont largeTextFontSize]];
  self.nameLabel.textColor = [UIColor whiteColor];
  CGSize nameLabelSize = [self.nameLabel.text sizeWithAttributes:@{ NSFontAttributeName : self.nameLabel.font }];
  self.nameLabel.frame = CGRectMake((self.view.width - nameLabelSize.width) / 2, self.profilePictureImageView.bottom + kSettingsNameLabelTopPadding, nameLabelSize.width, nameLabelSize.height);

  [self.view addSubview:self.nameLabel];

  self.biographyLabel = [[UILabel alloc] initWithFrame:CGRectMake(kSettingsViewPadding, self.nameLabel.bottom + 5, self.view.width - kSettingsViewPadding * 2, 0)];
  self.biographyLabel.userInteractionEnabled = YES;
  self.biographyLabel.text = [[PFUser currentUser][kUserBiographyKey] stringByAppendingString:@" ✎"];
  self.biographyLabel.font = [UIFont fontWithName:kItalicFontName size:[UIFont mediumTextFontSize]];
  self.biographyLabel.textColor = [UIColor whiteColor];
  self.biographyLabel.textAlignment = NSTextAlignmentCenter;
  self.biographyLabel.numberOfLines = 0;
  [self.biographyLabel setFrameToFitWithHeightLimit:0];
  [self.view addSubview:self.biographyLabel];

  UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(biographyTapped)];
  [self.biographyLabel addGestureRecognizer:tapGestureRecognizer];
}

- (void)setUpMenuSeparator {
  self.menuSeparator = [[UIView alloc] initWithFrame:CGRectMake(kSettingsViewPadding + kMenuSeparatorMargin.left, self.biographyLabel.bottom + kMenuSeparatorMargin.top, self.view.width - kSettingsViewPadding * 2 - kMenuSeparatorMargin.left - kMenuSeparatorMargin.right, 1 / [UIScreen mainScreen].scale)];
  self.menuSeparator.backgroundColor = [UIColor colorWithWhite:1 alpha:0.25f];

  [self.view addSubview:self.menuSeparator];
}

- (void)setUpMenuButtons {
  NSArray *titles = @[
    NSLocalizedString(@"Предпочтения", nil),
    NSLocalizedString(@"Отправить отзыв", nil),
    NSLocalizedString(@"Выйти", nil)
  ];
  CGFloat itemHeight = IS_IPHONE_4_OR_LESS ? 44 : kSettingsMenuViewItemHeight;

  self.menuView = [[NDASettingsMenuView alloc] initWithFrame:CGRectMake(kSettingsViewPadding, self.menuSeparator.bottom + kMenuSeparatorMargin.bottom, self.view.width - kSettingsViewPadding * 2, itemHeight * titles.count) images:@[] titles:titles];
  self.menuView.delegate = self;
  [self.view addSubview:self.menuView];
}

- (void)setUpBottomButtons {
  self.shareButton = [[NDASettingsViewButton alloc] initWithFrame:CGRectMake(0, 0, self.view.width / 2 - kSettingsViewPadding, 0) image:[UIImage imageNamed:@"ShareIcon"] buttonTitle:NSLocalizedString(@"Поделиться", nil)];
  self.shareButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^(id _) {
    NSString *appStoreLink = [NSString stringWithFormat:@"http://itunes.apple.com/app/id%@", kAppId];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[[NSString stringWithFormat:NSLocalizedString(@"Never Drink Alone - Одно знакомство в день с самыми крутыми людьми в Алматы! %@", nil), appStoreLink]] applicationActivities:nil];
    [self presentViewController:activityViewController animated:YES completion:nil];
    return [RACSignal empty];
  }];

  self.rateButton = [[NDASettingsViewButton alloc] initWithFrame:self.shareButton.frame image:[UIImage imageNamed:@"StarIcon"] buttonTitle:NSLocalizedString(@"Оценить", nil)];
  self.rateButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^(id _) {
    [AYAppStore openAppStoreReviewForApp:kAppId];
    return [RACSignal empty];
  }];

  self.shareButton.centerX = self.view.width / 4 + kSettingsViewPadding / 2;
  self.rateButton.centerX = self.view.width * 3 / 4 - kSettingsViewPadding / 2;
  for (NDASettingsViewButton *button in @[self.shareButton, self.rateButton]) {
    button.bottom = self.view.height - kSettingsViewPadding;
    button.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
    [self.view addSubview:button];
  }
}

- (void)biographyTapped {
  NDAEditBiographyViewController *editBiographyViewController = [NDAEditBiographyViewController new];

  editBiographyViewController.delegate = self;
  UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:editBiographyViewController];
  navigationController.navigationBar.tintColor = [UIColor nda_spaceGrayColor];
  MZFormSheetPresentationViewController *formSheetController = [[MZFormSheetPresentationViewController alloc] initWithContentViewController:navigationController];
  formSheetController.presentationController.contentViewSize = [NDAEditBiographyViewController viewSize];

  [self presentViewController:formSheetController animated:YES completion:nil];
}

- (void)profilePictureTapped {
  [[self.alertManager actionSheetWithCropMode:DZNPhotoEditorViewControllerCropModeCircular] show];
}

- (void)editPreferences {
  [self.navigationController pushViewController:
   [[NDAPreferencesManager sharedInstance] firstViewController] animated:YES];
}

- (void)sendFeedback {
  if ([MFMailComposeViewController canSendMail]) {
    AYFeedback *feedback = [AYFeedback new];
    self.mailComposeViewController = [MFMailComposeViewController new];
    self.mailComposeViewController.mailComposeDelegate = self;
    self.mailComposeViewController.toRecipients = @[@"we@neverdrinkaloneapp.com"];
    self.mailComposeViewController.subject = feedback.subject;
    [self.mailComposeViewController setMessageBody:feedback.messageWithMetaData isHTML:NO];
    [self presentViewController:self.mailComposeViewController animated:YES completion:nil];
  } else {
    [self.alertManager showNotificationWithText:NSLocalizedString(@"К сожалению, у вас не настроен почтовый сервис", nil) color:[UIColor nda_accentColor]];
  }
}

- (void)logOut {
  [JTProgressHUD showWithTransition:JTProgressHUDTransitionFade];
  [PFUser logOutInBackgroundWithBlock:^(NSError *error) {
    [JTProgressHUD hide];
    if (!error) {
      [[PFUser currentUser] clearCache];
      [self.navigationController pushViewController:[NDAAuthorizationViewController new] animated:YES];
    } else {
      [self.alertManager showNotificationWithText:NSLocalizedString(@"Что-то пошло не так. Попробуйте чуть позже", nil) color:[UIColor nda_accentColor]];
    }
  }];
}

#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
  UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
  self.profilePictureImageView.image = [chosenImage getRoundedRectImage];
  [[[PFUser currentUser] saveProfilePicture:chosenImage] subscribeError:^(NSError *error) {
    DDLogError(@"Error occured while saving user profile picture: %@", error);
  } completed:^{
    DDLogVerbose(@"Saved user profile picture");
  }];
  [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
  [self dismissViewControllerAnimated:YES completion:^{
    if (result == MFMailComposeResultSent) {
      [self.alertManager showNotificationWithText:NSLocalizedString(@"Спасибо! Ваш отзыв был отправлен", nil)
       color:[UIColor nda_greenColor]];
    }
  }];
}

#pragma mark NDASettingsMenuViewDelegate

- (void)menuView:(NDASettingsMenuView *)menuView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  switch (indexPath.row) {
    case 0:
      [self editPreferences];
      break;
    case 1:
      [self sendFeedback];
      break;
    case 2:
      [self logOut];
      break;
    default:
      break;
  }
}

#pragma mark NDAEditBiographyViewControllerDelegate

- (void)didFinishEditingBiographyWithText:(NSString *)text {
  [PFUser currentUser][kUserBiographyKey] = text;
  [[PFUser currentUser] saveEventually];
  self.biographyLabel.text = [text stringByAppendingString:@" ✎"];
  [self.biographyLabel setFrameToFitWithHeightLimit:0];
  self.menuSeparator.top = self.biographyLabel.bottom + kMenuSeparatorMargin.top;
  self.menuView.top = self.menuSeparator.bottom + kMenuSeparatorMargin.bottom;
}

@end
