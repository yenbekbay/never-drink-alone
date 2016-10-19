#import "NDAMeetingGoalPopup.h"

#import "NDAConstants.h"
#import "UIColor+NDAHelpers.h"
#import "UIColor+NDATints.h"
#import "UIFont+NDASizes.h"
#import "UIImage+NDAHelpers.h"
#import <CNPPopupController/CNPPopupController.h>

static UIEdgeInsets const kPopupDoneButtonPadding = {
  5, 20, 5, 20
};
static CGFloat const kPopupButtonHeight = 60;
static CGFloat const kPopupButtonWidth = 200;

@interface NDAMeetingGoalPopup () <CNPPopupControllerDelegate>

@property (nonatomic) CNPPopupController *popupController;
@property (nonatomic) BOOL didSelectGirls;
@property (nonatomic) BOOL didSelectGuys;

@end

@implementation NDAMeetingGoalPopup

#pragma mark Public

- (RACSignal *)getMeetingGoal {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentCenter;

    UILabel *titleLabel = [UILabel new];
    titleLabel.numberOfLines = 0;
    titleLabel.textColor = [UIColor nda_textColor];
    titleLabel.attributedText = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"С кем вы хотите встречаться?", nil) attributes:@{
                                   NSFontAttributeName : [UIFont fontWithName:kRegularFontName size:[UIFont extraLargeTextFontSize]],
                                   NSParagraphStyleAttributeName : paragraphStyle
                                 }];

    CNPPopupButton *doneButton = [CNPPopupButton new];
    [doneButton setTitle:@"Готово" forState:UIControlStateNormal];
    [doneButton setBackgroundImage:[UIImage imageWithColor:[UIColor nda_greenColor]] forState:UIControlStateNormal];
    [doneButton setBackgroundImage:[UIImage imageWithColor:[[UIColor nda_greenColor] darkerColor:0.1f]] forState:UIControlStateHighlighted];
    [doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    doneButton.titleLabel.font = [UIFont fontWithName:kLightFontName size:[UIFont mediumButtonFontSize]];
    CGSize actionButtonSize = [doneButton.titleLabel.text sizeWithAttributes:@{ NSFontAttributeName : doneButton.titleLabel.font }];
    actionButtonSize.width += kPopupDoneButtonPadding.left + kPopupDoneButtonPadding.right;
    actionButtonSize.height += kPopupDoneButtonPadding.top + kPopupDoneButtonPadding.bottom;
    doneButton.frame = CGRectMake(0, 0, actionButtonSize.width, actionButtonSize.height);
    doneButton.clipsToBounds = YES;
    doneButton.layer.cornerRadius = actionButtonSize.height / 2;
    [self setButtonEnabled:doneButton enabled:NO];
    doneButton.selectionHandler = ^(CNPPopupButton *button) {
      [self.popupController dismissPopupControllerAnimated:YES];
      if (self.didSelectGirls && !self.didSelectGuys) {
        [subscriber sendNext:@1];
      } else if (self.didSelectGuys && !self.didSelectGirls) {
        [subscriber sendNext:@0];
      } else if (self.didSelectGirls && self.didSelectGuys) {
        [subscriber sendNext:@2];
      }
      [subscriber sendCompleted];
    };

    CNPPopupButton *girlsButton = [[CNPPopupButton alloc] initWithFrame:CGRectMake(0, 0, kPopupButtonWidth, kPopupButtonHeight)];
    [girlsButton setTitle:NSLocalizedString(@"С девушками", nil) forState:UIControlStateNormal];
    girlsButton.selectionHandler = ^(CNPPopupButton *button) {
      if (self.didSelectGirls) {
        [button setBackgroundImage:nil forState:UIControlStateNormal];
        [button setTitleColor:[UIColor nda_primaryColor] forState:UIControlStateNormal];
        self.didSelectGirls = NO;
        [self setButtonEnabled:doneButton enabled:self.didSelectGuys];
      } else {
        [button setBackgroundImage:[UIImage imageWithColor:[UIColor nda_primaryColor]] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.didSelectGirls = YES;
        [self setButtonEnabled:doneButton enabled:YES];
      }
    };

    CNPPopupButton *guysButton = [[CNPPopupButton alloc] initWithFrame:CGRectMake(0, 0, kPopupButtonWidth, kPopupButtonHeight)];
    [guysButton setTitle:NSLocalizedString(@"С парнями", nil) forState:UIControlStateNormal];
    guysButton.selectionHandler = ^(CNPPopupButton *button) {
      if (self.didSelectGuys) {
        [button setBackgroundImage:nil forState:UIControlStateNormal];
        [button setTitleColor:[UIColor nda_primaryColor] forState:UIControlStateNormal];
        self.didSelectGuys = NO;
        [self setButtonEnabled:doneButton enabled:self.didSelectGirls];
      } else {
        [button setBackgroundImage:[UIImage imageWithColor:[UIColor nda_primaryColor]] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.didSelectGuys = YES;
        [self setButtonEnabled:doneButton enabled:YES];
      }
    };

    for (CNPPopupButton *button in @[girlsButton, guysButton]) {
      [button setTitleColor:[UIColor nda_primaryColor] forState:UIControlStateNormal];
      button.titleLabel.font = [UIFont fontWithName:kRegularFontName size:[UIFont mediumButtonFontSize]];
      button.clipsToBounds = YES;
      button.layer.cornerRadius = kPopupButtonHeight / 2;
      button.layer.borderColor = [UIColor nda_primaryColor].CGColor;
      button.layer.borderWidth = 1;
    }

    self.popupController = [[CNPPopupController alloc] initWithContents:@[titleLabel, girlsButton, guysButton, doneButton]];
    CNPPopupTheme *popupTheme = [CNPPopupTheme defaultTheme];
    popupTheme.shouldDismissOnBackgroundTouch = NO;
    self.popupController.theme = popupTheme;
    self.popupController.theme.popupStyle = CNPPopupStyleCentered;
    self.popupController.delegate = self;
    [self.popupController presentPopupControllerAnimated:YES];

    return nil;
  }];
}

#pragma mark Helpers

- (void)setButtonEnabled:(CNPPopupButton *)button enabled:(BOOL)enabled {
  button.enabled = enabled;
  button.alpha = enabled ? 1.0f : 0.5f;
}

@end
