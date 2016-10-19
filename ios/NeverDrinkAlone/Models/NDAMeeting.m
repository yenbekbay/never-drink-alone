#import "NDAMeeting.h"

@implementation NDAMeeting

@dynamic match;
@dynamic meetingPlace;
@dynamic timeSlot;

#pragma mark Initialization

- (instancetype)initWithMatch:(NDAMatch *)match meetingPlace:(NDAMeetingPlace *)meetingPlace timeSlot:(NDATimeSlot *)timeSlot {
  self = [super init];
  if (!self) {
    return nil;
  }

  self.match = match;
  self.meetingPlace = meetingPlace;
  self.timeSlot = timeSlot;

  return self;
}

#pragma mark PFSubclassing

+ (void)load {
  [self registerSubclass];
}

+ (NSString *)parseClassName {
  return @"Meeting";
}

@end
