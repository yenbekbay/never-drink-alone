#import "NDAChatViewController.h"

#import "CRGradientNavigationBar.h"
#import "JTProgressHUD.h"
#import "NDAConstants.h"
#import "NDAIncomingMessage.h"
#import "NDAOutcomingMessage.h"
#import "NSDate+NDAHelpers.h"
#import "PFUser+NDAHelpers.h"
#import "UIColor+NDAHelpers.h"
#import "UIColor+NDATints.h"
#import "UIImage+NDAHelpers.h"
#import <Firebase/Firebase.h>
#import <Parse/Parse.h>

// static NSUInteger const kInsertMessagesCount = 10;

#define HIDE_AVATARS 1
#define HIDE_NAMES 1
#define LIMIT_MESSAGES 0

@interface NDAChatViewController ()

@property (copy, nonatomic) NSString *chatId;
@property (nonatomic) Firebase *firebase;
@property (nonatomic) JSQMessagesBubbleImage *bubbleImageIncoming;
@property (nonatomic) JSQMessagesBubbleImage *bubbleImageOutgoing;
@property (nonatomic) NDAMatch *match;
@property (nonatomic) NSMutableArray *allItems;
@property (nonatomic) NSMutableArray *currentItems;
@property (nonatomic) NSMutableArray *messages;
@property (nonatomic) NSMutableDictionary *avatars;
@property (nonatomic) NSMutableDictionary *loading;
@property (nonatomic) NSUInteger allItemsCount;
@property (nonatomic, getter = isInitialized) BOOL initialized;

@end

@implementation NDAChatViewController

- (instancetype)initWithMatch:(NDAMatch *)match {
  self = [super init];
  if (!self) {
    return nil;
  }

  self.match = match;
  [self startChat];
  self.allItems = [NSMutableArray new];
  self.currentItems = [NSMutableArray new];
  self.messages = [NSMutableArray new];
  self.loading = [NSMutableDictionary new];
  self.avatars = [NSMutableDictionary new];

  return self;
}

#pragma mark Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];

  PFUser *otherUser = [self.match.firstUser.objectId isEqualToString:[PFUser currentUser].objectId] ? self.match.secondUser : self.match.firstUser;
  self.navigationItem.title = [NSString stringWithFormat:NSLocalizedString(@"Чат с %@", nil), [otherUser fullName]];
  self.senderId = [PFUser currentUser].objectId;
  self.senderDisplayName = [[PFUser currentUser] fullName];
  self.inputToolbar.contentView.leftBarButtonItem = nil;
  [self.inputToolbar.contentView.rightBarButtonItem setTitleColor:[UIColor nda_complementaryColor] forState:UIControlStateNormal];
  [self.inputToolbar.contentView.rightBarButtonItem setTitleColor:[[UIColor nda_complementaryColor] darkerColor:0.1f] forState:UIControlStateHighlighted];

  JSQMessagesBubbleImageFactory *bubbleFactory = [JSQMessagesBubbleImageFactory new];
  self.bubbleImageOutgoing = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor nda_complementaryColor]];
  self.bubbleImageIncoming = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor nda_lightGrayColor]];
#if HIDE_AVATARS
  self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
  self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
#endif

  [JSQMessagesCollectionViewCell registerMenuAction:@selector(actionCopy:)];
  UIMenuItem *menuItemCopy = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Скопировать", nil) action:@selector(actionCopy:)];
  [UIMenuController sharedMenuController].menuItems = @[menuItemCopy];

  self.firebase = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@/Message/%@", kFirebaseUrl, self.chatId]];

  [JTProgressHUD showWithTransition:JTProgressHUDTransitionFade];
  [self loadMessages];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [(CRGradientNavigationBar *)self.navigationController.navigationBar setBarTintGradientColors:@[
     [UIColor nda_primaryColor],
     [UIColor nda_complementaryColor]
   ]];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  self.collectionView.collectionViewLayout.springinessEnabled = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  if (self.isMovingFromParentViewController) {
    [self clearRecentCounter];
    [self.firebase removeAllObservers];
  }
}

#pragma mark Private

- (void)startChat {
  PFUser *user1 = self.match.firstUser;
  PFUser *user2 = self.match.secondUser;

  NSString *userId1 = user1.objectId;
  NSString *userId2 = user2.objectId;

  self.chatId = [userId1 compare:userId2] < 0 ? [userId1 stringByAppendingString : userId2] :[userId2 stringByAppendingString:userId1];

  [self createRecentIfNeededWithUser:user1];
  [self createRecentIfNeededWithUser:user2];
}

