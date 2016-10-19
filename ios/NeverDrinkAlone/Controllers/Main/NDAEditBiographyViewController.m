#import "NDAEditBiographyViewController.h"

#import "NDAConstants.h"
#import "NSString+NDAHelpers.h"
#import "UIColor+NDATints.h"
#import "UIFont+NDASizes.h"
#import "UIView+AYUtils.h"
#import <JVFloatLabeledTextField/JVFloatLabeledTextView.h>
#import <Parse/Parse.h>

static CGFloat const kEditBiographyViewPadding = 10;
static CGFloat const kEditBiographyViewWidth = 240;

@interface NDAEditBiographyViewController () <UITextViewDelegate>

@property (nonatomic) JVFloatLabeledTextView *biographyTextView;

@end

@implementation NDAEditBiographyViewController

#pragma mark Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];

  self.view.backgroundColor = [UIColor whiteColor];
  self.biographyTextView = [[JVFloatLabeledTextView alloc] initWithFrame:CGRectMake(kEditBiographyViewPadding, 44 + kEditBiographyViewPadding, kEditBiographyViewWidth - kEditBiographyViewPadding * 2, 0)];
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
  self.biographyTextView.height = ([self.biographyTextView.text.length > 0 ? self.biographyTextView.text : self.biographyTextView.placeholder sizeWithFont:self.biographyTextView.font width:self.biographyTextView.width].height + kFloatingLabelSpacing + [NSLocalizedString(@"Биография (50 символов)", nil) sizeWithAttributes:@{ NSFontAttributeName : self.biographyTextView.floatingLabelFont }].height);

  [self.view addSubview:self.biographyTextView];
  [self.biographyTextView becomeFirstResponder];

  UIBarButtonItem *closeButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonTapped)];
  self.navigationItem.leftBarButtonItem = closeButtonItem;
}

#pragma mark Public

+ (CGSize)viewSize {
  return CGSizeMake(kEditBiographyViewWidth, [NDAEditBiographyViewController maxBiographyTextViewHeight] + kEditBiographyViewPadding * 2 + 44);
}

#pragma mark Private

+ (CGFloat)maxBiographyTextViewHeight {
  return [[[NSString string] stringByPaddingToLength:kUserBiographyCharsLimit withString:@"W" startingAtIndex:0] sizeWithFont:[UIFont fontWithName:kRegularFontName size:[UIFont largeTextFontSize]] width:kEditBiographyViewWidth - kEditBiographyViewPadding * 2].height + kFloatingLabelSpacing + [NSLocalizedString(@"Биография (50 символов)", nil) sizeWithAttributes:@{ NSFontAttributeName : [UIFont fontWithName:kSemiboldFontName size:[UIFont extraSmallTextFontSize]] }].height;
}

#pragma mark Private

- (void)doneButtonTapped {
  if (self.delegate && ![[PFUser currentUser][kUserBiographyKey] isEqualToString:self.biographyTextView.text] && self.biographyTextView.text.length > 0) {
    [self.delegate didFinishEditingBiographyWithText:self.biographyTextView.text];
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
  if ([text isEqualToString:@"\n"]) {
    return NO;
  }
  if ([textView.text stringByAppendingString:text].length > kUserBiographyCharsLimit) {
    return NO;
  }

  return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
  if (textView.text.length > 0) {
    self.biographyTextView.placeholder = [NSString stringWithFormat:NSLocalizedString(@"Биография (%@ %@ %@)", nil), [NSString getNumEnding:(NSInteger)(50 - textView.text.length) endings:@[@"остался", @"осталось", @"осталось"]], @(50 - textView.text.length), [NSString getNumEnding:(NSInteger)(50 - textView.text.length) endings:@[@"символ", @"символа", @"символов"]]];
  } else {
    self.biographyTextView.placeholder = NSLocalizedString(@"Биография (50 символов)", nil);
  }
  [self fixBiographyTextView];
}

- (void)fixBiographyTextView {
  CGFloat newHeight = ([self.biographyTextView.text.length > 0 ? self.biographyTextView.text : self.biographyTextView.placeholder sizeWithFont:self.biographyTextView.font width:self.biographyTextView.width].height + kFloatingLabelSpacing + [self.biographyTextView.placeholder sizeWithAttributes:@{ NSFontAttributeName : self.biographyTextView.floatingLabelFont }].height);

  if (newHeight != self.biographyTextView.height) {
    self.biographyTextView.height = newHeight;
  }
}

@end
