#import "NDASecondProfileConfigurationViewController.h"

#import "DAKeyboardControl.h"
#import "NDAActionSheet.h"
#import "NDAAlertManager.h"
#import "NDAConstants.h"
#import "NDALoadingImageView.h"
#import "NDAMacros.h"
#import "NDAPreferencesManager.h"
#import "NSString+NDAHelpers.h"
#import "PFUser+NDAHelpers.h"
#import "UIColor+NDAHelpers.h"
#import "UIColor+NDATints.h"
#import "UIFont+NDASizes.h"
#import "UIImage+NDAHelpers.h"
#import "UIImagePickerController+Edit.h"
#import "UIView+AYUtils.h"
#import <JVFloatLabeledTextField/JVFloatLabeledTextView.h>
#import <Parse/Parse.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface NDASecondProfileConfigurationViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextViewDelegate>

/**
 *  Image view with user's profile picture. If the user signed up with Facebook, then it contains the image taken from there.
 */
@property (nonatomic) NDALoadingImageView *profilePictureImageView;
/**
 *  Text view for user biography property.
 */
@property (nonatomic) JVFloatLabeledTextView *biographyTextView;
/**
 *  Layer for border under the biography text view.
 */
@property (nonatomic) CALayer *biographyTextViewBorder;
/**
 *  Button allowing the user to continue with the registration process.
 */
@property (nonatomic) UIButton *continueButton;
/**
 *  Indicates whether or not the user has a profile picture set.
 */
@property (nonatomic) BOOL hasProfilePicture;
/**
 *  Frame of the keyboard with its size reflecting the visible size.
 */
@property (nonatomic) CGRect currentKeyboardFrame;
/**
 *  Indicates whether or not the view should stay fixed when the keyboard disappears.
 */
@property (nonatomic) BOOL forceTop;
/**
 *  Original (uncropped) profile picture image.
 */
@property (nonatomic) UIImage *originalProfilePictureImage;
/**
 *  Alert manager to display notifications.
 */
@property (nonatomic) NDAAlertManager *alertManager;

@end

@implementation NDASecondProfileConfigurationViewController {
  BOOL _centered;
}

#pragma mark Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor whiteColor];
  self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
  self.alertManager = [[NDAAlertManager alloc] initWithRootViewController:self];
  [self setUpProfilePicture];
  [self setUpBiographyTextView];
  [self setUpContinueButton];
  [self setUpKeyboard];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.navigationItem.title = NSLocalizedString(@"Рассказать о себе (2/5)", nil);
  self.forceTop = NO;
  [self fixBiographyTextView];
  if (!_centered) {
    _centered = YES;
    [self centerLayout];
  }
}

- (void)dealloc {
  [self.view removeKeyboardControl];
}

#pragma mark Private

- (void)setUpProfilePicture {
  CGFloat profilePictureSize = (IS_IPHONE_6 || IS_IPHONE_6P) ? kProfileHugePictureSize : kProfileBigPictureSize;

  self.profilePictureImageView = [[NDALoadingImageView alloc] initWithFrame:CGRectMake((self.view.width - profilePictureSize) / 2, 0, profilePictureSize, profilePictureSize)];
  self.profilePictureImageView.contentMode = UIViewContentModeScaleAspectFill;
  self.profilePictureImageView.userInteractionEnabled = YES;

  UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(profilePictureTapped)];
  [self.profilePictureImageView addGestureRecognizer:tapGestureRecognizer];
  self.hasProfilePicture = NO;

  if ([PFUser currentUser][kUserPictureKey]) {
    self.hasProfilePicture = YES;
    [self.profilePictureImageView startSpinning];
    [[[[PFUser currentUser] getProfilePicture] deliverOn:RACScheduler.mainThreadScheduler] subscribeNext:^(UIImage *image) {
      [self.profilePictureImageView stopSpinning];
      self.originalProfilePictureImage = image;
      self.profilePictureImageView.image = image;
    } error:^(NSError *error) {
      DDLogError(@"Error occured while getting user profile picture: %@", error);
    }];
  } else {
    self.profilePictureImageView.image = [[UIImage imageNamed:@"ProfilePicturePlaceholder"] getRoundedRectImage];
  }
  [self.view addSubview:self.profilePictureImageView];
}

