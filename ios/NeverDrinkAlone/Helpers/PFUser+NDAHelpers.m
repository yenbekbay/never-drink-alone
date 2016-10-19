#import "PFUser+NDAHelpers.h"

#import "NDAConstants.h"
#import "NDAInterest.h"
#import "UIImage+NDAHelpers.h"
#import <SDWebImage/UIImageView+WebCache.h>

@implementation PFUser (NDAHelpers)

#pragma mark Setters & getters

- (UIImage *)profilePictureImage {
  NSData *imageData = [[NSUserDefaults standardUserDefaults] objectForKey:[kUserPictureKey stringByAppendingString:self.objectId]];
  return [UIImage imageWithData:imageData];
}

- (void)setProfilePictureImage:(UIImage *)profilePictureImage {
  [[NSUserDefaults standardUserDefaults] setObject:UIImagePNGRepresentation(profilePictureImage) forKey:[kUserPictureKey stringByAppendingString:self.objectId]];
}

- (NSString *)fullName {
  return [NSString stringWithFormat:@"%@ %@", self[kUserFirstNameKey], self[kUserLastNameKey]];
}

#pragma mark Public

- (void)setDefaults {
  self[kUserKarmaKey] = @(kUserInitialKarma);
  self[kUserHasMeetingScheduledKey] = @NO;
  self[kUserHasUndecidedMeetingKey] = @NO;
  self[kIsAdministratorKey] = @NO;
  self[kCanPostSelfieKey] = @NO;
  self[kUserDidFinishRegistrationKey] = @NO;
  self[kUserHasSeenTips] = @NO;
}

- (RACSignal *)getProfilePicture {
  if (self.profilePictureImage) {
    return [RACSignal return :self.profilePictureImage];
  }
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    PFObject *userPicture = self[kUserPictureKey];
    if (userPicture) {
      [userPicture fetchIfNeededInBackgroundWithBlock:^(PFObject *fetchedUserPicture, NSError *fetchingError) {
        if (!fetchingError) {
          PFFile *imageFile = userPicture[@"imageFile"];
          if (imageFile) {
            [imageFile getDataInBackgroundWithBlock:^(NSData *imageData, NSError *dataError) {
              if (!dataError) {
                self.profilePictureImage = [[UIImage imageWithData:imageData] getRoundedRectImage];
                [subscriber sendNext:self.profilePictureImage];
              } else {
                DDLogError(@"Error occured while getting data for user profile picture: %@", dataError);
                [subscriber sendNext:[[UIImage imageNamed:@"ProfilePicturePlaceholder"] getRoundedRectImage]];
              }
              [subscriber sendCompleted];
            }];
          } else {
            NSURL *imageUrl = [NSURL URLWithString:userPicture[@"imageUrl"]];
            SDWebImageManager *manager = [SDWebImageManager sharedManager];
            [manager downloadImageWithURL:imageUrl options:0 progress:nil completed:^(UIImage *image, NSError *downloadingError, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
              if (!downloadingError) {
                self.profilePictureImage = [image getRoundedRectImage];
                [subscriber sendNext:self.profilePictureImage];
              } else {
                DDLogError(@"Error occured while downloading user profile picture: %@", downloadingError);
                [subscriber sendNext:[[UIImage imageNamed:@"ProfilePicturePlaceholder"] getRoundedRectImage]];
              }
              [subscriber sendCompleted];
            }];
          }
        } else {
          DDLogError(@"Error occured while fetching user profile picture: %@", fetchingError);
          [subscriber sendNext:[[UIImage imageNamed:@"ProfilePicturePlaceholder"] getRoundedRectImage]];
          [subscriber sendCompleted];
        }
      }];
    } else {
      [subscriber sendNext:[[UIImage imageNamed:@"ProfilePicturePlaceholder"] getRoundedRectImage]];
      [subscriber sendCompleted];
    }
    return nil;
  }];
}

