#import "NDAMeeting.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface NDAMeetingCard : UIButton

#pragma mark Properties

@property (weak, nonatomic) NDAMeeting *meeting;

#pragma mark Methods

- (RACSignal *)show;
- (RACSignal *)hide;

@end