- (void)setUpBiographyTextView {
  self.biographyTextView = [[JVFloatLabeledTextView alloc] initWithFrame:CGRectMake(kProfileConfigurationViewPadding, self.profilePictureImageView.bottom + kProfileConfigurationSpacing, self.view.width - kProfileConfigurationViewPadding * 2, 0)];
  self.biographyTextView.placeholder = NSLocalizedString(@"Биография (50 символов)", nil);
  self.biographyTextView.placeholderTextColor = [UIColor nda_darkGrayColor];
  self.biographyTextView.textColor = [UIColor nda_textColor];
  self.biographyTextView.font = [UIFont fontWithName:kRegularFontName size:[UIFont largeTextFontSize]];
  self.biographyTextView.floatingLabelFont = [UIFont fontWithName:kSemiboldFontName size:[UIFont extraSmallTextFontSize]];
  self.biographyTextView.floatingLabelTextColor = [UIColor nda_accentColor];
  self.biographyTextView.delegate = self;
  if ([PFUser currentUser][kUserBiographyKey]) {
    self.biographyTextView.text = [PFUser currentUser][kUserBiographyKey];
  }
  self.biographyTextView.height = [self.biographyTextView.text.length > 0 ? self.biographyTextView.text : NSLocalizedString(@"Биография (50 символов)", nil) sizeWithAttributes:@{ NSFontAttributeName : self.biographyTextView.font }].height + kFloatingLabelSpacing +  [NSLocalizedString(@"Биография (50 символов)", nil) sizeWithAttributes:@{ NSFontAttributeName : self.biographyTextView.floatingLabelFont }].height;

  self.biographyTextViewBorder = [CALayer layer];
  self.biographyTextViewBorder.frame = CGRectMake(0, self.biographyTextView.height - 1, self.biographyTextView.width, 1);
  self.biographyTextViewBorder.backgroundColor = [UIColor nda_darkGrayColor].CGColor;
  [self.biographyTextView.layer addSublayer:self.biographyTextViewBorder];

  [self.view addSubview:self.biographyTextView];
}

