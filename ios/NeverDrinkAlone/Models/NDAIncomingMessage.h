#import <JSQMessagesViewController/JSQMessages.h>

@interface NDAIncomingMessage : NSObject

- (instancetype)initWithChatId:(NSString *)chatId;
- (JSQMessage *)createWithItem:(NSDictionary *)item;

@end
