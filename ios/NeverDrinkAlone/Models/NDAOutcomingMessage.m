#import "NDAOutcomingMessage.h"

#import "NDAConstants.h"
#import "NSDate+NDAHelpers.h"
#import "PFUser+NDAHelpers.h"
#import <Firebase/Firebase.h>
#import <Parse/Parse.h>
#import <RNCryptor/RNEncryptor.h>

@interface NDAOutcomingMessage ()

@property (nonatomic) NSString *chatId;

@end

@implementation NDAOutcomingMessage

#pragma mark Initialization

- (instancetype)initWithChatId:(NSString *)chatId {
  self = [super init];
  if (!self) {
    return nil;
  }

  self.chatId = chatId;

  return self;
}

#pragma mark Public

- (void)sendWithText:(NSString *)text {
  NSMutableDictionary *item = [NSMutableDictionary new];

  item[@"userId"] = [PFUser currentUser].objectId;
  item[@"name"] = [[PFUser currentUser] fullName];
  item[@"date"] = [[NSDate date] messageString];
  item[@"status"] = @"Delivered";

  if (text) {
    [self sendTextMessage:item Text:text];
  }
}

#pragma mark Private

- (void)sendTextMessage:(NSMutableDictionary *)item Text:(NSString *)text {
  item[@"text"] = text;
  item[@"type"] = @"text";
  [self sendMessage:item];
}

- (void)sendMessage:(NSMutableDictionary *)item {
  NSString *unencryptedText = item[@"text"];
  item[@"text"] = [self encryptedText:item[@"text"]];

  Firebase *firebase = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@/Message/%@", kFirebaseUrl, self.chatId]];
  Firebase *reference = [firebase childByAutoId];
  item[@"messageId"] = reference.key;

  [reference setValue:item withCompletionBlock:^(NSError *error, Firebase *ref) {
    if (error) {
      DDLogError(@"Error occured while sending message: %@", error);
    }
  }];

  [self sendPushNotificationWithText:unencryptedText];
  [self updateRecentsWithText:item[@"text"]];
}

- (void)sendPushNotificationWithText:(NSString *)text {
  Firebase *firebase = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@/Recent", kFirebaseUrl]];
  FQuery *firebaseQuery = [[firebase queryOrderedByChild:@"chatId"] queryEqualToValue:self.chatId];

  [firebaseQuery observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
    if (snapshot.value != [NSNull null]) {
      NSArray *recents = [snapshot.value allValues];
      NSDictionary *recent = [recents firstObject];
      if (recent) {
        NSString *message = [NSString stringWithFormat:@"%@: %@", [[PFUser currentUser] fullName], text];

        PFQuery *parseQuery = [PFUser query];
        [parseQuery whereKey:@"objectId" containedIn:recent[@"members"]];
        [parseQuery whereKey:@"objectId" notEqualTo:[PFUser currentUser].objectId];
        [parseQuery setLimit:1000];

        PFQuery *queryInstallation = [PFInstallation query];
        [queryInstallation whereKey:kUserKey matchesQuery:parseQuery];

        PFPush *push = [PFPush new];
        [push setQuery:queryInstallation];
        [push setData:@{ @"alert" : message, @"sound" : @"default", @"badge" : @"Increment" }];
        [push sendPushInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
          if (error) {
            DDLogError(@"Error occured while sending push notification: %@", error);
          }
        }];
      }
    }
  }];
}

- (void)updateRecentsWithText:(NSString *)text {
  Firebase *firebase = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@/Recent", kFirebaseUrl]];
  FQuery *query = [[firebase queryOrderedByChild:@"chatId"] queryEqualToValue:self.chatId];

  [query observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
    if (snapshot.value != [NSNull null]) {
      for (NSDictionary *recent in [snapshot.value allValues]) {
        [self updateRecentItem:recent text:text];
      }
    }
  }];
}

- (void)updateRecentItem:(NSDictionary *)recent text:(NSString *)text {
  NSString *date = [[NSDate date] messageString];
  NSInteger counter = [recent[@"counter"] integerValue];
  if ([recent[@"userId"] isEqualToString:[PFUser currentUser].objectId] == NO) {
    counter++;
  }

  Firebase *firebase = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@/Recent/%@", kFirebaseUrl, recent[@"recentId"]]];
  NSDictionary *values = @{
    @"lastMessage" : text,
    @"counter" : @(counter),
    @"date" : date
  };
  [firebase updateChildValues:values withCompletionBlock:^(NSError *error, Firebase *ref) {
    if (error) {
      DDLogError(@"Error occured while updating recent item: %@", error);
    }
  }];
}

- (NSString *)encryptedText:(NSString *)text {
  NSError *error;
  NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
  NSData *encryptedData = [RNEncryptor encryptData:data withSettings:kRNCryptorAES256Settings password:@"0123456789" error:&error];

  return [encryptedData base64EncodedStringWithOptions:0];
}

@end
