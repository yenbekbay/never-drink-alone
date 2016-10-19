//
//  Copyright (c) 2014 AnyKey Entertainment, 2015 Ayan Yenbekbay.
//

#import "NDAConstants.h"

@interface NDAAlertView : UIView

#pragma mark Properties

@property (copy, nonatomic) NDADismissHandler dismissHandler;
@property (copy, nonatomic) NSString *body;
@property (copy, nonatomic) NSString *closeButtonTitle;
@property (copy, nonatomic) NSString *title;
@property (nonatomic) BOOL dismissOnTapOutside;
@property (nonatomic) NSDictionary *bodyTextAttributes;
@property (nonatomic) NSDictionary *buttonTextAttributes;
@property (nonatomic) NSDictionary *titleTextAttributes;
@property (nonatomic) NSTimeInterval animationDuration;
@property (nonatomic) UIColor *contentViewColor;
@property (nonatomic) UIImage *image;

#pragma mark Methods

- (instancetype)initWithTitle:(NSString *)title body:(NSString *)body;
- (instancetype)initWithTitle:(NSString *)title body:(NSString *)body closeButtonTitle:(NSString *)closeButtonTitle;
- (instancetype)initWithTitle:(NSString *)title body:(NSString *)body closeButtonTitle:(NSString *)closeButtonTitle handler:(NDADismissHandler)handler;
- (instancetype)initWithView:(UIView *)view closeButtonTitle:(NSString *)closeButtonTitle;
- (instancetype)initWithView:(UIView *)view closeButtonTitle:(NSString *)closeButtonTitle handler:(NDADismissHandler)handler;
- (void)addButtonWithTitle:(NSString *)title handler:(NDADismissHandler)handler;
- (void)show;
- (void)dismissAnimated:(BOOL)animated;

@end