- (void)setUpContinueButton {
  self.continueButton = [UIButton new];
  [self.continueButton setTitle:NSLocalizedString(@"Дальше", nil) forState:UIControlStateNormal];
  [self.continueButton setBackgroundImage:[UIImage imageWithColor:[UIColor nda_greenColor]] forState:UIControlStateNormal];
  [self.continueButton setBackgroundImage:[UIImage imageWithColor:[[UIColor nda_greenColor] darkerColor:0.1f]] forState:UIControlStateHighlighted];
  [self.continueButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  self.continueButton.titleLabel.font = [UIFont fontWithName:kLightFontName size:[UIFont mediumButtonFontSize]];
  CGSize continueButtonSize = [self.continueButton.titleLabel.text sizeWithAttributes:@{ NSFontAttributeName : self.continueButton.titleLabel.font }];
  continueButtonSize.width += kProfileConfigurationContinueButtonPadding.left + kProfileConfigurationContinueButtonPadding.right;
  continueButtonSize.height += kProfileConfigurationContinueButtonPadding.top + kProfileConfigurationContinueButtonPadding.bottom;
  self.continueButton.frame = CGRectMake((self.view.width - continueButtonSize.width) / 2, self.biographyTextView.bottom + kProfileConfigurationContinueButtonTopMargin, continueButtonSize.width, continueButtonSize.height);
  self.continueButton.clipsToBounds = YES;
  self.continueButton.layer.cornerRadius = continueButtonSize.height / 2;
  [self.continueButton addTarget:self action:@selector(continueButtonTapped) forControlEvents:UIControlEventTouchUpInside];

  if (self.biographyTextView.text.length == 0 || !self.hasProfilePicture) {
    [self setContinueButtonEnabled:NO];
  }
  [self.view addSubview:self.continueButton];
}

- (void)setUpKeyboard {
  self.view.keyboardTriggerOffset = kKeyboardTriggerOffset;
  __weak id weakSelf = self;
  [self.view addKeyboardPanningWithFrameBasedActionHandler:^(CGRect keyboardFrameInView, BOOL opening, BOOL closing) {
    CGRect keyboardFrame = CGRectMake(0, 0, CGRectGetWidth(keyboardFrameInView), self.view.height - CGRectGetMinY(keyboardFrameInView));
    [weakSelf setCurrentKeyboardFrame:keyboardFrame];
    if (![weakSelf forceTop]) {
      if (closing) {
        [weakSelf centerLayout];
      } else {
        [weakSelf topLayout];
      }
    }
  } constraintBasedActionHandler:nil];
  UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
  [self.view addGestureRecognizer:tapGestureRecognizer];
}

- (void)hideKeyboard {
  [self.view endEditing:YES];
}

- (void)profilePictureTapped {
  [self.view hideKeyboard];
  [self performSelector:@selector(showActionSheet) withObject:nil afterDelay:0.4f];
}

- (void)showActionSheet {
  [[self.alertManager actionSheetWithCropMode:DZNPhotoEditorViewControllerCropModeCircular] show];
}

- (void)showImagePicker:(UIImagePickerController *)picker {
  picker.delegate = self;
  picker.allowsEditing = YES;
  picker.cropMode = DZNPhotoEditorViewControllerCropModeCircular;

  self.forceTop = YES;
  [self presentViewController:picker animated:YES completion:nil];
}

- (void)continueButtonTapped {
  PFUser *currentUser = [PFUser currentUser];

  [[[PFUser currentUser] saveProfilePicture:self.originalProfilePictureImage] subscribeError:^(NSError *error) {
    DDLogError(@"Error occured while saving user profile picture: %@", error);
  } completed:^{
    DDLogVerbose(@"Saved user profile picture");
  }];
  if (![currentUser[kUserBiographyKey] isEqualToString:self.biographyTextView.text]) {
    DDLogVerbose(@"Saved user biography");
    currentUser[kUserBiographyKey] = self.biographyTextView.text;
  }
  [currentUser saveEventually];

  self.forceTop = YES;
  [self.navigationController pushViewController:[[NDAPreferencesManager sharedInstance] firstViewController] animated:YES];
}

- (void)setContinueButtonEnabled:(BOOL)enabled {
  self.continueButton.enabled = enabled;
  self.continueButton.alpha = enabled ? 1 : 0.5f;
}

- (void)centerLayout {
  [self centerLayout:YES];
}

- (void)centerLayout:(BOOL)animated {
  CGFloat profilePictureSize = (IS_IPHONE_6 || IS_IPHONE_6P) ? kProfileHugePictureSize : kProfileBigPictureSize;
  CGRect oldProfilePictureImageViewFrame = self.profilePictureImageView.frame;
  CGRect newProfilePictureImageViewFrame = CGRectMake((self.view.width - profilePictureSize) / 2, CGRectGetMaxY(oldProfilePictureImageViewFrame) - profilePictureSize, profilePictureSize, profilePictureSize);

  if (animated) {
    [UIView animateWithDuration:0.2 animations:^{
      self.profilePictureImageView.frame = newProfilePictureImageViewFrame;
      self.profilePictureImageView.spinner.center = CGPointMake(CGRectGetMidX(self.profilePictureImageView.bounds), CGRectGetMidY(self.profilePictureImageView.bounds));
    } completion:^(BOOL finished) {
      CGFloat offset = [self offsetForCenterLayout];
      [UIView animateWithDuration:0.1 animations:^{
        for (UIView *view in @[self.profilePictureImageView, self.biographyTextView, self.continueButton]) {
          view.top += offset;
        }
      }];
    }];
  } else {
    self.profilePictureImageView.frame = newProfilePictureImageViewFrame;
    self.profilePictureImageView.spinner.center = CGPointMake(CGRectGetMidX(self.profilePictureImageView.bounds), CGRectGetMidY(self.profilePictureImageView.bounds));
    CGFloat offset = [self offsetForCenterLayout];
    for (UIView *view in @[self.profilePictureImageView, self.biographyTextView, self.continueButton]) {
      view.top += offset;
    }
  }
}

- (CGFloat)offsetForCenterLayout {
  CGFloat totalHeight = self.continueButton.bottom - self.profilePictureImageView.top;

  return (self.view.height - totalHeight) / 2 - self.profilePictureImageView.top;
}

- (void)topLayout {
  CGFloat preKeyboardHeight = self.view.height - kProfileConfigurationViewPadding - CGRectGetHeight(self.currentKeyboardFrame) - kProfileConfigurationKeyboardTopMargin;
  CGFloat heightWithoutProfilePicture = kProfileConfigurationSpacing + self.continueButton.bottom - self.biographyTextView.top;
  CGFloat maxProfilePictureSize = (IS_IPHONE_6 || IS_IPHONE_6P) ? kProfileHugePictureSize : kProfileBigPictureSize;
  CGFloat profilePictureSize = preKeyboardHeight - heightWithoutProfilePicture;
  CGFloat additionalDiff = 0;

  if (profilePictureSize > maxProfilePictureSize) {
    CGRect offsetProfilePictureImageViewFrame = CGRectOffset(self.profilePictureImageView.frame, 0, [self offsetForCenterLayout]);
    if (self.profilePictureImageView.top >= CGRectGetMinY(offsetProfilePictureImageViewFrame)) {
      return;
    }
    additionalDiff = profilePictureSize - maxProfilePictureSize;
    profilePictureSize = maxProfilePictureSize;
  } else if (profilePictureSize < 50) {
    additionalDiff = -kProfileConfigurationSpacing;
    profilePictureSize = 0;
  }
  CGRect oldProfilePictureImageViewFrame = self.profilePictureImageView.frame;
  CGRect newProfilePictureImageViewFrame = CGRectMake((self.view.width - profilePictureSize) / 2, CGRectGetMaxY(oldProfilePictureImageViewFrame) - profilePictureSize, profilePictureSize, profilePictureSize);
  self.profilePictureImageView.frame = newProfilePictureImageViewFrame;
  self.profilePictureImageView.spinner.center = CGPointMake(CGRectGetMidX(self.profilePictureImageView.bounds), CGRectGetMidY(self.profilePictureImageView.bounds));
  CGFloat offset = -(self.profilePictureImageView.top - kProfileConfigurationViewPadding - additionalDiff);
  for (UIView *view in @[self.profilePictureImageView, self.biographyTextView, self.continueButton]) {
    view.top += offset;
  }
}

#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
  UIImage *chosenImage = info[UIImagePickerControllerEditedImage];

  self.originalProfilePictureImage = chosenImage;
  self.profilePictureImageView.image = [chosenImage getRoundedRectImage];
  self.hasProfilePicture = YES;
  [self setContinueButtonEnabled:self.biographyTextView.text.length > 0];
  [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
  if (textView != self.biographyTextView) {
    return YES;
  }
  if ([text isEqualToString:@"\n"]) {
    return NO;
  }
  if ([textView.text stringByAppendingString:text].length > kUserBiographyCharsLimit) {
    return NO;
  }

  return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
  if (textView != self.biographyTextView) {
    return;
  }
  [self setContinueButtonEnabled:(textView.text.length > 0 && self.hasProfilePicture)];

  if (textView.text.length > 0) {
    self.biographyTextView.placeholder = [NSString stringWithFormat:NSLocalizedString(@"Биография (%@ %@ %@)", nil), [NSString getNumEnding:(NSInteger)(50 - textView.text.length) endings:@[@"остался", @"осталось", @"осталось"]], @(50 - textView.text.length), [NSString getNumEnding:(NSInteger)(50 - textView.text.length) endings:@[@"символ", @"символа", @"символов"]]];
  } else {
    self.biographyTextView.placeholder = NSLocalizedString(@"Биография (50 символов)", nil);
  }
  [self fixBiographyTextView];
}

- (void)fixBiographyTextView {
  CGFloat newHeight = [self.biographyTextView.text sizeWithFont:self.biographyTextView.font width:self.biographyTextView.width].height + kFloatingLabelSpacing + [self.biographyTextView.placeholder sizeWithAttributes:@{ NSFontAttributeName : self.biographyTextView.floatingLabelFont }].height;

  if (newHeight != self.biographyTextView.height) {
    self.biographyTextView.height = newHeight;
    self.biographyTextViewBorder.frame = CGRectMake(0, self.biographyTextView.height - 1, self.biographyTextView.width, 1);
    self.continueButton.top = self.biographyTextView.bottom + kProfileConfigurationContinueButtonTopMargin;
    [self topLayout];
  }
}

@end
