#import "NDAMeeting.h"
#import "NDAMeetingViewController.h"

@interface NDAMeetingDetailsView : UIScrollView

#pragma mark Properties

@property (weak, nonatomic) NDAMeeting *meeting;
@property (nonatomic) id<NDAMeetingViewControllerDelegate> meetingDelegate;

#pragma mark Methods

- (void)setUserStatuses;

@end
