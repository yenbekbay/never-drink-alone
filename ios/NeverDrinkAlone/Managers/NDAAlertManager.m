#import "NDAAlertManager.h"

#import "NDAAlertView.h"
#import "NDAConstants.h"
#import "NDAMeetingManager.h"
#import "PFUser+NDAHelpers.h"
#import "UIColor+NDATints.h"
#import "UIFont+NDASizes.h"
#import "UIImagePickerController+NDABugFix.h"
#import <CRToast/CRToast.h>
#import <Parse/Parse.h>

@implementation NDAAlertManager

#pragma mark Initialization

- (instancetype)initWithRootViewController:(UIViewController<UIImagePickerControllerDelegate, UINavigationControllerDelegate> *)rootViewController {
  self = [super init];
  if (!self) {
    return nil;
  }

  self.rootViewController = rootViewController;

  return self;
}

#pragma mark Public

- (RACSignal *)displayAlert {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    [[PFUser currentUser] fetchInBackgroundWithBlock:^(PFObject *userObject, NSError *userError) {
      if (!userError) {
        PFUser *user = (PFUser *)userObject;
        if (user[kLastNotificationKey]) {
          if ([user[kCanPostSelfieKey] boolValue]) {
            [[self displaySelfieAlert:user] subscribe:subscriber];
          } else {
            NDAAlertView *alertView = [[NDAAlertView alloc] initWithTitle:NSLocalizedString(@"Новое уведомление", nil) body:user[kLastNotificationKey]];
            [alertView show];
            [PFInstallation currentInstallation].badge = 0;
            [[PFInstallation currentInstallation] saveEventually];
            [user removeObjectForKey:kLastNotificationKey];
            [user saveEventually];
            [subscriber sendCompleted];
          }
        }
      } else {
        [subscriber sendError:userError];
      }
    }];
    return nil;
  }];
}

- (NDAActionSheet *)actionSheetWithCropMode:(DZNPhotoEditorViewControllerCropMode)cropMode {
  NDAActionSheet *actionSheet = [[NDAActionSheet alloc] initWithTitle:@""];

  actionSheet.cancelButtonTitle = NSLocalizedString(@"Отмена", nil);
  if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Сфотографировать", nil) handler:^{
      UIImagePickerController *picker = [UIImagePickerController new];
      picker.allowsEditing = NO;
      picker.delegate = self.rootViewController;
      picker.sourceType = UIImagePickerControllerSourceTypeCamera;
      picker.cropMode = cropMode;
      [self.rootViewController presentViewController:picker animated:YES completion:nil];
    }];
  }
  [actionSheet addButtonWithTitle:NSLocalizedString(@"Выбрать из библиотеки", nil) handler:^{
    UIImagePickerController *picker = [UIImagePickerController new];
    picker.allowsEditing = NO;
    picker.delegate = self.rootViewController;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
      picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    } else if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]) {
      picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    }
    picker.cropMode = cropMode;
    [self.rootViewController presentViewController:picker animated:YES completion:nil];
  }];
  return actionSheet;
}

- (void)showNotificationWithText:(NSString *)text {
  [self showNotificationWithText:text color:[UIColor nda_accentColor]];
}

- (void)showNotificationWithText:(NSString *)text color:(UIColor *)color {
  NSDictionary *options = @{
    kCRToastNotificationTypeKey : @(CRToastTypeNavigationBar),
    kCRToastTextKey : text,
    kCRToastFontKey : [UIFont fontWithName:kRegularFontName size:[UIFont mediumTextFontSize]],
    kCRToastBackgroundColorKey : color,
    kCRToastAnimationInTypeKey : @(CRToastAnimationTypeSpring),
    kCRToastAnimationOutTypeKey : @(CRToastAnimationTypeSpring),
    kCRToastAnimationInDirectionKey : @(CRToastAnimationDirectionTop),
    kCRToastAnimationOutDirectionKey : @(CRToastAnimationDirectionBottom)
  };

  [CRToastManager showNotificationWithOptions:options completionBlock:nil];
}

