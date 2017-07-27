//
//  AppDelegate.m
//  LinkedIn Bump
//
//  Created by Michael Royzen on 7/25/17.
//  Copyright © 2017 Michael Royzen. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.client = [MSClient
                   clientWithApplicationURLString:@"https://linkedin-bump-ios.azurewebsites.net"
                   ];
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    [[LISDKAPIHelper sharedInstance] getRequest:@"https://api.linkedin.com/v1/people/~?format=json"
                                        success:^(LISDKAPIResponse *response) {
                                            NSLog(@"Response: %@", response.data);
                                            NSData *data = [response.data dataUsingEncoding:NSUTF8StringEncoding];
                                            NSError *error;
                                            
                                            //    Note that JSONObjectWithData will return either an NSDictionary or an NSArray, depending whether your JSON string represents an a dictionary or an array.
                                            id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                                            __block NSString *myLinkID = [jsonObject objectForKey:@"id"];
                                            
                                            
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                NSPredicate * predicate = [NSPredicate predicateWithFormat:@"Link_ID == [c] %@", myLinkID];
                                                MSClient *client = [(AppDelegate *) [[UIApplication sharedApplication] delegate] client];
                                                MSTable *itemTable = [client tableWithName:@"Final"];
                                                // Query the TodoItem table
                                                
                                                [itemTable readWithPredicate:predicate completion:^(MSQueryResult *result, NSError *error) {
                                                    NSDictionary *dic = result.items[0];
                                                    NSMutableDictionary *newItems = [[NSMutableDictionary alloc]init];
                                                    [newItems setValue:@"No" forKey:@"IsBumping"];
                                                    [newItems setValue:[dic objectForKey:@"id"] forKey:@"id"];
                                                    [itemTable update:newItems completion:^(NSDictionary * _Nullable item, NSError * _Nullable error) {
                                                        if (!error) {
                                                            NSLog(@"Bumping successfully updated");
                                                        }
                                                        else {
                                                            NSLog(@"Upload error: %@", [error localizedDescription]);
                                                        }
                                                    }];
                                                }];
                                                
                                            });
                                        } error:^(LISDKAPIError *error) {
                                        }];
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options {
    if ([LISDKCallbackHandler shouldHandleUrl:url]) {
        return [LISDKCallbackHandler application:app openURL:url sourceApplication:options[UIApplicationLaunchOptionsSourceApplicationKey] annotation:options[UIApplicationLaunchOptionsAnnotationKey]];
    }
    return YES;
    
}


@end