- (void)createRecentIfNeededWithUser:(PFUser *)user {
  Firebase *firebase = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@/Recent", kFirebaseUrl]];
  FQuery *query = [[firebase queryOrderedByChild:@"chatId"] queryEqualToValue:self.chatId];

  [query observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
    BOOL shouldCreate = YES;
    if (snapshot.value != [NSNull null]) {
      for (NSDictionary *recent in [snapshot.value allValues]) {
        if ([recent[@"userId"] isEqualToString:user.objectId]) {
          shouldCreate = NO;
          break;
        }
      }
    }
    if (shouldCreate) {
      [self createRecentItemWithUser:user];
    }
  }];
}

- (void)createRecentItemWithUser:(PFUser *)user {
  Firebase *firebase = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@/Recent", kFirebaseUrl]];
  Firebase *reference = [firebase childByAutoId];

  [reference setValue:@{
     @"recentId" : reference.key,
     @"userId" : user.objectId,
     @"chatId" : self.chatId,
     @"members" : @[self.match.firstUser.objectId, self.match.secondUser.objectId],
     @"lastMessage" : @"",
     @"counter" : @0,
     @"date" : [[NSDate date] messageString],
     @"password" : @""
   } withCompletionBlock:^(NSError *error, Firebase *ref) {
    if (error) {
      DDLogError(@"Error occured while creating a recent item: %@", error);
    } else {
      DDLogVerbose(@"Created recent item for user %@", user.objectId);
    }
  }];
}

- (void)clearRecentCounter {
  Firebase *firebase = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@/Recent", kFirebaseUrl]];
  FQuery *query = [[firebase queryOrderedByChild:@"chatId"] queryEqualToValue:self.chatId];

  [query observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
    if (snapshot.value != [NSNull null]) {
      for (NSDictionary *recent in [snapshot.value allValues]) {
        if ([recent[@"userId"] isEqualToString:[PFUser currentUser].objectId]) {
          [self clearRecentCounterItem:recent];
        }
      }
      DDLogVerbose(@"Cleared recent counter");
    }
  }];
}

- (void)clearRecentCounterItem:(NSDictionary *)recent {
  Firebase *firebase = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@/Recent/%@", kFirebaseUrl, recent[@"recentId"]]];

  [firebase updateChildValues:@{ @"counter" : @0 } withCompletionBlock:^(NSError *error, Firebase *ref) {
    if (error) {
      DDLogError(@"Error occured while clearing recent counter: %@", error);
    }
  }];
}

- (void)loadMessages {
  self.initialized = NO;
  self.automaticallyScrollsToMostRecentMessage = NO;

  [self.firebase observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
    if (self.isInitialized) {
      BOOL incoming = [self addMessage:snapshot.value];
      if (incoming) {
        [JSQSystemSoundPlayer jsq_playMessageReceivedSound];
        [self setMessageAsRead:[snapshot.value mutableCopy]];
      }
      [self finishReceivingMessage];
    } else {
      [self.allItems addObject:snapshot.value];
    }
  }];

  [self.firebase observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
    [self updateMessage:snapshot.value];
  }];

  [self.firebase observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
    [self deleteMessage:snapshot.value];
  }];

  [self.firebase observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
    if ([JTProgressHUD isVisible]) {
      [JTProgressHUD hide];
    }
    DDLogVerbose(@"Loaded %@ messages", @(self.allItems.count));
    [self insertMessages];
    [self scrollToBottomAnimated:NO];
    self.initialized = YES;
  }];
}

- (void)setMessageAsRead:(NSMutableDictionary *)message {
  Firebase *firebase = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@/Message/%@/%@", kFirebaseUrl, self.chatId, message[@"messageId"]]];

  message[@"status"] = @"Read";
  [firebase setValue:message withCompletionBlock:^(NSError *error, Firebase *ref) {
    if (error) {
      DDLogError(@"Error occured while updating status for message: %@", error);
    }
  }];
}

- (void)insertMessages {
  NSInteger max = (NSInteger)self.allItems.count - (NSInteger)self.allItemsCount;
  NSInteger min;

#if LIMIT_MESSAGES
  min = MAX(0, max - (NSInteger)kInsertMessagesCount);
#else
  min = 0;
#endif

  for (NSInteger i = max - 1; i >= min; i--) {
    NSDictionary *item = self.allItems[(NSUInteger)i];
    [self insertMessage:item];
    if ([self isIncoming:item]) {
      [self setMessageAsRead:[item mutableCopy]];
    }
    self.allItemsCount++;
  }
  DDLogVerbose(@"Inserted %@ messages", @(max - min));

  self.automaticallyScrollsToMostRecentMessage = NO;
  [self finishReceivingMessage];
  self.automaticallyScrollsToMostRecentMessage = YES;
#if LIMIT_MESSAGES
  self.showLoadEarlierMessagesHeader = (self.allItemsCount != self.allItems.count);
#else
  self.showLoadEarlierMessagesHeader = NO;
#endif
}

