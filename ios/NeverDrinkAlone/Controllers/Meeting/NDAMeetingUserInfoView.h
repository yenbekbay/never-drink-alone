#import "NDAMeetingViewController.h"
#import <Parse/Parse.h>

@interface NDAMeetingUserInfoView : UIView

#pragma mark Properties

@property (weak, nonatomic) PFUser *user;
@property (nonatomic) id<NDAMeetingViewControllerDelegate> meetingDelegate;

#pragma mark Methods

- (void)shrink;
- (void)expand;

@end
