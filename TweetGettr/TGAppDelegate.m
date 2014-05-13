
#import "TGAppDelegate.h"

@implementation TGAppDelegate

static NSString *const kAuthorizationTokenStorageKey = @"authorizationToken";

+ (instancetype)shared;
{
    return UIApplication.sharedApplication.delegate;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    return YES;
}

- (NSString *)authorizationToken;
{
    return [NSUserDefaults.standardUserDefaults valueForKey:kAuthorizationTokenStorageKey];
}

- (void)setAuthorizationToken:(NSString *)authorizationToken
{
    if (!authorizationToken) {
        [NSUserDefaults.standardUserDefaults removeObjectForKey:kAuthorizationTokenStorageKey];
    } else {
        [NSUserDefaults.standardUserDefaults setValue:authorizationToken forKey:kAuthorizationTokenStorageKey];
    }
    [NSUserDefaults.standardUserDefaults synchronize];
}

@end
