#import "NDAFirstProfileConfigurationViewController.h"

#import "ActionSheetPicker.h"
#import "CRGradientNavigationBar.h"
#import "DAKeyboardControl.h"
#import "NDAConstants.h"
#import "NDASecondProfileConfigurationViewController.h"
#import "NSDate+NDAHelpers.h"
#import "UIColor+NDAHelpers.h"
#import "UIColor+NDATints.h"
#import "UIFont+NDASizes.h"
#import "UIImage+NDAHelpers.h"
#import "UIView+AYUtils.h"
#import <Parse/Parse.h>

@interface NDAFirstProfileConfigurationViewController () <UITextFieldDelegate>

/**
 *  Text field for the user education property.
 */
@property (nonatomic) UITextField *educationTextField;
/**
 *  Text field for the user job property.
 */
@property (nonatomic) UITextField *jobTextField;
/**
 *  Text field for the user birthday property.
 */
@property (nonatomic) UITextField *birthdayTextField;
/**
 *  Text field for the user gender property.
 */
@property (nonatomic) UITextField *genderTextField;
/**
 *  Button allowing the user to continue with the registration process.
 */
@property (nonatomic) UIButton *continueButton;
/**
 *  Selected date for user birthday property.
 */
@property (nonatomic) NSDate *birthdayDate;
/**
 *  Selected index for user gender property.
 */
@property (nonatomic) NSInteger genderIndex;

@end

@implementation NDAFirstProfileConfigurationViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor whiteColor];
  self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];

  [self setUpTextFields];
  [self setUpContinueButton];
  [self.educationTextField becomeFirstResponder];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.navigationController.navigationBarHidden = NO;
  [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
  self.navigationItem.title = NSLocalizedString(@"Рассказать о себе (1/5)", nil);
  [(CRGradientNavigationBar *)self.navigationController.navigationBar setBarTintGradientColors:@[
     [UIColor nda_primaryColor],
     [UIColor nda_complementaryColor]
   ]];
}

#pragma mark Private

