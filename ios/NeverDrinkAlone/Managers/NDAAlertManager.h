#import "NDAActionSheet.h"
#import "UIImagePickerController+Edit.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

/**
 *  Provides an interface for showing notification, alerts, and action sheets in the UI.
 */
@interface NDAAlertManager : NSObject

#pragma mark Properties

@property (nonatomic) UIViewController<UIImagePickerControllerDelegate, UINavigationControllerDelegate> *rootViewController;

#pragma mark Methods

/**
 *  Creates a new alert manager with the given root view controller.
 *
 *  @param rootViewController The view controller to show notifications in.
 *
 *  @return Newly created alert manager object.
 */
- (instancetype)initWithRootViewController:(UIViewController<UIImagePickerControllerDelegate, UINavigationControllerDelegate> *)rootViewController;
/**
 *  Fetches the active alert message from Parse and displays it above all views.
 */
- (RACSignal *)displayAlert;
/**
 *  Shows a notification as a toast view on navigation bar with the given text and red color.
 *
 *  @param text Text to display in the notification.
 */
- (void)showNotificationWithText:(NSString *)text;
/**
 *  Shows a notification as a toast view on navigation bar with the given text and color.
 *
 *  @param text Text to display in the notification.
 */
- (void)showNotificationWithText:(NSString *)text color:(UIColor *)color;
/**
 *  Opens an action sheet for getting an image from the user with the given crop mode.
 *
 *  @param cropMode Crop mode to use on the image, can be circular or square.
 *
 *  @return Newly created action sheet.
 */
- (NDAActionSheet *)actionSheetWithCropMode:(DZNPhotoEditorViewControllerCropMode)cropMode;
/**
 *  Shows an alert view with given title and body text.
 *
 *  @param title       Text for the title of the alert.
 *  @param body        Text for the body of the alert.
 *  @param dismissable Whether or not the alert view should be dismissable by tapping outside.
 */
- (void)showAlertWithTitle:(NSString *)title body:(NSString *)body dismissable:(BOOL)dismissable;

@end
