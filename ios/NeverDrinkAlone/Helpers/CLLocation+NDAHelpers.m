#import "CLLocation+NDAHelpers.h"

static NSTimeInterval const kRecentLocationMaximumElapsedTimeInterval = 5;

@implementation CLLocation (NDAHelpers)

- (BOOL)isStale {
  return [self elapsedTimeInterval] > kRecentLocationMaximumElapsedTimeInterval;
}

- (NSTimeInterval)elapsedTimeInterval {
  return [[NSDate date] timeIntervalSinceDate:self.timestamp];
}

@end
