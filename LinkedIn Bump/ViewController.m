//
//  ViewController.m
//  LinkedIn Bump
//
//  Created by Michael Royzen on 7/25/17.
//  Copyright © 2017 Michael Royzen. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () {
    CMMotionManager *manager;
    NSString *username;
    __block NSString *myLinkID;
    __block NSString *myAzureID;
    __block NSString *myLocation;
    CLLocationManager *locationManager;
    CLLocation *latestLocation;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    locationManager = [[CLLocationManager alloc]init];
    [locationManager setDelegate:self];
    if (CLLocationManager.authorizationStatus != kCLAuthorizationStatusAuthorizedWhenInUse) {
        [locationManager requestWhenInUseAuthorization];
    }
    [locationManager setDesiredAccuracy:kCLLocationAccuracyBestForNavigation];
    [locationManager startUpdatingLocation];
    
    if ([LISDKSessionManager hasValidSession]) {
        //DUMMY CODE for username
        username = @"Michael";
        [self queryForID];
        //[self sendDataToAzure:myLinkID withLocation:locationManager.location];
        //myID variable is defined at this point
        //[self sendDataToAzure:myID withLocation:locationManager.location];
        
        
        manager = [[CMMotionManager alloc]init];
        if (manager.deviceMotionAvailable) {
            NSLog(@"Available");
            [manager setDeviceMotionUpdateInterval:0.01];
            __block int counter = 0;
            [manager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    //bump occurred
                    if (counter >= 0 ) {
                        if (motion.userAcceleration.x > .4 || motion.userAcceleration.z > .4) {
                            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Bump!"
                                                                                           message:@"You have just bumped"
                                                                                    preferredStyle:UIAlertControllerStyleAlert];
                            
                            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                                  handler:^(UIAlertAction * action) {}];
                            
                            [alert addAction:defaultAction];
                            [self presentViewController:alert animated:YES completion:nil];
                            [self findPersonToBump];
                        }
                        // fetch closest record
                    }
                    counter++;
                });
            }];
        }
    }
    else {
        //authenticate
        [LISDKSessionManager
         createSessionWithAuth:[NSArray arrayWithObjects:LISDK_BASIC_PROFILE_PERMISSION, nil]
         state:@"hackathon"
         showGoToAppStoreDialog:NO
         successBlock:^(NSString *returnState) {
             NSLog(@"%s","success called!");
             LISDKSession *session = [[LISDKSessionManager sharedInstance] session];
         }
         errorBlock:^(NSError *error) {
             NSLog(@"%s","error called!");
         }
         ];
    }
}

- (void)findPersonToBump {
    MSClient *client = [(AppDelegate *) [[UIApplication sharedApplication] delegate] client];
    MSTable *itemTable = [client tableWithName:@"Final"];
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"IsBumping == [c] Yes"];
    [itemTable readWithPredicate:predicate completion:^(MSQueryResult *result, NSError *error) {
        NSLog(@"Querying people to bump");
        if(error) {
            NSLog(@"ERROR %@", error);
        }
        else {
            double closestDistance = 500;
            int closestPersonIndex = 0;
            
            for (int i = 0; i < result.items.count; i++) {
                NSDictionary *item = result.items[i];
                double latitude = [[item objectForKey:@"Latitude"] doubleValue];
                double longitude = [[item objectForKey:@"Longitude"] doubleValue];
                CLLocation *loc = [[CLLocation alloc]initWithLatitude:latitude longitude:longitude];
                double newDistance = [latestLocation distanceFromLocation:loc];
                if (newDistance < closestDistance) {
                    closestDistance = newDistance;
                    closestPersonIndex = i;
                }
            }
            NSDictionary *closestPerson = result.items[closestPersonIndex];
            NSString *personID = [closestPerson objectForKey:@"Link_ID"];
            NSLog(@"Closest distance: %f", closestDistance);
            NSLog(@"Closest person: %@", personID);
             
        }
    }];
}

