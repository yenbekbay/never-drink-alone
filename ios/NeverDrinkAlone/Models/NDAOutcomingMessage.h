#import <JSQMessagesViewController/JSQMessages.h>

@interface NDAOutcomingMessage : NSObject

- (instancetype)initWithChatId:(NSString *)chatId;
- (void)sendWithText:(NSString *)text;

@end