- (BOOL)insertMessage:(NSDictionary *)item {
  NDAIncomingMessage *incoming = [[NDAIncomingMessage alloc] initWithChatId:self.chatId];
  JSQMessage *message = [incoming createWithItem:item];

  [self.currentItems insertObject:item atIndex:0];
  [self.messages insertObject:message atIndex:0];

  return [self isIncoming:item];
}

- (BOOL)addMessage:(NSDictionary *)item {
  NDAIncomingMessage *incoming = [[NDAIncomingMessage alloc] initWithChatId:self.chatId];
  JSQMessage *message = [incoming createWithItem:item];

  [self.currentItems addObject:item];
  [self.messages addObject:message];

  return [self isIncoming:item];
}

- (void)updateMessage:(NSDictionary *)item {
  for (NSUInteger i = 0; i < self.currentItems.count; i++) {
    NSDictionary *temp = self.currentItems[i];
    if ([item[@"messageId"] isEqualToString:temp[@"messageId"]]) {
      self.currentItems[i] = item;
      [self.collectionView reloadData];
      break;
    }
  }
}

- (void)deleteMessage:(NSDictionary *)item {
  for (NSUInteger i = 0; i < self.currentItems.count; i++) {
    NSDictionary *temp = self.currentItems[i];
    if ([item[@"messageId"] isEqualToString:temp[@"messageId"]]) {
      [self.currentItems removeObjectAtIndex:i];
      [self.messages removeObjectAtIndex:i];
      [self.collectionView reloadData];
      break;
    }
  }
}

- (void)loadAvatar:(NSString *)senderId {
  if (self.loading[senderId]) {
    return;
  }
  self.loading[senderId] = @YES;

  if ([senderId isEqualToString:[PFUser currentUser].objectId]) {
    [self downloadAvatar:[PFUser currentUser]];
    return;
  }

  PFQuery *query = [PFUser query];
  [query whereKey:@"objectId" equalTo:senderId];
  [query getFirstObjectInBackgroundWithBlock:^(PFObject *userObject, NSError *error) {
    if (!error) {
      if (userObject) {
        [self downloadAvatar:(PFUser *)userObject];
      } else {
        [self.loading removeObjectForKey:senderId];
      }
    } else {
      [self.loading removeObjectForKey:senderId];
    }
  }];
}

- (void)downloadAvatar:(PFUser *)user {
  [[[user getProfilePicture] deliverOn:RACScheduler.mainThreadScheduler] subscribeNext:^(UIImage *image) {
    self.avatars[user.objectId] = [JSQMessagesAvatarImageFactory avatarImageWithImage:image diameter:30];
    [self performSelector:@selector(delayedReload) withObject:nil afterDelay:0.1f];
  } error:^(NSError *error) {
    DDLogError(@"Error occured while getting user profile picture: %@", error);
    [self.loading removeObjectForKey:user.objectId];
  }];
}

- (void)delayedReload {
  [self.collectionView reloadData];
}

- (void)messageSend:(NSString *)text {
  NDAOutcomingMessage *outgoing = [[NDAOutcomingMessage alloc] initWithChatId:self.chatId];

  [outgoing sendWithText:text];

  [JSQSystemSoundPlayer jsq_playMessageSentSound];
  [self finishSendingMessage];
}

#pragma mark JSQMessagesViewController

- (void)didPressSendButton:(UIButton *)button withMessageText:(NSString *)text senderId:(NSString *)senderId senderDisplayName:(NSString *)name date:(NSDate *)date {
  [self messageSend:text];
}

#pragma mark JSQMessagesViewCollectionViewDataSource

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
  return self.messages[(NSUInteger)indexPath.item];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
  return [self isOutgoing:self.currentItems[(NSUInteger)indexPath.item]] ? self.bubbleImageOutgoing : self.bubbleImageIncoming;
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
#if HIDE_AVATARS
  return nil;
#else
  JSQMessage *message = self.messages[(NSUInteger)indexPath.item];
  if (!self.avatars[message.senderId]) {
    [self loadAvatar:message.senderId];
    return [JSQMessagesAvatarImageFactory avatarImageWithImage:[UIImage imageWithColor:[UIColor lightGrayColor]] diameter:30];
  } else {
    return self.avatars[message.senderId];
  }
