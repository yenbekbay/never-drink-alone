#import "NDAEmailAuthorizationViewController.h"

#import "DAKeyboardControl.h"
#import "JTProgressHUD.h"
#import "NDAConstants.h"
#import "NDALoginViewController.h"
#import "NDAMainPageViewController.h"
#import "NDAPermissionsViewController.h"
#import "NDASignUpViewController.h"
#import "UIColor+NDAHelpers.h"
#import "UIColor+NDATints.h"
#import "UIFont+NDASizes.h"
#import "UIImage+NDAHelpers.h"
#import "UIView+AYUtils.h"
#import <Parse/Parse.h>

static CGFloat const kEmailAuthorizationTextFieldSpacing = 10;
static UIEdgeInsets const kEmailAuthorizationButtonPadding = {
  5, 20, 5, 20
};
static CGFloat const kEmailAuthorizationActionButtonTopMargin = 20;
static UIEdgeInsets const kEmailAuthorizationTextFieldPadding = {
  10, 0, 10, 0
};
static CGFloat const kPasswordResetButtonTopMargin = 10;
static UIEdgeInsets const kPasswordResetButtonPadding = {
  5, 10, 5, 10
};

@interface NDAEmailAuthorizationViewController ()

/**
 *  Button that calls the action (login or signup)
 */
@property (nonatomic) UIButton *actionButton;
/**
 *  Button that allows the user to reset his password.
 */
@property (nonatomic) UIButton *passwordResetButton;

@end

@implementation NDAEmailAuthorizationViewController

#pragma mark Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor whiteColor];
  self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
  self.alertManager = [NDAAlertManager new];
  [self setUpTextFields];
  [self setUpActionButton];
  [self.emailTextField becomeFirstResponder];
  if ([self isKindOfClass:[NDALogInViewController class]]) {
    [self setUpPasswordResetButton];
  }
  self.view.keyboardTriggerOffset = kKeyboardTriggerOffset;
  [self.view addKeyboardPanningWithFrameBasedActionHandler:nil constraintBasedActionHandler:nil];
  UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
  [self.view addGestureRecognizer:tapGestureRecognizer];
}

- (void)hideKeyboard {
  [self.view endEditing:YES];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.navigationController.navigationBarHidden = NO;
  self.navigationItem.title = self.action;
}

- (void)dealloc {
  [self.view removeKeyboardControl];
}

#pragma mark Private

- (void)setUpTextFields {
  self.emailTextField = [[UITextField alloc] initWithFrame:CGRectMake(kAuthorizationViewPadding, kAuthorizationViewPadding, self.view.width - kAuthorizationViewPadding * 2, 0)];
  self.emailTextField.accessibilityIdentifier = @"Email Text Field";
  self.emailTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"E-mail", nil) attributes:@{ NSForegroundColorAttributeName : [UIColor nda_darkGrayColor] }];
  self.emailTextField.keyboardType = UIKeyboardTypeEmailAddress;
  self.emailTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
  self.emailTextField.autocorrectionType = UITextAutocorrectionTypeNo;
  [self stylizeTextField:self.emailTextField];
  [self.view addSubview:self.emailTextField];

  self.passwordTextField = [[UITextField alloc] initWithFrame:CGRectMake(kAuthorizationViewPadding, self.emailTextField.bottom + kEmailAuthorizationTextFieldSpacing, self.view.width - kAuthorizationViewPadding * 2, 0)];
  self.passwordTextField.accessibilityIdentifier = @"Password Text Field";
  self.passwordTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Пароль", nil) attributes:@{ NSForegroundColorAttributeName : [UIColor nda_darkGrayColor] }];
  self.passwordTextField.secureTextEntry = YES;
  [self stylizeTextField:self.passwordTextField];
  [self.view addSubview:self.passwordTextField];

  if (![self isKindOfClass:[NDASignUpViewController class]]) {
    return;
  }

  self.firstNameTextField = [[UITextField alloc] initWithFrame:CGRectMake(kAuthorizationViewPadding, self.passwordTextField.bottom + kEmailAuthorizationTextFieldSpacing, (self.view.width - kAuthorizationViewPadding * 2 - kEmailAuthorizationTextFieldSpacing) / 2, 0)];
  self.firstNameTextField.accessibilityIdentifier = @"First Name Text Field";
  self.firstNameTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Имя", nil) attributes:@{ NSForegroundColorAttributeName : [UIColor nda_darkGrayColor] }];
  self.firstNameTextField.autocorrectionType = UITextAutocorrectionTypeNo;
  [self stylizeTextField:self.firstNameTextField];
  [self.view addSubview:self.firstNameTextField];

  self.lastNameTextField = [[UITextField alloc] initWithFrame:CGRectMake(self.firstNameTextField.right + kEmailAuthorizationTextFieldSpacing, self.passwordTextField.bottom + kEmailAuthorizationTextFieldSpacing, (self.view.width - kAuthorizationViewPadding * 2 - kEmailAuthorizationTextFieldSpacing) / 2, 0)];
  self.lastNameTextField.accessibilityIdentifier = @"Last Name Text Field";
  self.lastNameTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Фамилия", nil) attributes:@{ NSForegroundColorAttributeName : [UIColor nda_darkGrayColor] }];
  self.lastNameTextField.autocorrectionType = UITextAutocorrectionTypeNo;
  [self stylizeTextField:self.lastNameTextField];
  [self.view addSubview:self.lastNameTextField];
}

