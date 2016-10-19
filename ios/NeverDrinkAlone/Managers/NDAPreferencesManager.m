#import "NDAPreferencesManager.h"

#import "Foursquare2.h"
#import "JTProgressHUD.h"
#import "NDAAlertManager.h"
#import "NDAConstants.h"
#import "NDAFreeTimesViewController.h"
#import "NDAInterest.h"
#import "NDAInterestsViewController.h"
#import "NDALocationManager.h"
#import "NDAMainPageViewController.h"
#import "NDAMeetingPlace.h"
#import "NDAMeetingPlacesViewController.h"
#import "NDATimeSlot.h"
#import <Parse/Parse.h>

@interface NDAPreferencesManager () <UIAlertViewDelegate>

@property (nonatomic) NDAInterestsViewController *interestsViewController;
@property (nonatomic) NDAMeetingPlacesViewController *meetingPlacesViewController;
@property (nonatomic) NDAFreeTimesViewController *freeTimesViewController;
@property (nonatomic) NDAAlertManager *alertManager;

@end

@implementation NDAPreferencesManager

#pragma mark Initialization

- (instancetype)init {
  self = [super init];
  if (!self) {
    return nil;
  }

  [Foursquare2 setupFoursquareWithClientId:kFoursquareClientId secret:kFoursquareClientSecret callbackURL:@""];
  self.alertManager = [NDAAlertManager new];
  [self reset];

  return self;
}

+ (instancetype)sharedInstance {
  static NDAPreferencesManager *_sharedInstance = nil;
  static dispatch_once_t oncePredicate;
  dispatch_once(&oncePredicate, ^{
    _sharedInstance = [NDAPreferencesManager new];
  });
  return _sharedInstance;
}

#pragma mark Public

- (void)reset {
  self.interestsViewController = [NDAInterestsViewController new];
  self.meetingPlacesViewController = [NDAMeetingPlacesViewController new];
  [(NDAMeetingPlacesViewController *)self.meetingPlacesViewController setLoadingInProgress:YES];
  [[[NDALocationManager sharedInstance] getCurrentLocation] subscribeNext:^(CLLocation *location) {
    [self.meetingPlacesViewController locationLoaded];
  }];
  self.freeTimesViewController = [NDAFreeTimesViewController new];
  self.currentViewController = self.interestsViewController;
  self.firstViewController = self.interestsViewController;
}

- (void)pushNextViewController:(UINavigationController *)navigationController {
  self.currentViewController = [self nextViewController:navigationController];
  PFUser *user = [PFUser currentUser];
  if (self.currentViewController) {
    [navigationController pushViewController:self.currentViewController animated:YES];
  } else if (![user[kUserDidFinishRegistrationKey] boolValue]) {
    [JTProgressHUD showWithTransition:JTProgressHUDTransitionFade];
    user[kUserDidFinishRegistrationKey] = @YES;
    [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
      [JTProgressHUD hide];
      if (succeeded) {
        [self saveInfo];
        [navigationController pushViewController:[NDAMainPageViewController new] animated:YES];
        [self reset];
      } else {
        [self.alertManager showNotificationWithText:NSLocalizedString(@"Что-то пошло не так. Попробуйте еще раз", nil)];
      }
    }];
  } else {
    [self saveInfo];
    for (UIViewController *viewController in navigationController.viewControllers) {
      if ([viewController isKindOfClass:[NDAMainPageViewController class]]) {
        [navigationController popToViewController:viewController animated:YES];
        return;
      }
    }
    [navigationController pushViewController:[NDAMainPageViewController new] animated:YES];
  }
}

#pragma mark Private

- (NDAPreferencesViewController *)nextViewController:(UINavigationController *)navigationController {
  self.currentViewController = (NDAPreferencesViewController *)navigationController.visibleViewController;
  if (self.currentViewController == self.interestsViewController) {
    return self.meetingPlacesViewController;
  } else if (self.currentViewController == self.meetingPlacesViewController) {
    return self.freeTimesViewController;
  } else {
    return nil;
  }
}

- (void)saveInfo {
  PFQuery *userInterestQuery = [PFQuery queryWithClassName:@"UserInterest"];
  PFQuery *userMeetingPlaceQuery = [PFQuery queryWithClassName:@"UserMeetingPlace"];
  PFQuery *userFreeTimeQuery = [PFQuery queryWithClassName:@"UserFreeTime"];

  for (PFQuery *query in @[userInterestQuery, userMeetingPlaceQuery, userFreeTimeQuery]) {
    [query whereKey:kUserKey equalTo:[PFUser currentUser]];
  }

  [userInterestQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
    for (PFObject *object in objects) {
      [object deleteEventually];
    }
    for (NDAInterest *interest in self.interestsViewController.addedObjects) {
      [self saveUserInterest:interest];
    }
  }];

  [userMeetingPlaceQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
    for (PFObject *object in objects) {
      [object deleteEventually];
    }
    for (NDAMeetingPlace *meetingPlace in self.meetingPlacesViewController.addedObjects) {
      [self saveUserMeetingPlace:meetingPlace];
    }
  }];

  [userFreeTimeQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
    for (PFObject *object in objects) {
      [object deleteEventually];
    }
    for (NDATimeSlot *timeSlot in self.freeTimesViewController.addedObjects) {
      [self saveUserTimeSlot:timeSlot];
    }
  }];
}

- (void)saveUserInterest:(NDAInterest *)interest {
  PFQuery *interestQuery = [NDAInterest query];
  [interestQuery whereKey:@"name" equalTo:interest.name];
  [interestQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
    PFObject *userInterest = [PFObject objectWithClassName:@"UserInterest"];
    userInterest[kUserKey] = [PFUser currentUser];
    userInterest[kInterestKey] = object ? : interest;
    [userInterest saveEventually];
  }];
}

- (void)saveUserMeetingPlace:(NDAMeetingPlace *)meetingPlace {
  PFQuery *meetingPlaceQuery = [NDAMeetingPlace query];
  [meetingPlaceQuery whereKey:@"name" equalTo:meetingPlace.name];
  [meetingPlaceQuery whereKey:@"address" equalTo:meetingPlace.address];
  [meetingPlaceQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
    PFObject *userMeetingPlace = [PFObject objectWithClassName:@"UserMeetingPlace"];
    userMeetingPlace[kUserKey] = [PFUser currentUser];
    userMeetingPlace[kMeetingPlaceKey] = object ? : meetingPlace;
    [userMeetingPlace saveEventually];
  }];
}

- (void)saveUserTimeSlot:(NDATimeSlot *)timeSlot {
  PFQuery *timeSlotQuery = [NDATimeSlot query];
  [timeSlotQuery whereKey:@"weekday" equalTo:timeSlot.weekday];
  [timeSlotQuery whereKey:@"startingHour" equalTo:timeSlot.startingHour];
  [timeSlotQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
    PFObject *userTimeSlot = [PFObject objectWithClassName:@"UserFreeTime"];
    userTimeSlot[kUserKey] = [PFUser currentUser];
    userTimeSlot[kTimeSlotKey] = object ? : timeSlot;
    [userTimeSlot saveEventually];
  }];
}

@end
