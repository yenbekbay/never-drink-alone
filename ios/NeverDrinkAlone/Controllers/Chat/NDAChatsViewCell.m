#import "NDAChatsViewCell.h"

#import "NDAConstants.h"
#import "NSDate+NDAHelpers.h"
#import "PFUser+NDAHelpers.h"
#import "UIColor+NDATints.h"
#import "UIFont+NDASizes.h"
#import "UILabel+NDAHelpers.h"
#import "UIView+AYUtils.h"
#import <Parse/Parse.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <RNCryptor/RNDecryptor.h>

UIEdgeInsets const kChatsCellPadding = {
  10, 10, 10, 10
};

@interface NDAChatsViewCell ()

@property (nonatomic) UIImageView *avatarImageView;
@property (nonatomic) UILabel *nameLabel;
@property (nonatomic) UILabel *lastMessageLabel;
@property (nonatomic) UILabel *elapsedLabel;
@property (nonatomic) UILabel *counterLabel;
@property (nonatomic) NDAMatch *match;

@end

@implementation NDAChatsViewCell

#pragma mark Initialization

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (!self) {
    return nil;
  }

  self.userInteractionEnabled = NO;

  self.avatarImageView = [[UIImageView alloc] initWithFrame:CGRectMake(kChatsCellPadding.left, kChatsCellPadding.top, kChatsCellHeight - kChatsCellPadding.top - kChatsCellPadding.bottom, kChatsCellHeight - kChatsCellPadding.top - kChatsCellPadding.bottom)];
  self.avatarImageView.layer.cornerRadius = self.avatarImageView.height / 2;
  self.avatarImageView.clipsToBounds = YES;
  [self.contentView addSubview:self.avatarImageView];

  self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.avatarImageView.right + kChatsCellPadding.left, kChatsCellPadding.top, 0, 0)];
  self.nameLabel.font = [UIFont fontWithName:kRegularFontName size:[UIFont mediumTextFontSize]];
  self.nameLabel.textColor = [UIColor blackColor];
  [self.contentView addSubview:self.nameLabel];

  self.lastMessageLabel = [[UILabel alloc] initWithFrame:self.nameLabel.frame];
  self.lastMessageLabel.font = [UIFont fontWithName:kRegularFontName size:[UIFont smallTextFontSize]];
  self.lastMessageLabel.textColor = [UIColor nda_darkGrayColor];
  [self.contentView addSubview:self.lastMessageLabel];

  self.elapsedLabel = [UILabel new];
  self.elapsedLabel.font = [UIFont fontWithName:kRegularFontName size:[UIFont extraSmallTextFontSize]];
  self.elapsedLabel.textColor = [UIColor nda_greenColor];
  [self.contentView addSubview:self.elapsedLabel];

  self.counterLabel = [UILabel new];
  self.counterLabel.font = [UIFont fontWithName:kRegularFontName size:[UIFont extraSmallTextFontSize]];
  self.counterLabel.textColor = [UIColor nda_accentColor];
  [self.contentView addSubview:self.counterLabel];

  return self;
}

#pragma mark Lifecycle

- (void)layoutSubviews {
  [super layoutSubviews];

  [self.elapsedLabel sizeToFit];
  [self.counterLabel sizeToFit];
  self.elapsedLabel.right = self.width - kChatsCellPadding.right;
  self.elapsedLabel.bottom = self.height / 2 - kChatsCellPadding.bottom / 2;
  self.counterLabel.top = self.height / 2 + kChatsCellPadding.top / 2;
  self.counterLabel.right = self.width - kChatsCellPadding.right;

  [self.nameLabel sizeToFit];
  [self.lastMessageLabel sizeToFit];
  self.nameLabel.width = MIN(self.elapsedLabel.left, self.counterLabel.left) - self.nameLabel.left - kChatsCellPadding.right;
  self.nameLabel.bottom = self.elapsedLabel.bottom;
  self.lastMessageLabel.width = MIN(self.elapsedLabel.left, self.counterLabel.left) - self.lastMessageLabel.left - kChatsCellPadding.right;
  self.lastMessageLabel.top = self.counterLabel.top;
}

- (void)prepareForReuse {
  self.avatarImageView.image = nil;
  self.elapsedLabel.text = @"";
  self.counterLabel.text = @"";
  self.nameLabel.text = @"";
  self.lastMessageLabel.text = @"";
}

#pragma mark Setters & getters

- (void)setRecent:(NSDictionary *)recent {
  _recent = recent;

  PFQuery *query = [PFUser query];
  [query whereKey:@"objectId" containedIn:recent[@"members"]];
  [query whereKey:@"objectId" notEqualTo:[PFUser currentUser].objectId];
  [query getFirstObjectInBackgroundWithBlock:^(PFObject *userObject, NSError *userError) {
    if (!userError) {
      [[[(PFUser *)userObject getProfilePicture] deliverOn:RACScheduler.mainThreadScheduler] subscribeNext:^(UIImage *image) {
        self.avatarImageView.image = image;
      } error:^(NSError *profilePictureError) {
        DDLogError(@"Error occured while getting user profile picture: %@", profilePictureError);
      }];
      self.match = [[NDAMatch alloc] initWithFirstUser:[PFUser currentUser] secondUser:(PFUser *)userObject interests:@[]];
      self.userInteractionEnabled = YES;
      self.nameLabel.text = [(PFUser *)userObject fullName];
      self.lastMessageLabel.text = [self decryptedText:recent[@"lastMessage"]];

      NSDate *date = [NSDate dateFromMessageString:recent[@"date"]];
      self.elapsedLabel.text = [date timeAgo];

      NSInteger counter = [recent[@"counter"] integerValue];
      self.counterLabel.text = (counter == 0) ? @"" : [NSString stringWithFormat:@"%@ %@", @(counter), NSLocalizedString(@"новых", nil)];

      [self layoutSubviews];
    } else {
      DDLogError(@"Error occured while getting user: %@", userError);
    }
  }];
}

#pragma mark Private

- (NSString *)decryptedText:(NSString *)text {
  NSError *error;
  NSData *encryptedData = [[NSData alloc] initWithBase64EncodedString:text options:0];
  NSData *decryptedData = [RNDecryptor decryptData:encryptedData withPassword:@"0123456789" error:&error];

  return [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
}

@end
