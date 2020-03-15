//
//  AppDelegate.swift
//  Thred
//
//  Created by Arta Koroushnia on 2019-12-25.
//  Copyright © 2019 Thred. All rights reserved.
//

import UIKit
import Firebase
import Stripe


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    var window: UIWindow?

    func loadUserInfo(){
        UserDefaults.standard.set("6QetMxilaaN9YdyEb3DoAPiTjlu1", forKey: "UID") //Arta
        
        UserDefaults.standard.removeObject(forKey: "NOTIF_ID")
        //UserDefaults.standard.set("tl1oOs1NXdeHsium7ZygweBc7YO2", forKey: "UID") //Arvin
        //UserDefaults.standard.set("te7lsnwiPUMyj85O4Q5Tkvuu3VH3", forKey: "UID") //Dad
        let uid = UserDefaults.standard.string(forKey: "UID")!
        userInfo.uid = uid

        let username = UserDefaults.standard.string(forKey: "USERNAME") ?? "null"
        userInfo.username = username
        let fullname = UserDefaults.standard.string(forKey: "FULLNAME") ?? "null"
        userInfo.fullName = fullname

        if let bio = UserDefaults.standard.string(forKey: "BIO"){
            userInfo.bio = bio
        }
        let dpID = UserDefaults.standard.string(forKey: "DP_ID") ?? "default"
        userInfo.dpID = dpID
        if let profilePic = cache.imageFromDiskCache(forKey: dpID){
            userInfo.dp = profilePic
        }

        if let notifID = UserDefaults.standard.string(forKey: "NOTIF_ID"){
            userInfo.notifID = notifID
        }
        if let userLiked = UserDefaults.standard.stringArray(forKey: "LikedPosts"){
            userInfo.userLiked = userLiked
        }
        if let userFollowing = UserDefaults.standard.stringArray(forKey: "FOLLOWING"){
            userInfo.userFollowing = userFollowing
        }
        if let likesToUpdate =         UserDefaults.standard.object(forKey: "likeQueue") as? [String : Bool]{
            likeQueue = likesToUpdate
        }
        if let uploadPosts =         UserDefaults.standard.stringArray(forKey: "UploadingPosts"){
            uploadingPosts = uploadPosts
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        loadUserInfo()
        //login()
        if userInfo.uid != String(){
            registerNotifs(application: application)
        }

        return true
        
    }
    
    func registerNotifs(application: UIApplication){
        if #available(iOS 10.0, *) {
          // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            Messaging.messaging().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {_, _ in })
        } else {
          let settings: UIUserNotificationSettings =
          UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
          application.registerUserNotificationSettings(settings)
        }

        application.registerForRemoteNotifications()
    }

    // MARK: UISceneSession Lifecycle
    
    func applicationWillResignActive(_ application: UIApplication) {
        
        
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        
    }
    
    func login(){
        Auth.auth().signIn(withEmail: "djkazi19@gmail.com", password: "123456", completion: { result, error in
            if error != nil{
                print(error?.localizedDescription ?? "")
            }
        })
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
    }
    
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        InstanceID.instanceID().instanceID { (result, error) in
            if let error = error {
                print("Error fetching remote instance ID: \(error)")
            } else if let result = result {
                print("Remote instance ID token: \(result.token)")
                let oldToken = UserDefaults.standard.string(forKey: "NOTIF_ID") ?? ""
                
                if oldToken != result.token || oldToken.isEmpty{
                    
                    let ref = Firestore.firestore().collection("Users").document(userInfo.uid)
                    ref.updateData(["notification_tokens" : FieldValue.arrayUnion([result.token])], completion: { error in
                        if error != nil{
                            print(error?.localizedDescription ?? "")
                        }
                        else{
                            UserDefaults.standard.set(result.token, forKey: "NOTIF_ID")
                            ref.updateData(["notification_tokens" : FieldValue.arrayRemove([oldToken])])
                        }
                    })
                }
            }
        }
    }
    
    
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        /*
        guard userInfo.uid.isEmpty else{return}
        
        breakNoLikes:
        if let userLiked = userInfo.userLiked, !userLiked.isEmpty{
            guard let likedData = json(from: userLiked) else{
                break breakNoLikes
            }

            likedData
            
        }
        
        if let userFollowing = userInfo.userFollowing, !userFollowing.isEmpty{
            
        }
        */
    }
    
    
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    //func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        
    //}


}

