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
import BRYXBanner
import FirebaseFirestore
import SwiftKeychainWrapper
import FirebaseMessaging
//
var isMerchant = false
var hasCard = false

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        
        if !UserDefaults.standard.bool(forKey: "Already_Opened"){
            UserDefaults.standard.set(true, forKey: "Already_Opened")
            if Auth.auth().currentUser != nil{
                do{
                    try Auth.auth().signOut()
                }catch{}
            }
        }
        
        if let uid = UserDefaults.standard.string(forKey: "UID"), UserDefaults.standard.string(forKey: "USERNAME") != nil{
            print(uid)
            userInfo.uid = uid
            beginSignIn()
            
        }
        return true
    }
    
    func beginSignIn(){
        self.registerNotifs(application: UIApplication.shared)
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        if let signedInVC: UINavigationController = mainStoryboard.instantiateViewController(withIdentifier: "SignedInVC") as? UINavigationController{
            signedInVC.loadUserInfo()
            self.window?.rootViewController = signedInVC
            self.window?.makeKeyAndVisible()
        }
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
    

    
    
    lazy var didTapBlock: () -> () = {
        let rootViewController = self.window!.rootViewController as? MainTabBarViewController
        rootViewController?.selectedIndex = 3
    }
    
    
   
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
                
        if let payload = notification.request.content.userInfo["aps"] as? [String : Any]{
            if let alert = payload["alert"] as? [String:Any]{
                if let message = alert["body"] as? String{
                    if let rootViewController = self.window!.rootViewController?.children.first as? MainTabBarViewController{
                        if rootViewController.selectedIndex != 3{
                            if let navVC = rootViewController.viewControllers?[3]{
                                navVC.tabBarItem.badgeColor = UIColor(named: "LoadingColor")
                                navVC.tabBarItem.badgeValue = " "
                                let banner = Banner(title: nil, subtitle: message, image: UIImage(named: "thred.logo"), backgroundColor: UIColor(named: "LoadingColor")!)
                                banner.dismissesOnTap = true
                                banner.didTapBlock = didTapBlock
                                banner.show(duration: 5.0)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func processNotif(type: String?, uid: String?, postID: String?, commentID: String?, commentMsg: String?, timestampString: String?){
        
        guard let uid = uid else{return}
        guard let type = type else{return}

        
        guard let timestamp = timestampString?.getDateFromString(timezone: TimeZone(abbreviation: "UTC")) else{return}

        switch type {
        case "Follow":
            print("")
            if let rootViewController = self.window!.rootViewController?.children.first as? MainTabBarViewController{
                let friendSB: UIStoryboard = UIStoryboard(name: "FriendVC", bundle: nil)
                if let friendVC: FriendVC = friendSB.instantiateViewController(withIdentifier: "FriendVC") as? FriendVC{
                    friendVC.friendInfo = UserInfo(uid: uid, dp: nil, dpID: nil, username: nil, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: [])
                    
                    if let vc = rootViewController.selectedViewController as? UINavigationController{
                        vc.pushViewController(friendVC, animated: true)
                    }
                }
            }
        case "Like":
            if let rootViewController = self.window!.rootViewController?.children.first as? MainTabBarViewController{
                guard let productID = postID else{return}
                let fullSB: UIStoryboard = UIStoryboard(name: "FullProductVC", bundle: nil)
                if let fullVC: FullProductVC = fullSB.instantiateViewController(withIdentifier: "FullVC") as? FullProductVC{
                    fullVC.fullProduct = Product(uid: userInfo.uid ?? "", picID: nil, description: nil, fullName: userInfo.fullName ?? "", username: userInfo.username ?? "", productID: productID, userImageID: userInfo.dpID ?? "", timestamp: nil, index: nil, timestampDiff: nil, blurred: nil, price: nil, name: nil, templateColor: nil, likes: nil, liked: nil, designImage: nil, comments: nil)
                    if let vc = rootViewController.selectedViewController as? UINavigationController{
                        vc.pushViewController(fullVC, animated: true)
                    }
                }
            }
        case "Purchase":
            print("")
        case "Comment":
            fallthrough
        case "Mention":
            if let rootViewController = self.window!.rootViewController?.children.first as? MainTabBarViewController{
                guard let productID = postID else{return}
                guard let commentID = commentID else{return}
                guard let commentMsg = commentMsg else{return}
                let fullSB: UIStoryboard = UIStoryboard(name: "FullProductVC", bundle: nil)
                if let fullVC: FullProductVC = fullSB.instantiateViewController(withIdentifier: "FullVC") as? FullProductVC{
                    fullVC.fullProduct = Product(uid: userInfo.uid ?? "", picID: nil, description: nil, fullName: userInfo.fullName ?? "", username: userInfo.username ?? "", productID: productID, userImageID: userInfo.dpID ?? "", timestamp: nil, index: nil, timestampDiff: nil, blurred: nil, price: nil, name: nil, templateColor: nil, likes: nil, liked: nil, designImage: nil, comments: nil)
                    fullVC.selectedComment = Comment(timestamp: timestamp, message: commentMsg, commentID: commentID, userInfo: UserInfo(uid: uid, dp: nil, dpID: nil, username: nil, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: []))
                    if let vc = rootViewController.selectedViewController as? UINavigationController{
                        vc.pushViewController(fullVC, animated: true)
                    }
                }
            }
        default:
            return
        }
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
      // If you are receiving a notification message while your app is in the background,
      // this callback will not be fired till the user taps on the notification launching the application.
      // TODO: Handle data of notification

      // With swizzling disabled you must let Messaging know about the message, for Analytics
      // Messaging.messaging().appDidReceiveMessage(userInfo)
      // Print message ID.
        

        
         if let payload = userInfo["aps"] as? [String : Any]{
            print(payload)
            
            if let alert = payload["alert"] as? [String:Any]{
                if let message = alert["body"] as? String{
                    print(message)
                }
            }
        }
        
        let uid = userInfo["UID"] as? String
        let type = userInfo["Type"] as? String
        let commentID = userInfo["CommentID"] as? String
        let postID = userInfo["PostID"] as? String
        let commentMsg = userInfo["CommentMessage"] as? String
        let timestampString = userInfo["Timestamp"] as? String
        
        processNotif(type: type, uid: uid, postID: postID, commentID: commentID, commentMsg: commentMsg, timestampString: timestampString)
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        
        InstanceID.instanceID().instanceID { (result, error) in
            if let error = error {
                print("Error fetching remote instance ID: \(error)")
            } else if let result = result {
                print("Remote instance ID token: \(result.token)")
                let oldToken = KeychainWrapper.standard.string(forKey: "NOTIF_ID") ?? ""
                let newToken = result.token
                guard let uid = userInfo.uid else{return}
                let ref = Firestore.firestore().collection("Users").document(uid)
                
                if oldToken.isEmpty{
                    self.addCurrentToken(newToken: newToken, ref: ref, completed: {
                        
                    })
                }
                else{
                    self.removeOldToken(oldToken: oldToken, ref: ref, completed: {
                        self.addCurrentToken(newToken: newToken, ref: ref, completed: {
                            
                        })
                    })
                }
            }
        }
    }
    
    func removeOldToken(oldToken: String, ref: DocumentReference, completed: @escaping () -> ()){
        ref.updateData(["notification_tokens" : FieldValue.arrayRemove([oldToken])], completion: { error in
            if error != nil{
                print(error?.localizedDescription ?? "")
            }
            else{
                completed()
            }
        })
    }
    
    func addCurrentToken(newToken: String, ref: DocumentReference, completed: @escaping () -> ()){
        KeychainWrapper.standard.set(newToken, forKey: "NOTIF_ID")
        ref.updateData(["notification_tokens" : FieldValue.arrayUnion([newToken])])
    }
    
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
      
    }
    
    
    
    
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        application.applicationIconBadgeNumber = 0
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    //func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        
    //}


}

extension UIApplication {
    class func topViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            let moreNavigationController = tab.moreNavigationController

            if let top = moreNavigationController.topViewController, top.view.window != nil {
                return topViewController(base: top)
            } else if let selected = tab.selectedViewController {
                return topViewController(base: selected)
            }
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
}


extension UIViewController{
    func checkAuthStatus(completed: @escaping () -> ()){
        Auth.auth().currentUser?.getIDTokenForcingRefresh(true) { (idToken, error) in
            if error != nil, error?.localizedDescription == "There is no user record corresponding to this identifier. The user may have been deleted."{
                self.logout(withMessage: "Your account has been deactivated")
            }
            completed()
        }
    }
    
    func logout(withMessage: String?){
        
        if let uid = Auth.auth().currentUser?.uid{
            let ref = Firestore.firestore().collection("Users").document(uid)
            let oldToken = KeychainWrapper.standard.string(forKey: "NOTIF_ID") ?? ""
            ref.updateData(["notification_tokens" : FieldValue.arrayRemove([oldToken])], completion: { error in
                if let err = error{
                    print(err.localizedDescription)
                }
                do{
                    try Auth.auth().signOut()
                    
                        cache.clearDisk(onCompletion: {
                            let domain = Bundle.main.bundleIdentifier!
                            UserDefaults.standard.removePersistentDomain(forName: domain)
                            UserDefaults.standard.set(true, forKey: "Already_Opened")
                            self.deleteAllCachedProducts()
                            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                            if let navVC: UINavigationController = mainStoryboard.instantiateViewController(withIdentifier: "LoginVC") as? UINavigationController{
                                if let loginVC = navVC.viewControllers.first as? FirstViewController{
                                    loginVC.textToSet = withMessage
                                }
                                window?.rootViewController = navVC
                                window?.makeKeyAndVisible()
                            }
                        })
                }catch{ print(error.localizedDescription) }
            })
        }
    }
    
    func deleteAllCachedProducts(){
        let types = ["FeedProducts", "Products"]
        for type in types{
            if let folderName = type.determineFolder(){
                try? FileManager.default.removeItem(at: folderName.appendingPathComponent("Products"))
            }
        }
    }
    func dismissPopAllViewViewControllers() {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.window?.rootViewController!.dismiss(animated: true, completion: nil)
            (appDelegate.window?.rootViewController as? UINavigationController)!.popToRootViewController(animated: true)
        }
    }
}

