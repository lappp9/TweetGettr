
#import "TGViewController.h"
#import "TGAppDelegate.h"

#pragma mark - Private Categories

@implementation NSArray (Utilities)
- (NSString *)string;
{
    return [self componentsJoinedByString:@""];
}
@end

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

- (NSURL *)url;
{
    return [NSURL URLWithString:self];
}
@end

@implementation NSURL (Utilities)
- (NSMutableURLRequest *)mutableRequest;
{
    return [NSMutableURLRequest.alloc initWithURL:self];
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
static NSString *const kPostMethod = @"POST";
static NSString *const kGetMethod = @"GET";
static NSString *const kContentTypeHeader = @"Content-Type";
static NSString *const kAuthorizationHeader = @"Authorization";
static NSString *const kOAuthRootURL = @"https://api.twitter.com/oauth2/token";
static NSString *const kTimelineRootURL = @"https://api.twitter.com/1.1/statuses/user_timeline.json?count=30&screen_name=";
static NSString *const kAuthorizationBody = @"grant_type=client_credentials";
static NSString *const kAuthorizationContentType = @"application/x-www-form-urlencoded;charset=UTF-8";

#pragma mark - UIViewController Stuffs

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.spinner = [UIActivityIndicatorView.alloc initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
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

- (IBAction)twitterNameTextFieldChanged;
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
    NSMutableURLRequest *tokenRequest = kOAuthRootURL.url.mutableRequest;
    tokenRequest.HTTPMethod = kPostMethod;
    tokenRequest.HTTPBody = kAuthorizationBody.data;
    [tokenRequest addValue:kAuthorizationContentType forHTTPHeaderField:kContentTypeHeader];
    [tokenRequest addValue:self.authorizationString forHTTPHeaderField:kAuthorizationHeader];
    
    [NSURLConnection sendAsynchronousRequest:tokenRequest
                                       queue:NSOperationQueue.mainQueue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
    {
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
    NSMutableURLRequest *twitterRequest = @[kTimelineRootURL, self.twitterNameTextField.text].string.url.mutableRequest;
    twitterRequest.HTTPMethod = kGetMethod;
    [twitterRequest addValue:self.bearerString forHTTPHeaderField:kAuthorizationHeader];
    
    [NSURLConnection sendAsynchronousRequest:twitterRequest
                                       queue:NSOperationQueue.mainQueue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
    {
        if (response.httpRequestWasSuccessful) {
            self.tweets = data.json;
            [self.tweetsTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
            [self.tweetsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        } else {
            [self showAlertViewWithMessage:[NSString stringWithFormat:@"Something went wrong getting tweets:\n\n%@", connectionError.localizedDescription]];
        }
       [self.spinner stopAnimating];
    }];
}

- (NSString *)authorizationString;
{
    NSString *base64EncodedKeys = @[kAPIKey, @":", kAPISecret].string.base64EncodedString;
    return @[@"Basic ", base64EncodedKeys].string;
}

- (NSString *)bearerString;
{
    if (TGAppDelegate.shared.authorizationToken) {
        return @[@"Bearer ", TGAppDelegate.shared.authorizationToken].string;
    }
    return nil;
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
    return cell;
}

#pragma mark - Alert Showing

- (void)showAlertViewWithMessage:(NSString *)message;
{
    [[UIAlertView.alloc initWithTitle:@"Oops!" message:message delegate:nil
                    cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
}

@end