- (void)stylizeTextField:(UITextField *)textField {
  textField.textColor = [UIColor nda_textColor];
  textField.font = [UIFont fontWithName:kRegularFontName size:[UIFont largeTextFontSize]];
  textField.clearButtonMode = UITextFieldViewModeWhileEditing;
  textField.height = kEmailAuthorizationTextFieldPadding.top + [textField.placeholder sizeWithAttributes:@{ NSFontAttributeName : textField.font }].height + kEmailAuthorizationTextFieldPadding.bottom;
  CALayer *border = [CALayer layer];
  border.frame = CGRectMake(0, textField.height - 1, textField.width, 1);
  border.backgroundColor = [UIColor nda_darkGrayColor].CGColor;
  [textField.layer addSublayer:border];
}

- (void)setUpActionButton {
  self.actionButton = [UIButton new];
  self.actionButton.accessibilityIdentifier = @"Action Button";
  [self.actionButton setTitle:self.action forState:UIControlStateNormal];
  [self.actionButton setBackgroundImage:[UIImage imageWithColor:[UIColor nda_greenColor]] forState:UIControlStateNormal];
  [self.actionButton setBackgroundImage:[UIImage imageWithColor:[[UIColor nda_greenColor] darkerColor:0.1f]] forState:UIControlStateHighlighted];
  [self.actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  self.actionButton.titleLabel.font = [UIFont fontWithName:kLightFontName size:[UIFont mediumButtonFontSize]];
  CGSize actionButtonSize = [self.actionButton.titleLabel.text sizeWithAttributes:@{ NSFontAttributeName : self.actionButton.titleLabel.font }];
  actionButtonSize.width += kEmailAuthorizationButtonPadding.left + kEmailAuthorizationButtonPadding.right;
  actionButtonSize.height += kEmailAuthorizationButtonPadding.top + kEmailAuthorizationButtonPadding.bottom;
  CGRect offsetFromFrame = [self isKindOfClass:[NDASignUpViewController class]] ? self.lastNameTextField.frame : self.passwordTextField.frame;
  self.actionButton.frame = CGRectMake((self.view.width - actionButtonSize.width) / 2, CGRectGetMaxY(offsetFromFrame) + kEmailAuthorizationActionButtonTopMargin, actionButtonSize.width, actionButtonSize.height);
  self.actionButton.clipsToBounds = YES;
  self.actionButton.layer.cornerRadius = actionButtonSize.height / 2;
  [self.actionButton addTarget:self action:@selector(actionButtonTapped) forControlEvents:UIControlEventTouchUpInside];

  [self.view addSubview:self.actionButton];
}

- (void)setUpPasswordResetButton {
  self.passwordResetButton = [UIButton new];
  self.passwordResetButton.accessibilityIdentifier = @"Password Reset Button";
  [self.passwordResetButton setTitle:NSLocalizedString(@"Забыли пароль?", nil) forState:UIControlStateNormal];
  [self.passwordResetButton setBackgroundImage:[UIImage imageWithColor:[UIColor nda_lightGrayColor]] forState:UIControlStateHighlighted];
  [self.passwordResetButton setTitleColor:[UIColor nda_textColor] forState:UIControlStateNormal];
  self.passwordResetButton.titleLabel.font = [UIFont fontWithName:kLightFontName size:[UIFont smallButtonFontSize]];
  CGSize passwordResetButtonSize = [self.passwordResetButton.titleLabel.text sizeWithAttributes:@{ NSFontAttributeName : self.passwordResetButton.titleLabel.font }];
  passwordResetButtonSize.width += kPasswordResetButtonPadding.left + kPasswordResetButtonPadding.right;
  passwordResetButtonSize.height += kPasswordResetButtonPadding.top + kPasswordResetButtonPadding.bottom;
  self.passwordResetButton.frame = CGRectMake((self.view.width - passwordResetButtonSize.width) / 2, self.actionButton.bottom + kPasswordResetButtonTopMargin, passwordResetButtonSize.width, passwordResetButtonSize.height);
  self.passwordResetButton.clipsToBounds = YES;
  self.passwordResetButton.layer.cornerRadius = kMediumButtonCornerRadius;
  [self.passwordResetButton addTarget:self action:@selector(passwordResetButtonTapped) forControlEvents:UIControlEventTouchUpInside];

  [self.view addSubview:self.passwordResetButton];
}

#pragma mark Public

- (void)actionButtonTapped {
}

- (void)passwordResetButtonTapped {
  if (self.emailTextField.text.length == 0) {
    [self.alertManager showNotificationWithText:NSLocalizedString(@"Сначала введите ваш e-mail", nil)];
    return;
  }
  [self.view endEditing:YES];
  [JTProgressHUD showWithTransition:JTProgressHUDTransitionFade];
  [PFUser requestPasswordResetForEmailInBackground:self.emailTextField.text block:^(BOOL succeeded, NSError *error) {
    if (!error) {
      DDLogVerbose(@"Password reset requested for user");
      [self.alertManager showNotificationWithText:NSLocalizedString(@"Письмо было отправлено на указанный e-mail", nil) color:[UIColor nda_greenColor]];
    } else {
      DDLogError(@"Error occured while requesting password reset for user: %@", error);
      [self.alertManager showNotificationWithText:[self stringForError:error]];
    }
    [JTProgressHUD hide];
  }];
}

- (NSString *)stringForError:(NSError *)error {
  NSString *errorString;

  switch (error.code) {
    case kPFErrorConnectionFailed:
      errorString = NSLocalizedString(@"Что-то пошло не так. Попробуйте чуть позже", nil);
      break;
    case kPFErrorInvalidServerResponse:
      errorString = NSLocalizedString(@"Что-то пошло не так. Попробуйте чуть позже", nil);
      break;
    case kPFErrorRequestLimitExceeded:
      errorString = NSLocalizedString(@"Что-то пошло не так. Попробуйте чуть позже", nil);
      break;
    case kPFErrorInvalidEmailAddress:
      errorString = NSLocalizedString(@"Недействительный e-mail", nil);
      break;
    case kPFErrorUsernameTaken:
      errorString = NSLocalizedString(@"Данный e-mail уже используется другим пользователем", nil);
      break;
    case kPFErrorUserEmailTaken:
      errorString = NSLocalizedString(@"Данный e-mail уже используется другим пользователем", nil);
      break;
    case kPFErrorUserWithEmailNotFound:
      errorString = NSLocalizedString(@"Пользователя с таким e-mail не существует", nil);
      break;
    case kPFErrorObjectNotFound:
      errorString = NSLocalizedString(@"Неверные данные", nil);
      break;
    default:
      errorString = [error localizedDescription];
      break;
  }
  return errorString;
}

- (void)continueRegistration {
  [self.navigationController pushViewController:[NDAPermissionsViewController new] animated:YES];
}

- (void)goToDashboard {
  [self.navigationController pushViewController:[NDAMainPageViewController new] animated:YES];
}

@end