- (void)showAlertWithTitle:(NSString *)title body:(NSString *)body dismissable:(BOOL)dismissable {
  NDAAlertView *alertView = [[NDAAlertView alloc] initWithTitle:title body:body];

  alertView.dismissOnTapOutside = dismissable;
  [alertView show];
}

#pragma mark Private

- (RACSignal *)displaySelfieAlert:(PFUser *)user {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    [[[NDAMeetingManager sharedInstance] getMeetingUser] subscribeNext:^(PFUser *meetingUser) {
      NDAAlertView *alertView = [[NDAAlertView alloc] initWithTitle:NSLocalizedString(@"#селфош time!", nil) body:user[kLastNotificationKey]];
      alertView.dismissOnTapOutside = NO;
      alertView.closeButtonTitle = NSLocalizedString(@"Не в этот раз", nil);
      alertView.image = [UIImage imageNamed:@"selfosh.jpg"];
      [alertView addButtonWithTitle:NSLocalizedString(@"Выбрать фотографию", nil) handler:^{
        [[self actionSheetWithCropMode:DZNPhotoEditorViewControllerCropModeSquare] show];
      }];
      NSString *firstButtonTitle = [user[kUserGenderKey] integerValue] == 0 ? NSLocalizedString(@"Я не пришел", nil) : NSLocalizedString(@"Я не пришла", nil);
      [alertView addButtonWithTitle:firstButtonTitle handler:^{
        user[kCanPostSelfieKey] = @NO;
        [user removeObjectForKey:kLastNotificationKey];
        [user saveEventually];
        [[user karmaTransactionWithAmount:@(-4) description:@"Didn't come to a meeting"] subscribeNext:^(PFObject *karmaTransaction) {
          [subscriber sendCompleted];
        } error:^(NSError *error) {
          DDLogError(@"Error occured while performing a karma transaction: %@", error);
          [subscriber sendCompleted];
        }];
        [self showNotificationWithText:NSLocalizedString(@"-4 от кармы", nil) color:[UIColor nda_accentColor]];
      }];
      NSString *secondButtonTitle = [meetingUser[kUserGenderKey] integerValue] == 0 ? NSLocalizedString(@"Он не пришел", nil) : NSLocalizedString(@"Она не пришла", nil);
      [alertView addButtonWithTitle:secondButtonTitle handler:^{
        user[kCanPostSelfieKey] = @NO;
        [user removeObjectForKey:kLastNotificationKey];
        [user saveEventually];
        if ([meetingUser[kCanPostSelfieKey] boolValue]) {
          meetingUser[kCanPostSelfieKey] = @NO;
          [meetingUser removeObjectForKey:kLastNotificationKey];
          [meetingUser saveEventually];
          [[meetingUser karmaTransactionWithAmount:@(-4) description:@"Didn't come to a meeting"] subscribeNext:^(PFObject *karmaTransaction) {
            [subscriber sendCompleted];
          } error:^(NSError *error) {
            DDLogError(@"Error occured while performing a karma transaction: %@", error);
            [subscriber sendCompleted];
          }];
          [[[NDAMeetingManager sharedInstance] userMissedMeeting:meetingUser] subscribeError:^(NSError *error) {
            DDLogError(@"Error occured while notifying that user missed a meeting: %@", error);
          } completed:^{
            DDLogVerbose(@"Notified that user missed a meeting");
          }];
          [self showNotificationWithText:NSLocalizedString(@"Cпасибо!", nil) color:[UIColor nda_greenColor]];
        }
      }];
      [alertView setDismissHandler:^{
        user[kCanPostSelfieKey] = @NO;
        [user removeObjectForKey:kLastNotificationKey];
        [user saveEventually];
        [subscriber sendCompleted];
      }];
      [alertView show];
      [PFInstallation currentInstallation].badge = 0;
      [[PFInstallation currentInstallation] saveEventually];
    } error:^(NSError *error) {
      [subscriber sendError:error];
    }];
    return nil;
  }];
}

@end
