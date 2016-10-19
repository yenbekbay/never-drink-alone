#import "NDAChatsViewController.h"

#import "CRGradientNavigationBar.h"
#import "JTProgressHUD.h"
#import "NDAChatsViewCell.h"
#import "NDAChatViewController.h"
#import "NDAConstants.h"
#import "NDAMatch.h"
#import "NSDate+NDAHelpers.h"
#import "UIColor+NDATints.h"
#import "UIFont+NDASizes.h"
#import "UIView+AYUtils.h"
#import <DZNEmptyDataSet/UIScrollView+EmptyDataSet.h>
#import <Firebase/Firebase.h>
#import <Parse/Parse.h>

@interface NDAChatsViewController () <UITableViewDataSource, UITableViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

@property (nonatomic) UITableView *tableView;
@property (nonatomic) Firebase *firebase;
@property (nonatomic) NSMutableArray *recents;
@property (nonatomic, getter = isLoaded) BOOL loaded;

@end

@implementation NDAChatsViewController

#pragma mark Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  self.navigationItem.title = NSLocalizedString(@"Чаты", nil);
  self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
  self.view.backgroundColor = [UIColor whiteColor];

  self.recents = [NSMutableArray new];
  [self setUpTableView];
  [JTProgressHUD showWithTransition:JTProgressHUDTransitionFade];
  [self loadRecents];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [(CRGradientNavigationBar *)self.navigationController.navigationBar setBarTintGradientColors:@[
     [UIColor nda_primaryColor],
     [UIColor nda_complementaryColor]
   ]];
}

#pragma mark Private

- (void)setUpTableView {
  self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  self.tableView.emptyDataSetSource = self;
  self.tableView.emptyDataSetDelegate = self;
  self.tableView.tableFooterView = [UIView new];
  [self.tableView registerClass:[NDAChatsViewCell class] forCellReuseIdentifier:NSStringFromClass([NDAChatsViewCell class])];
  [self.view addSubview:self.tableView];
}

- (void)loadRecents {
  self.firebase = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@/Recent", kFirebaseUrl]];
  FQuery *query = [[self.firebase queryOrderedByChild:@"userId"] queryEqualToValue:[PFUser currentUser].objectId];
  [query observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
    [self.recents removeAllObjects];
    if (snapshot.value != [NSNull null]) {
      NSArray *sorted = [[snapshot.value allValues] sortedArrayUsingComparator:^NSComparisonResult (NSDictionary *recent1, NSDictionary *recent2) {
        NSDate *date1 = [NSDate dateFromMessageString:recent1[@"date"]];
        NSDate *date2 = [NSDate dateFromMessageString:recent2[@"date"]];
        return [date2 compare:date1];
      }];
      for (NSDictionary *recent in sorted) {
        [self.recents addObject:recent];
      }
    }
    self.loaded = YES;
    [JTProgressHUD hide];
    [self.tableView reloadData];
  }];
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return (NSInteger)self.recents.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  NDAChatsViewCell *cell = (NDAChatsViewCell *)[tableView dequeueReusableCellWithIdentifier:NSStringFromClass([NDAChatsViewCell class]) forIndexPath:indexPath];

  cell.recent = self.recents[(NSUInteger)indexPath.row];
  return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  return YES;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return kChatsCellHeight;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  NSDictionary *recent = self.recents[(NSUInteger)indexPath.row];

  [self.recents removeObject:recent];
  [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
  [self deleteRecentItem:recent];
}

- (void)deleteRecentItem:(NSDictionary *)recent {
  Firebase *firebase = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@/Recent/%@", kFirebaseUrl, recent[@"recentId"]]];

  [firebase removeValueWithCompletionBlock:^(NSError *error, Firebase *ref) {
    if (error) {
      DDLogError(@"Error occured while deleting recent item: %@", error);
    }
  }];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  NDAChatsViewCell *cell = (NDAChatsViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
  NDAChatViewController *chatViewController = [[NDAChatViewController alloc] initWithMatch:cell.match];

  [self.navigationController pushViewController:chatViewController animated:YES];
  [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark DZNEmptyDataSetSource

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView {
  return -self.navigationController.navigationBar.height;
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
  return [UIImage imageNamed:@"ChatsPlaceholder"];
}

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
  return [[NSAttributedString alloc] initWithString:NSLocalizedString(@"У вас пока нет чатов", nil) attributes:@{
            NSFontAttributeName : [UIFont fontWithName:kRegularFontName size:[UIFont largeTextFontSize]],
            NSForegroundColorAttributeName : [UIColor nda_darkGrayColor]
          }];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView {
  return [[NSAttributedString alloc] initWithString:
          NSLocalizedString(@"Вы можете перписываться с теми, с кем у вас есть подтвержденная встреча. Как только вы начнете с кем-либо чат, он появится тут.", nil) attributes:@{
            NSFontAttributeName : [UIFont fontWithName:kRegularFontName size:[UIFont smallTextFontSize]],
            NSForegroundColorAttributeName : [UIColor nda_darkGrayColor]
          }];
}

#pragma mark DZNEmptyDataSetDelegate

- (BOOL)emptyDataSetShouldDisplay:(UIScrollView *)scrollView {
  return self.isLoaded;
}

@end
