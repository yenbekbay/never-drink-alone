#import "NDAMeetingManager.h"

#import "NDAConstants.h"
#import "NDAInterest.h"
#import "NDAMatch.h"
#import "NSDate+NDAHelpers.h"
#import <Parse/Parse.h>

@implementation NDAMeetingManager

#pragma mark Initialization

+ (instancetype)sharedInstance {
  static NDAMeetingManager *_sharedInstance = nil;
  static dispatch_once_t oncePredicate;
  dispatch_once(&oncePredicate, ^{
    _sharedInstance = [NDAMeetingManager new];
  });
  return _sharedInstance;
}

#pragma mark Public

- (RACSignal *)getMeeting {
  if (self.meeting && [self.userMeeting[kActiveKey] boolValue]) {
    return [RACSignal return :self.meeting];
  }
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    [[self getUserMeeting] subscribeNext:^(PFObject *userMeeting) {
      BOOL hasRejected = [userMeeting[kUserHasRejectedKey] boolValue];
      if (hasRejected) {
        [subscriber sendNext:nil];
        [subscriber sendCompleted];
      }
      PFQuery *meetingQuery = [NDAMeeting query];
      [meetingQuery includeKey:kMatchKey];
      [meetingQuery includeKey:kMeetingPlaceKey];
      [meetingQuery includeKey:kTimeSlotKey];
      [meetingQuery getObjectInBackgroundWithId:[self.userMeeting[kMeetingKey] objectId] block:^(PFObject *meeting, NSError *meetingError) {
        if (!meetingError) {
          self.meeting = (NDAMeeting *)meeting;
          [self fetchUsersForMeetingWithSubscriber:subscriber];
        } else {
          [subscriber sendError:meetingError];
        }
      }];
    } error:^(NSError *error) {
      [subscriber sendError:error];
    }];
    return nil;
  }];
}

- (RACSignal *)getCommonInterests {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    NSMutableArray *interests = [NSMutableArray new];
    for (PFObject *rawInterestObject in self.meeting.match.interests) {
      [rawInterestObject fetchIfNeededInBackgroundWithBlock:^(PFObject *interestObject, NSError *error) {
        if (!error) {
          NDAInterest *interest = (NDAInterest *)interestObject;
          [interests addObject:interest.name];
          if (interests.count == self.meeting.match.interests.count) {
            [subscriber sendNext:interests];
            [subscriber sendCompleted];
          }
        } else {
          [subscriber sendError:error];
        }
      }];
    }
    return nil;
  }];
}

- (RACSignal *)getUserMeeting {
  if (self.userMeeting && [self.userMeeting[kActiveKey] boolValue]) {
    return [RACSignal return :self.userMeeting];
  }
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    PFQuery *userMeetingQuery = [PFQuery queryWithClassName:@"UserMeeting"];
    [userMeetingQuery whereKey:kUserKey equalTo:[PFUser currentUser]];
    [userMeetingQuery whereKey:kActiveKey equalTo:@YES];
    [userMeetingQuery getFirstObjectInBackgroundWithBlock:^(PFObject *userMeeting, NSError *error) {
      if (!error) {
        self.userMeeting = userMeeting;
        [subscriber sendNext:self.userMeeting];
        [subscriber sendCompleted];
      } else {
        [subscriber sendError:error];
      }
    }];
    return nil;
  }];
}

- (RACSignal *)getUserMeetings {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    [[self getMeeting] subscribeNext:^(NDAMeeting *meeting) {
      PFQuery *userMeetingsQuery = [PFQuery queryWithClassName:@"UserMeeting"];
      [userMeetingsQuery includeKey:kUserKey];
      [userMeetingsQuery whereKey:kMeetingKey equalTo:self.meeting];
      [userMeetingsQuery findObjectsInBackgroundWithBlock:^(NSArray *userMeetings, NSError *userMeetingsError) {
        if (!userMeetingsError) {
          [subscriber sendNext:userMeetings];
          [subscriber sendCompleted];
        } else {
          [subscriber sendError:userMeetingsError];
        }
      }];
    } error:^(NSError *error) {
      [subscriber sendError:error];
    }];
    return nil;
  }];
}