#endif
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.item % 3 == 0) {
    JSQMessage *message = self.messages[(NSUInteger)indexPath.item];
    return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date];
  } else {
    return nil;
  }
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath {
  if ([self isIncoming:self.currentItems[(NSUInteger)indexPath.item]]) {
#if HIDE_NAMES
    return nil;
#else
    JSQMessage *message = self.messages[(NSUInteger)indexPath.item];
    if (indexPath.item > 0) {
      JSQMessage *previous = self.messages[(NSUInteger)indexPath.item - 1];
      if ([previous.senderId isEqualToString:message.senderId]) {
        return nil;
      }
    }
    return [[NSAttributedString alloc] initWithString:message.senderDisplayName];
#endif
  } else {
    return nil;
  }
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath {
  NSArray *outgoing = [self.currentItems filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL (NSDictionary *item, NSDictionary *bindings) {
    return [self isOutgoing:item];
  }]];
  NSDictionary *item = self.currentItems[(NSUInteger)indexPath.item];

  if (item != [outgoing lastObject]) {
    return nil;
  }
  return [[NSAttributedString alloc] initWithString:[self localizedStringForItemStatus:item[@"status"]]];
}

- (NSString *)localizedStringForItemStatus:(NSString *)status {
  if ([status isEqualToString:@"Delivered"]) {
    return NSLocalizedString(@"Доставлено", nil);
  } else if ([status isEqualToString:@"Read"]) {
    return NSLocalizedString(@"Прочитано", nil);
  } else {
    return status;
  }
}

#pragma mark JSQMessagesViewCollectionViewDelegate

- (void)collectionView:(JSQMessagesCollectionView *)collectionView header:(JSQMessagesLoadEarlierHeaderView *)headerView didTapLoadEarlierMessagesButton:(UIButton *)sender {
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView atIndexPath:(NSIndexPath *)indexPath {
  NSDictionary *item = self.currentItems[(NSUInteger)indexPath.item];

  if ([self isIncoming:item]) {
    // TODO: Back to user profile
  }
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath {
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapCellAtIndexPath:(NSIndexPath *)indexPath touchLocation:(CGPoint)touchLocation {
}

#pragma mark UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  return (NSInteger)self.messages.count;
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  UIColor *color = [self isOutgoing:self.currentItems[(NSUInteger)indexPath.item]] ? [UIColor whiteColor] : [UIColor blackColor];

  JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];

  cell.textView.textColor = color;
  cell.textView.linkTextAttributes = @{
    NSForegroundColorAttributeName : color
  };

  return cell;
}

#pragma mark UICollectionViewDelegate

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
  NSDictionary *item = self.currentItems[(NSUInteger)indexPath.item];

  if (action == @selector(actionCopy:)) {
    if ([item[@"type"] isEqualToString:@"text"]) {
      return YES;
    }
  }
  return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
  if (action == @selector(actionCopy:)) {
    [self actionCopy:indexPath];
  }
}

#pragma mark JSQMessagesCollectionViewFlowLayoutDelegate

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath {
  return (indexPath.item % 3 == 0) ? kJSQMessagesCollectionViewCellLabelHeightDefault + 5 : 0;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath {
  if ([self isIncoming:self.currentItems[(NSUInteger)indexPath.item]]) {
    if (indexPath.item > 0) {
      JSQMessage *message = self.messages[(NSUInteger)indexPath.item];
      JSQMessage *previous = self.messages[(NSUInteger)indexPath.item - 1];
      if ([previous.senderId isEqualToString:message.senderId]) {
        return 0;
      }
    }
    return kJSQMessagesCollectionViewCellLabelHeightDefault;
  } else {
    return 0;
  }
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath {
  NSArray *outgoing = [self.currentItems filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL (NSDictionary *item, NSDictionary *bindings) {
    return [self isOutgoing:item];
  }]];

  if (self.currentItems[(NSUInteger)indexPath.item] != [outgoing lastObject]) {
    return 0;
  }
  return kJSQMessagesCollectionViewCellLabelHeightDefault;
}

#pragma mark Actions

- (void)actionCopy:(NSIndexPath *)indexPath {
  NSDictionary *item = self.currentItems[(NSUInteger)indexPath.item];
  [[UIPasteboard generalPasteboard] setString:item[@"text"]];
}

#pragma mark Helpers

- (BOOL)isIncoming:(NSDictionary *)item {
  return ![self.senderId isEqualToString:item[@"userId"]];
}

- (BOOL)isOutgoing:(NSDictionary *)item {
  return [self.senderId isEqualToString:item[@"userId"]];
}

@end
