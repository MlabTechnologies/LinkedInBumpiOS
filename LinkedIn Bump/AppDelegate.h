//
//  AppDelegate.h
//  LinkedIn Bump
//
//  Created by Michael Royzen on 7/25/17.
//  Copyright © 2017 Michael Royzen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <linkedin-sdk/LISDK.h>
#import <MicrosoftAzureMobile/MicrosoftAzureMobile.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) MSClient *client;
@property (strong, nonatomic) UIWindow *window;


@end