- (RACSignal *)getMeetingUser {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    [[self getMeeting] subscribeNext:^(NDAMeeting *meeting) {
      PFUser *meetingUser = [meeting.match.firstUser.objectId isEqualToString:[PFUser currentUser].objectId] ? meeting.match.secondUser : meeting.match.firstUser;
      PFQuery *query = [PFUser query];
      [query getObjectInBackgroundWithId:meetingUser.objectId block:^(PFObject *fetchedMeetingUser, NSError *error) {
        if (!error) {
          [subscriber sendNext:fetchedMeetingUser];
          [subscriber sendCompleted];
        } else {
          [subscriber sendError:error];
        }
      }];
    } error:^(NSError *error) {
      [subscriber sendError:error];
    }];
    return nil;
  }];
}

- (RACSignal *)updateMeetingStatus {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    [[self getUserMeetings] subscribeNext:^(NSArray *userMeetings) {
      PFObject *firstUserMeeting = userMeetings[0];
      PFObject *secondUserMeeting = userMeetings[1];
      [PFCloud callFunctionInBackground:@"updateMeetingStatus" withParameters:@{
         @"firstUserMeetingId" : firstUserMeeting.objectId,
         @"secondUserMeetingId" : secondUserMeeting.objectId
       } block:^(id result, NSError *error) {
        if (!error) {
          [subscriber sendCompleted];
        } else {
          [subscriber sendError:error];
        }
      }];
    } error:^(NSError *error) {
      [subscriber sendError:error];
    }];
    return nil;
  }];
}

- (RACSignal *)notifySecondUser {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    PFUser *receivingUser = [self.meeting.match.firstUser.objectId isEqualToString:[PFUser currentUser].objectId] ? self.meeting.match.secondUser : self.meeting.match.firstUser;
    [PFCloud callFunctionInBackground:@"notifyMeetingUser" withParameters:@{
       @"userMeetingId" : self.userMeeting.objectId,
       @"receivingUserId" : receivingUser.objectId,
       @"sendingUserName" : [PFUser currentUser][kUserFirstNameKey]
     } block:^(id result, NSError *error) {
      if (!error) {
        [subscriber sendCompleted];
      } else {
        [subscriber sendError:error];
      }
    }
    ];
    return nil;
  }];
}

- (RACSignal *)saveImageForMeeting:(UIImage *)image {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    [[self getMeeting] subscribeNext:^(NDAMeeting *meeting) {
      NSMutableArray *meetingImages = [meeting[kImagesKey] mutableCopy] ? : [NSMutableArray new];
      NSData *imageData = UIImageJPEGRepresentation(image, 0.7f);
      PFFile *imageFile = [PFFile fileWithName:@"meeting-image.jpg" data:imageData];
      [meetingImages addObject:imageFile];
      meeting[kImagesKey] = meetingImages;
      [meeting saveInBackground];
      [subscriber sendCompleted];
    } error:^(NSError *error) {
      [subscriber sendError:error];
    }];
    return nil;
  }];
}

- (RACSignal *)userMissedMeeting:(PFUser *)user {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    [PFCloud callFunctionInBackground:@"userMissedMeeting" withParameters:@{ @"userId" : user.objectId } block:^(id result, NSError *error) {
      if (!error) {
        [subscriber sendCompleted];
      } else {
        [subscriber sendError:error];
      }
    }];
    return nil;
  }];
}

- (void)resetMeeting {
  self.meeting = nil;
  self.userMeeting = nil;
}

#pragma mark Private

- (void)fetchUsersForMeetingWithSubscriber:(id<RACSubscriber>)subscriber {
  if (self.meeting) {
    [self.meeting.match.firstUser fetchIfNeededInBackgroundWithBlock:^(PFObject *firstUserObject, NSError *firstUserError) {
      if (firstUserError) {
        [subscriber sendError:firstUserError];
        return;
      }
      [self.meeting.match.secondUser fetchIfNeededInBackgroundWithBlock:^(PFObject *secondUserObject, NSError *secondUserError) {
        if (secondUserError) {
          [subscriber sendError:secondUserError];
          return;
        }
        [subscriber sendNext:self.meeting];
        [subscriber sendCompleted];
      }];
    }];
  } else {
    [subscriber sendNext:self.meeting];
    [subscriber sendCompleted];
  }
}

@end
