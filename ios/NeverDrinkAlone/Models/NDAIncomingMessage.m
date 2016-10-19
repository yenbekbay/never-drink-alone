#import "NDAIncomingMessage.h"

#import "NSDate+NDAHelpers.h"
#import <Parse/Parse.h>
#import <RNCryptor/RNDecryptor.h>

@interface NDAIncomingMessage ()

@property (copy, nonatomic) NSString *chatId;

@end

@implementation NDAIncomingMessage

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

- (JSQMessage *)createWithItem:(NSDictionary *)item {
  JSQMessage *message;

  if ([item[@"type"] isEqualToString:@"text"]) {
    message = [self createTextMessage:item];
  }

  return message;
}

#pragma mark Private

- (JSQMessage *)createTextMessage:(NSDictionary *)item {
  NSString *name = item[@"name"];
  NSString *userId = item[@"userId"];
  NSDate *date = [NSDate dateFromMessageString:item[@"date"]];

  NSString *text = [self decryptedText:item[@"text"]];

  return [[JSQMessage alloc] initWithSenderId:userId senderDisplayName:name date:date text:text];
}

- (NSString *)decryptedText:(NSString *)text {
  NSError *error;
  NSData *encryptedData = [[NSData alloc] initWithBase64EncodedString:text options:0];
  NSData *decryptedData = [RNDecryptor decryptData:encryptedData withPassword:@"0123456789" error:&error];

  return [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
}

@end
