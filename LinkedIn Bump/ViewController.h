//
//  ViewController.h
//  LinkedIn Bump
//
//  Created by Michael Royzen on 7/25/17.
//  Copyright © 2017 Michael Royzen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#import <linkedin-sdk/LISDK.h>
#import <MicrosoftAzureMobile/MicrosoftAzureMobile.h>
#import "AppDelegate.h"
#import <CoreLocation/CoreLocation.h>

@interface ViewController : UIViewController <CLLocationManagerDelegate>

- (IBAction)addLinkedIn:(id)sender;

@end