- (void)setUpTextFields {
  PFUser *currentUser = [PFUser currentUser];

  self.educationTextField = [[UITextField alloc] initWithFrame:CGRectMake(kProfileConfigurationViewPadding, kProfileConfigurationViewPadding, self.view.width - kProfileConfigurationViewPadding * 2, 0)];
  self.educationTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Университет", nil) attributes:@{ NSForegroundColorAttributeName : [UIColor nda_darkGrayColor] }];
  [self.educationTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
  [self stylizeTextField:self.educationTextField];
  if (currentUser[kUserEducationKey]) {
    self.educationTextField.text = currentUser[kUserEducationKey];
  }
  [self.view addSubview:self.educationTextField];

  self.jobTextField = [[UITextField alloc] initWithFrame:CGRectMake(kProfileConfigurationViewPadding, self.educationTextField.bottom + kProfileConfigurationSpacing, self.view.width - kProfileConfigurationViewPadding * 2, 0)];
  [self.jobTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
  self.jobTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Место работы", nil) attributes:@{ NSForegroundColorAttributeName : [UIColor nda_darkGrayColor] }];
  [self stylizeTextField:self.jobTextField];
  if (currentUser[kUserJobKey]) {
    self.jobTextField.text = currentUser[kUserJobKey];
  }
  [self.view addSubview:self.jobTextField];

  self.birthdayTextField = [[UITextField alloc] initWithFrame:CGRectMake(kAuthorizationViewPadding, self.jobTextField.bottom + kProfileConfigurationSpacing, (self.view.width - kAuthorizationViewPadding * 2 - kProfileConfigurationSpacing) / 2, 0)];
  self.birthdayTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Дата рождения", nil) attributes:@{ NSForegroundColorAttributeName : [UIColor nda_darkGrayColor] }];
  self.birthdayTextField.delegate = self;
  [self stylizeTextField:self.birthdayTextField];
  if (currentUser[kUserBirthdayKey]) {
    self.birthdayDate = (NSDate *)currentUser[kUserBirthdayKey];
    self.birthdayTextField.text = [self.birthdayDate birthdayDate];
  }
  [self.view addSubview:self.birthdayTextField];

  self.genderTextField = [[UITextField alloc] initWithFrame:CGRectMake(self.birthdayTextField.right + kProfileConfigurationSpacing, self.jobTextField.bottom + kProfileConfigurationSpacing, (self.view.width - kProfileConfigurationViewPadding * 2 - kProfileConfigurationSpacing) / 2, 0)];
  self.genderTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Пол", nil) attributes:@{ NSForegroundColorAttributeName : [UIColor nda_darkGrayColor] }];
  self.genderTextField.delegate = self;
  [self stylizeTextField:self.genderTextField];
  if (currentUser[kUserGenderKey]) {
    self.genderIndex = [currentUser[kUserGenderKey] integerValue];
    if (self.genderIndex == 0) {
      self.genderTextField.text = NSLocalizedString(@"Я парень", nil);
    } else {
      self.genderTextField.text = NSLocalizedString(@"Я девушка", nil);
    }
  }
  [self.view addSubview:self.genderTextField];

  self.view.keyboardTriggerOffset = kKeyboardTriggerOffset;
  [self.view addKeyboardPanningWithFrameBasedActionHandler:nil constraintBasedActionHandler:nil];
  UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
  [self.view addGestureRecognizer:tapGestureRecognizer];
}

- (void)hideKeyboard {
  [self.view endEditing:YES];
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
  self.continueButton.frame = CGRectMake((self.view.width - continueButtonSize.width) / 2, self.genderTextField.bottom + kProfileConfigurationContinueButtonTopMargin, continueButtonSize.width, continueButtonSize.height);
  self.continueButton.clipsToBounds = YES;
  self.continueButton.layer.cornerRadius = continueButtonSize.height / 2;
  [self.continueButton addTarget:self action:@selector(continueButtonTapped) forControlEvents:UIControlEventTouchUpInside];

  if (self.educationTextField.text.length == 0 || self.jobTextField.text.length == 0 || self.birthdayTextField.text.length == 0 || self.genderTextField.text.length == 0) {
    [self setContinueButtonEnabled:NO];
  }

  [self.view addSubview:self.continueButton];
}

- (void)stylizeTextField:(UITextField *)textField {
  textField.textColor = [UIColor nda_textColor];
  textField.font = [UIFont fontWithName:kRegularFontName size:[UIFont largeTextFontSize]];
  textField.clearButtonMode = UITextFieldViewModeWhileEditing;
  textField.height = (kProfileConfigurationTextFieldPadding.top + [textField.placeholder sizeWithAttributes:@{ NSFontAttributeName : textField.font }].height + kProfileConfigurationTextFieldPadding.bottom);
  CALayer *border = [CALayer layer];
  border.frame = CGRectMake(0, textField.height - 1, textField.width, 1);
  border.backgroundColor = [UIColor nda_darkGrayColor].CGColor;
  [textField.layer addSublayer:border];
}

- (void)checkTextFields {
  if (self.educationTextField.text.length > 0 && self.jobTextField.text.length > 0 && self.birthdayTextField.text.length > 0 && self.genderTextField.text.length > 0) {
    [self setContinueButtonEnabled:YES];
  } else {
    [self setContinueButtonEnabled:NO];
  }
}

- (void)setContinueButtonEnabled:(BOOL)enabled {
  self.continueButton.enabled = enabled;
  self.continueButton.alpha = enabled ? 1.0f : 0.5f;
}

- (void)openBirthdayPicker {
  [self.view endEditing:YES];
  [ActionSheetDatePicker showPickerWithTitle:@"Ваша дата рождения" datePickerMode:UIDatePickerModeDate selectedDate:self.birthdayDate ? : [NSDate date] doneBlock:^(ActionSheetDatePicker *picker, id selectedDate, id origin) {
    self.birthdayDate = (NSDate *)selectedDate;
    self.birthdayTextField.text = [self.birthdayDate birthdayDate];
    [self checkTextFields];
  } cancelBlock:nil origin:self.view];
}

- (void)openGenderPicker {
  [self.view endEditing:YES];
  [ActionSheetStringPicker showPickerWithTitle:NSLocalizedString(@"Ваш пол", nil) rows:@[NSLocalizedString(@"Мужской", nil), NSLocalizedString(@"Женский", nil)] initialSelection:self.genderIndex doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {
    self.genderIndex = selectedIndex;
    if (self.genderIndex == 0) {
      self.genderTextField.text = NSLocalizedString(@"Я парень", nil);
    } else {
      self.genderTextField.text = NSLocalizedString(@"Я девушка", nil);
    }
    [self checkTextFields];
  } cancelBlock:nil origin:self.view];
}

- (void)continueButtonTapped {
  PFUser *currentUser = [PFUser currentUser];

  if (![currentUser[kUserEducationKey] isEqualToString:self.educationTextField.text]) {
    DDLogVerbose(@"Saved user education");
    currentUser[kUserEducationKey] = self.educationTextField.text;
  }
  if (![currentUser[kUserJobKey] isEqualToString:self.jobTextField.text]) {
    DDLogVerbose(@"Saved user job");
    currentUser[kUserJobKey] = self.jobTextField.text;
  }
  if (![currentUser[kUserBirthdayKey] isEqualToDate:self.birthdayDate]) {
    DDLogVerbose(@"Saved user birthday");
    currentUser[kUserBirthdayKey] = self.birthdayDate;
  }
  if (![currentUser[kUserGenderKey] isEqualToValue:@(self.genderIndex)]) {
    DDLogVerbose(@"Saved user gender");
    currentUser[kUserGenderKey] = @(self.genderIndex);
  }
  [currentUser saveEventually];

  [self.navigationController pushViewController:[NDASecondProfileConfigurationViewController new] animated:YES];
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
  if (textField == self.birthdayTextField) {
    [self openBirthdayPicker];
  } else if (textField == self.genderTextField) {
    [self openGenderPicker];
  }
  return NO;
}

- (void)textFieldDidChange:(UITextField *)textField {
  [self checkTextFields];
}

@end
