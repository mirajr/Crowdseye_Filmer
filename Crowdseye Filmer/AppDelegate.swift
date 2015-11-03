//
//  AppDelegate.swift
//  Crowdseye Filmer
//
//  Created by Patrick O'Grady on 10/29/15.
//  Copyright © 2015 crowdseye. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        Parse.setApplicationId("HSPKoZpqyPfrGkmQV5rQ18DIUtPT54Ds4PhiJJix",
            clientKey: "pDreMDJo9xe7e2heKrWDfH1xIE1WNmdKCMPg75Ex")
        do {
            PFUser.enableAutomaticUser();
            try PFUser.currentUser()?.save()
            
            var currentUser = PFUser.currentUser()!
            
            if(currentUser["name"] == nil || currentUser["name"] as! String == "") {
                currentUser["name"] = "Anonymous"
                currentUser["votedEvents"] = []
                try currentUser.save()
            }
        } catch {
            print("Sign up unsuccessful")
        }
        
        var credentialsProvider = AWSCognitoCredentialsProvider(regionType: AWSRegionType.USEast1, identityPoolId: "us-east-1:cdb87120-5f38-479d-955c-39cd27f27aac")
        
        let defaultServiceConfiguration = AWSServiceConfiguration(
            region: AWSRegionType.USWest1,
            credentialsProvider: credentialsProvider)
        
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = defaultServiceConfiguration
        
        var settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
        
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()

        
        return true
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        var currentInstallation = PFInstallation.currentInstallation()
        currentInstallation.setDeviceTokenFromData(deviceToken)
        currentInstallation["user"] = PFUser.currentUser()!
        currentInstallation["channels"] = ["filmer"]
        currentInstallation.saveInBackground()
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        PFPush.handlePush(userInfo)
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

