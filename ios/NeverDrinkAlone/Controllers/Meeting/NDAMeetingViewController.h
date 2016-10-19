#import "NDAMeeting.h"

@protocol NDAMeetingViewControllerDelegate <NSObject>
@required
- (void)displayImageForImageView:(UIImageView *)imageView;
- (void)shrinkUserInfoView;
- (void)expandUserInfoView;
- (void)userInfoViewChangedHeight:(CGFloat)heightDiff;
@end

@interface NDAMeetingViewController : UIViewController <NDAMeetingViewControllerDelegate>

#pragma mark Properties

@property (nonatomic, readonly) NDAMeeting *meeting;

#pragma mark Methods

- (instancetype)initWithMeeting:(NDAMeeting *)meeting;

@end
