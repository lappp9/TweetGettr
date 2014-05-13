
#import "TGViewController.h"
#import "TGAppDelegate.h"

#pragma mark - Private Categories

@implementation NSURLResponse (Utilities)
- (BOOL)httpRequestWasSuccessful;
{
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)self;
    return (response.statusCode >= 200 && response.statusCode <= 299);
}
@end

@implementation NSData (Utilities)
- (id)json;
{
    return [NSJSONSerialization JSONObjectWithData:self options:kNilOptions error:nil];
}
@end

@implementation NSString (Utilities)
- (NSData *)data;
{
    return [self dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)base64EncodedString;
{
    return [[self dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:kNilOptions];
}
@end

#pragma mark - Private Properties and Protocol Declarations

@interface TGViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *twitterNameTextField;
@property (weak, nonatomic) IBOutlet UIButton *gettrButton;
@property (weak, nonatomic) IBOutlet UITableView *tweetsTableView;
@property (nonatomic) NSArray *tweets;
@property (nonatomic) UIActivityIndicatorView *spinner;
@end

@implementation TGViewController

// You will need to supply your own API Key and Secret before this will work.
static NSString *const kAPIKey = @"";
static NSString *const kAPISecret = @"";
static NSString *const kOAuthRootURL = @"https://api.twitter.com/oauth2/token";


#pragma mark - UIViewController Stuffs

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.twitterNameTextField addTarget:self action:@selector(twitterNameTextFieldChanged)
                   forControlEvents:UIControlEventAllEditingEvents];
    self.gettrButton.enabled = NO;
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.twitterNameTextField.rightView = self.spinner;
    self.twitterNameTextField.rightViewMode = UITextFieldViewModeAlways;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.tweetsTableView deselectRowAtIndexPath:self.tweetsTableView.indexPathForSelectedRow animated:animated];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender;
{
    UIViewController *destinationViewController = segue.destinationViewController;
    UITextView *textView = (UITextView *)destinationViewController.view;
    NSDictionary *tweet = self.tweets[self.tweetsTableView.indexPathForSelectedRow.row];
    textView.text = tweet.description;
}

#pragma mark - User Interface Actions

- (void)twitterNameTextFieldChanged;
{
    self.gettrButton.enabled = self.twitterNameTextField.text.length;
}

- (IBAction)gettrWasTapped:(UIButton *)sender
{
    [self.twitterNameTextField resignFirstResponder];
    [self.spinner startAnimating];
    if (TGAppDelegate.shared.authorizationToken) {
        [self makeTwitterRequest];
    } else {
        [self fetchAuthorizationToken];
    }
}

#pragma mark - UITextFieldDelegate Methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField.text.length) {
        [self gettrWasTapped:nil];
    }
    return [textField resignFirstResponder];
}

#pragma mark - HTTP Requesting

- (void)fetchAuthorizationToken;
{
    NSURL *tokenURL = [NSURL URLWithString:kOAuthRootURL];
    NSMutableURLRequest *tokenRequest = [NSMutableURLRequest.alloc initWithURL:tokenURL];
    tokenRequest.HTTPMethod = @"POST";
    tokenRequest.HTTPBody = @"grant_type=client_credentials".data;
    
    [tokenRequest addValue:@"application/x-www-form-urlencoded;charset=UTF-8"
        forHTTPHeaderField:@"Content-Type"];
    NSString *authorizationToken = [NSString stringWithFormat:@"%@:%@", kAPIKey, kAPISecret].base64EncodedString;
    [tokenRequest addValue:[@"Basic " stringByAppendingString:authorizationToken]
        forHTTPHeaderField:@"Authorization"];
    
    [NSURLConnection sendAsynchronousRequest:tokenRequest queue:NSOperationQueue.mainQueue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (response.httpRequestWasSuccessful) {
            TGAppDelegate.shared.authorizationToken = data.json[@"access_token"];
            [self makeTwitterRequest];
        } else {
            [self showAlertViewWithMessage:[NSString stringWithFormat:@"Something went wrong getting token:\n\n%@", connectionError.localizedDescription]];
            TGAppDelegate.shared.authorizationToken = nil;
        }
        [self.spinner stopAnimating];
    }];
}

- (void)makeTwitterRequest;
{
    NSString *urlString = [@"https://api.twitter.com/1.1/statuses/user_timeline.json?count=30&screen_name=" stringByAppendingString:self.twitterNameTextField.text];
    NSURL *twitterURL = [NSURL URLWithString:urlString];
    NSMutableURLRequest *twitterRequest = [NSMutableURLRequest.alloc initWithURL:twitterURL];
    twitterRequest.HTTPMethod = @"GET";
    [twitterRequest addValue:[@"Bearer " stringByAppendingString:TGAppDelegate.shared.authorizationToken]
          forHTTPHeaderField:@"Authorization"];
    
    [NSURLConnection sendAsynchronousRequest:twitterRequest queue:NSOperationQueue.mainQueue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (response.httpRequestWasSuccessful) {
            self.tweets = data.json;
            [self.tweetsTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        } else {
            [self showAlertViewWithMessage:[NSString stringWithFormat:@"Something went wrong getting tweets:\n\n%@", connectionError.localizedDescription]];
        }
       [self.spinner stopAnimating];
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tweets.count;
}

#pragma mark - UITableViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"tweetCell"];

    NSDictionary *tweet = self.tweets[indexPath.row];
    cell.textLabel.text = tweet[@"text"];
    cell.detailTextLabel.text = tweet[@"created_at"];
    cell.backgroundColor = [UIColor colorWithWhite:(indexPath.row % 2) ? 0.95 : 0.975 alpha:1];
    return cell;
}

#pragma mark - Alert Showing

- (void)showAlertViewWithMessage:(NSString *)message;
{
    [[UIAlertView.alloc initWithTitle:@"Oops!" message:message delegate:nil
                    cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
}

@end