- (void)queryForID {
    //query for ID
    [[LISDKAPIHelper sharedInstance] getRequest:@"https://api.linkedin.com/v1/people/~?format=json"
                                        success:^(LISDKAPIResponse *response) {
                                            NSLog(@"Response: %@", response.data);
                                            NSData *data = [response.data dataUsingEncoding:NSUTF8StringEncoding];
                                            NSError *error;
                                            
                                            //    Note that JSONObjectWithData will return either an NSDictionary or an NSArray, depending whether your JSON string represents an a dictionary or an array.
                                            id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                                            myLinkID = [jsonObject objectForKey:@"id"];
                                            //NSString *predicateString = [NSString stringWithFormat:@"Link_ID == [c] %@", myLinkID];
                                            //NSLog(@"Predicate: %@", predicateString);
                                            
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                NSPredicate * predicate = [NSPredicate predicateWithFormat:@"Link_ID == [c] %@", myLinkID];
                                                MSClient *client = [(AppDelegate *) [[UIApplication sharedApplication] delegate] client];
                                                MSTable *itemTable = [client tableWithName:@"Final"];
                                                // Query the TodoItem table
                                                
                                                [itemTable readWithPredicate:predicate completion:^(MSQueryResult *result, NSError *error) {
                                                    NSLog(@"Querying...");
                                                    if(error) {
                                                        NSLog(@"ERROR %@", error);
                                                    }
                                                    else {
                                                        if (result.items.count == 0) {
                                                            NSLog(@"No ID found");
                                                            //upload ID to Azure
                                                            NSMutableDictionary *items = [[NSMutableDictionary alloc]init];
                                                            [items setValue:myLinkID forKey:@"Link_ID"];
                                                            [itemTable insert:items completion:^(NSDictionary *insertedItem, NSError *error) {
                                                                if (error) {
                                                                    NSLog(@"Error: %@", error);
                                                                } else {
                                                                    //NSLog(@"ID inserted, id: %@", [insertedItem objectForKey:@"id"]);
                                                                    myAzureID = [insertedItem objectForKey:@"id"];
                                                                    NSLog(@"Inserted Azure ID: %@", myAzureID);
                                                                    NSLog(@"Inserted Link ID: %@", [insertedItem objectForKey:@"Link_ID"]);
                                                                }
                                                            }];
                                                        }
                                                        else {
                                                            NSLog(@"LinkedIn ID found");
                                                            //Send data to Azure
                                                            NSDictionary *dic = result.items[0];
                                                            myAzureID = [dic objectForKey:@"id"];
                                                            NSLog(@"Azure ID: %@", myAzureID);
                                                        }
                                                        CLGeocoder *geocoder = [[CLGeocoder alloc]init];
                                                        [geocoder reverseGeocodeLocation:locationManager.location completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
                                                            CLPlacemark *placemark = [placemarks firstObject];
                                                            NSString *locationString = placemark.name;
                                                            [self sendDataToAzure:myLinkID withLocation:locationManager.location andName:locationString];
                                                        }];
                                                    }
                                                }];
                                            });
                                        } error:^(LISDKAPIError *error) {
                        }];
}

- (void)sendDataToAzure:(NSString *)linkedInID withLocation:(CLLocation *)location andName:(NSString *)name {
    NSLog(@"Sending data to Azure");
    MSClient *client = [(AppDelegate *) [[UIApplication sharedApplication] delegate] client];
    NSMutableDictionary *items = [[NSMutableDictionary alloc]init];
    double latitude = location.coordinate.latitude;
    double longitude = location.coordinate.longitude;
    [items setValue:[NSString stringWithFormat:@"%f", latitude] forKey:@"Latitude"];
    [items setValue:[NSString stringWithFormat:@"%f", longitude] forKey:@"Longitude"];
    //[items setValue:name forKey:@"City_Name"];
    
    MSTable *itemTable = [client tableWithName:@"Final"];
    
    //NSString *predicateString = [NSString stringWithFormat:@"Link_ID == %@", myLinkID];
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"Link_ID == [c] %@", myLinkID];
    [itemTable readWithPredicate:predicate completion:^(MSQueryResult *result, NSError *error) {
        NSLog(@"Querying ID...");
        if(error) {
            NSLog(@"ERROR %@", error);
        }
        else {
            //upload location data
            //NSLog(@"Uploading...");
            /*
            [itemTable deleteWithId:myAzureID completion:^(id itemId, NSError *error) {
                if(error) {
                    NSLog(@"ERROR %@", error);
                } else {
                    NSLog(@"Todo Item ID: %@", itemId);
                }
            }];
             */
            
            NSMutableDictionary *newItems = [[NSMutableDictionary alloc]init];
            [newItems setValue:[NSString stringWithFormat:@"%f", latitude] forKey:@"Latitude"];
            [newItems setValue:[NSString stringWithFormat:@"%f", longitude] forKey:@"Longitude"];
            [newItems setValue:myAzureID forKey:@"id"];
            [newItems setValue:name forKey:@"Loc_Name"];
            [newItems setValue:@"Yes" forKey:@"IsBumping"];
            [itemTable update:newItems completion:^(NSDictionary * _Nullable item, NSError * _Nullable error) {
                if (!error) {
                    NSLog(@"Location successfully updated");
                }
                else {
                    NSLog(@"Upload error: %@", [error localizedDescription]);
                }
            }];
             
        }
    }];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    CLGeocoder *geocoder = [[CLGeocoder alloc]init];
    [geocoder reverseGeocodeLocation:newLocation completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        CLPlacemark *placemark = [placemarks firstObject];
        NSString *locationString = placemark.name;
        [self sendDataToAzure:myLinkID withLocation:newLocation andName:locationString];
        myLocation = locationString;
    }];
    latestLocation = newLocation;
    [locationManager stopUpdatingLocation];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)addLinkedIn:(id)sender {
    
}

@end