- (RACSignal *)saveProfilePicture:(UIImage *)image {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    self.profilePictureImage = [image getRoundedRectImage];

    NSData *imageData = UIImageJPEGRepresentation(image, 0.7f);
    PFFile *imageFile = [PFFile fileWithName:@"profile-picture.jpg" data:imageData];

    PFObject *userPicture = [PFObject objectWithClassName:@"UserPicture"];
    userPicture[@"imageFile"] = imageFile;
    [userPicture saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
      if (succeeded) {
        DDLogVerbose(@"Saved user profile picture");
        self[kUserPictureKey] = userPicture;
        [self saveEventually];
        [subscriber sendCompleted];
      } else {
        [subscriber sendError:error];
      }
    }];
    return nil;
  }];
}

- (RACSignal *)karmaTransactionWithAmount:(NSNumber *)amount description:(NSString *)description {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    [PFCloud callFunctionInBackground:@"karmaTransaction" withParameters:@{
       @"userId" : self.objectId,
       @"amount" : amount,
       @"description" : description
     } block:^(PFObject *karmaTransaction, NSError *error) {
      if (karmaTransaction) {
        [subscriber sendNext:karmaTransaction];
        [subscriber sendCompleted];
      } else {
        [subscriber sendError:error];
      }
    }];
    return nil;
  }];
}

- (RACSignal *)getInterests {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    PFQuery *userInterestsQuery = [PFQuery queryWithClassName:@"UserInterest"];
    [userInterestsQuery whereKey:kUserKey equalTo:self];
    [userInterestsQuery includeKey:kInterestKey];
    [userInterestsQuery findObjectsInBackgroundWithBlock:^(NSArray *userInterests, NSError *error) {
      if (!error) {
        NSMutableArray *interests = [NSMutableArray new];
        for (PFObject *userInterest in userInterests) {
          [interests addObject:userInterest[kInterestKey]];
        }
        [subscriber sendNext:interests];
        [subscriber sendCompleted];
      } else {
        [subscriber sendError:error];
      }
    }];
    return nil;
  }];
}

- (RACSignal *)getMeetingPlaces {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    PFQuery *userMeetingPlacesQuery = [PFQuery queryWithClassName:@"UserMeetingPlace"];
    [userMeetingPlacesQuery whereKey:kUserKey equalTo:self];
    [userMeetingPlacesQuery includeKey:kMeetingPlaceKey];
    [userMeetingPlacesQuery findObjectsInBackgroundWithBlock:^(NSArray *userMeetingPlaces, NSError *error) {
      if (!error) {
        NSMutableArray *meetingPlaces = [NSMutableArray new];
        for (PFObject *userMeetingPlace in userMeetingPlaces) {
          [meetingPlaces addObject:userMeetingPlace[kMeetingPlaceKey]];
        }
        [subscriber sendNext:meetingPlaces];
        [subscriber sendCompleted];
      } else {
        [subscriber sendError:error];
      }
    }];
    return nil;
  }];
}

- (RACSignal *)getTimeSlots {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    PFQuery *userFreeTimesQuery = [PFQuery queryWithClassName:@"UserFreeTime"];
    [userFreeTimesQuery whereKey:kUserKey equalTo:self];
    [userFreeTimesQuery includeKey:kTimeSlotKey];
    [userFreeTimesQuery findObjectsInBackgroundWithBlock:^(NSArray *userFreeTimes, NSError *error) {
      if (!error) {
        NSMutableArray *timeSlots = [NSMutableArray new];
        for (PFObject *userFreeTime in userFreeTimes) {
          [timeSlots addObject:userFreeTime[kTimeSlotKey]];
        }
        [subscriber sendNext:timeSlots];
        [subscriber sendCompleted];
      } else {
        [subscriber sendError:error];
      }
    }];
    return nil;
  }];
}

- (void)clearCache {
  self.profilePictureImage = nil;
}

@end
