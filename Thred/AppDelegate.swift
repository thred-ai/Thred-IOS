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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        
            
        DispatchQueue(label: "Info").async {
            if let stripeKey = Bundle.main.object(forInfoDictionaryKey: "StripeKeyLive") as? String{
                STPAPIClient.shared().publishableKey = stripeKey
            }
        }
                
        Messaging.messaging().delegate = self
        if Auth.auth().currentUser != nil{
            if !UserDefaults.standard.bool(forKey: "Already_Opened"){
                UserDefaults.standard.set(true, forKey: "Already_Opened")
                application.logout(withMessage: nil, segueToFirstScreen: true)
            }
            else{
                if let uid = UserDefaults.standard.string(forKey: "UID"), UserDefaults.standard.string(forKey: "USERNAME") != nil{
                    userInfo.uid = uid
                    beginSignIn()
                    guard checkInternetConnection() else{
                        return true
                    }
                }
            }
        }
        return true
    }

    /*
    func fixCounts(){
        Firestore.firestore().collection("Users").getDocuments(completion: { snaps, error in
            if let err = error{
                print(err.localizedDescription)
            }
            else{
                for doc in snaps?.documents ?? []{
                    var pCount = 0
                    var fCount = 0
                    var foCount = 0

                    doc.reference.collection("Products").getDocuments(completion: { pSnaps, error in
                        for _ in pSnaps?.documents ?? []{
                            pCount += 1
                        }
                        doc.reference.collection("Followers").getDocuments(completion: { pSnaps, error in
                            for _ in pSnaps?.documents ?? []{
                                foCount += 1
                            }
                            doc.reference.collection("Following").getDocuments(completion: { pSnaps, error in
                                for _ in pSnaps?.documents ?? []{
                                    fCount += 1
                                }
                                let data = [
                                    "Posts_Count" : pCount,
                                    "Following_Count" : fCount,
                                    "Followers_Count" : foCount
                                ]
                                doc.reference.updateData(data)
                            })
                        })
                    })
                }
            }
        })
    }
*/
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
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        let token = KeychainWrapper.standard.string(forKey: "NOTIF_ID") ?? ""
        uploadNotifTokens(oldToken: "", newToken: token)
    }

    // MARK: UISceneSession Lifecycle
    
    func applicationWillResignActive(_ application: UIApplication) {
        
        
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        
    }
    

    var notifInfo: [AnyHashable:Any]!
    
    func visibleViewController() -> UIViewController?{
        
        return UIApplication.topViewController()
    }
    
    
    lazy var didTapBlock: () -> () = {
        
        guard let userInfo = self.notifInfo else{return}
        let uid = userInfo["UID"] as? String
        let type = userInfo["Type"] as? String
        let commentID = userInfo["CommentID"] as? String
        let postID = userInfo["PostID"] as? String
        let commentMsg = userInfo["CommentMessage"] as? String
        let timestampString = userInfo["Timestamp"] as? String
        
        guard let visibleViewController = self.visibleViewController(), !(visibleViewController is DesignViewController || visibleViewController is CheckoutVC || visibleViewController is ShoppingCartVC) else{return}
        self.processNotif(type: type, uid: uid, postID: postID, commentID: commentID, commentMsg: commentMsg, timestampString: timestampString, rootViewController: visibleViewController)
    }
    
   
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
                
        guard let visibleViewController = visibleViewController(), !(visibleViewController is DesignViewController || visibleViewController is CheckoutVC || visibleViewController is ShoppingCartVC), Auth.auth().currentUser != nil else{return}
        notifInfo = notification.request.content.userInfo
        if let payload = notification.request.content.userInfo["aps"] as? [String : Any]{
            if let alert = payload["alert"] as? [String:Any]{
                if let message = alert["body"] as? String{
                    let banner = Banner(title: nil, subtitle: message, image: UIImage(named: "thred.logo"), backgroundColor: UIColor(named: "LoadingColor")!)
                    banner.alpha = 1.0
                    banner.dismissesOnTap = true
                    banner.didTapBlock = didTapBlock
                    banner.show(duration: 5.0)
                }
            }
        }
    }
    
    func processNotif(type: String?, uid: String?, postID: String?, commentID: String?, commentMsg: String?, timestampString: String?, rootViewController: UIViewController){
        
        guard let uid = uid else{return}
        guard let type = type else{return}
        var vcToPush: UIViewController!
        
        guard let timestamp = timestampString?.getDateFromString(timezone: TimeZone(abbreviation: "UTC")) else{return}
        
        if let tabVC = rootViewController.navigationController?.tabBarController as? MainTabBarViewController{
            if tabVC.selectedIndex != 3{
                if let navVC = tabVC.viewControllers?[3]{
                    navVC.tabBarItem.badgeColor = UIColor(named: "LoadingColor")
                    navVC.tabBarItem.badgeValue = " "
                }
            }
            else if let notifVC = (tabVC.selectedViewController as? UINavigationController)?.viewControllers.first as? NotificationVC{
                notifVC.downloadNotifs {
                    
                }
            }
        }
                
        switch type {
        case "Follow":
            let friendSB: UIStoryboard = UIStoryboard(name: "FriendVC", bundle: nil)
            if let friendVC: FriendVC = friendSB.instantiateViewController(withIdentifier: "FriendVC") as? FriendVC{
                friendVC.friendInfo = UserInfo(uid: uid, dp: nil, dpID: nil, username: nil, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: [], profileLink: nil, verified: nil)
                vcToPush = friendVC
            }
        case "Like":
            guard let productID = postID else{return}
            let fullSB: UIStoryboard = UIStoryboard(name: "FullProductVC", bundle: nil)
            if let fullVC: FullProductVC = fullSB.instantiateViewController(withIdentifier: "FullVC") as? FullProductVC{
                fullVC.fullProduct = Product(userInfo: userInfo, picID: nil, description: nil, productID: productID, timestamp: nil, index: nil, timestampDiff: nil, blurred: nil, price: nil, name: nil, templateColor: nil, likes: nil, liked: nil, designImage: nil, comments: nil, link: nil, isAvailable: true, isPublic: nil, productType: nil)
                vcToPush = fullVC
            }
        case "Buy":
            guard let productID = postID else{return}
            let fullSB: UIStoryboard = UIStoryboard(name: "FullProductVC", bundle: nil)
            if let fullVC: FullProductVC = fullSB.instantiateViewController(withIdentifier: "FullVC") as? FullProductVC{
                fullVC.fullProduct = Product(userInfo: userInfo, picID: nil, description: nil, productID: productID, timestamp: nil, index: nil, timestampDiff: nil, blurred: nil, price: nil, name: nil, templateColor: nil, likes: nil, liked: nil, designImage: nil, comments: nil, link: nil, isAvailable: true, isPublic: nil, productType: nil)
                vcToPush = fullVC
            }
        case "Bio_Mention":
            let friendSB: UIStoryboard = UIStoryboard(name: "FriendVC", bundle: nil)
            if let friendVC: FriendVC = friendSB.instantiateViewController(withIdentifier: "FriendVC") as? FriendVC{
                friendVC.friendInfo = UserInfo(uid: uid, dp: nil, dpID: nil, username: nil, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: [], profileLink: nil, verified: nil)
                vcToPush = friendVC
            }
        case "Post_Mention":
            guard let productID = postID else{return}
            let fullSB: UIStoryboard = UIStoryboard(name: "FullProductVC", bundle: nil)
            if let fullVC: FullProductVC = fullSB.instantiateViewController(withIdentifier: "FullVC") as? FullProductVC{
                fullVC.fullProduct = Product(userInfo: UserInfo(), picID: productID, description: nil, productID: productID, timestamp: nil, index: nil, timestampDiff: nil, blurred: nil, price: nil, name: nil, templateColor: nil, likes: nil, liked: nil, designImage: nil, comments: nil, link: nil, isAvailable: true, isPublic: nil, productType: nil)
                vcToPush = fullVC
            }
        case "Comment":
            fallthrough
        case "Mention":
            guard let productID = postID else{return}
            guard let commentID = commentID else{return}
            guard let commentMsg = commentMsg else{return}
            let fullSB: UIStoryboard = UIStoryboard(name: "FullProductVC", bundle: nil)
            if let fullVC: FullProductVC = fullSB.instantiateViewController(withIdentifier: "FullVC") as? FullProductVC{
                ///Fix uid for mention
                fullVC.fullProduct = Product(userInfo: UserInfo(), picID: productID, description: nil, productID: productID, timestamp: nil, index: nil, timestampDiff: nil, blurred: nil, price: nil, name: nil, templateColor: nil, likes: nil, liked: nil, designImage: nil, comments: nil, link: nil, isAvailable: true, isPublic: nil, productType: nil)
                fullVC.selectedComment = Comment(timestamp: timestamp, message: commentMsg, commentID: commentID, userInfo: UserInfo(uid: uid, dp: nil, dpID: nil, username: nil, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: [], profileLink: nil, verified: nil))
                vcToPush = fullVC
            }
        default:
            return
        }
        if let vcToPush = vcToPush{
            rootViewController.navigationController?.pushViewController(vcToPush, animated: true)
        }
    }
    
    
    
    func handleDynamicLink(isProduct: Bool, uid: String?, productID: String?, username: String?){
        
        guard Auth.auth().currentUser != nil else{return}
        guard let uid = uid else {return}
        var vcToPush: UIViewController!
        
        guard let visibleViewController = visibleViewController(), !(visibleViewController is DesignViewController || visibleViewController is CheckoutVC || visibleViewController is ShoppingCartVC) else{return}

        switch isProduct{
            
        case true:
            let fullSB: UIStoryboard = UIStoryboard(name: "FullProductVC", bundle: nil)
            if let fullVC: FullProductVC = fullSB.instantiateViewController(withIdentifier: "FullVC") as? FullProductVC{
                guard let productID = productID else{return}
                fullVC.fullProduct = Product(userInfo: UserInfo(uid: uid, dp: nil, dpID: nil, username: nil, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: [], profileLink: nil, verified: nil), picID: productID, description: nil, productID: productID, timestamp: nil, index: nil, timestampDiff: nil, blurred: nil, price: nil, name: nil, templateColor: nil, likes: nil, liked: nil, designImage: nil, comments: nil, link: nil, isAvailable: true, isPublic: nil, productType: nil)
                vcToPush = fullVC
            }
        default:
            if uid == userInfo.uid{
                if let tab = visibleViewController.tabBarController{
                    tab.selectedIndex = 4
                    if let userVC = (tab.selectedViewController as? UINavigationController)?.viewControllers.first as? UserVC{
                        userVC.navigationController?.popToViewController(userVC, animated: true)
                        return
                    }
                }
            }
            else{
                let friendSB: UIStoryboard = UIStoryboard(name: "FriendVC", bundle: nil)
                if let friendVC: FriendVC = friendSB.instantiateViewController(withIdentifier: "FriendVC") as? FriendVC{
                    friendVC.friendInfo = UserInfo(uid: uid, dp: nil, dpID: nil, username: username, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: [], profileLink: nil, verified: nil)
                    vcToPush = friendVC
                }
            }
        }
        
        if let vcToPush = vcToPush{
            visibleViewController.navigationController?.pushViewController(vcToPush, animated: true)
        }
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        
        let handled = DynamicLinks.dynamicLinks().handleUniversalLink(userActivity.webpageURL!) { (dynamiclink, error) in
            guard let link = dynamiclink?.url else{return}
            guard !link.lastPathComponent.isEmpty else{return}
            let parts = link.pathComponents
            if !parts.isEmpty{
                var productID: String!
                var uid: String!
                var username: String!
                if parts.count >= 5{
                    productID = parts[parts.count - 1]
                    uid = parts[parts.count - 3]
                }
                else{
                    username = parts[parts.count - 2]
                    uid = parts[parts.count - 1]
                }
                self.handleDynamicLink(isProduct: link.pathComponents.contains("product"), uid: uid, productID: productID, username: username)
            }
        }

        return handled
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let visibleViewController = self.visibleViewController(), !(visibleViewController is DesignViewController || visibleViewController is CheckoutVC || visibleViewController is ShoppingCartVC), Auth.auth().currentUser != nil else{return}
            self.processNotif(type: type, uid: uid, postID: postID, commentID: commentID, commentMsg: commentMsg, timestampString: timestampString, rootViewController: visibleViewController)
        }
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    func uploadNotifTokens(oldToken: String, newToken: String){
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
    
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        
        InstanceID.instanceID().instanceID { (result, error) in
            if let error = error {
                print("Error fetching remote instance ID: \(error)")
            } else if let result = result {
                print("Remote instance ID token: \(result.token)")
                let oldToken = KeychainWrapper.standard.string(forKey: "NOTIF_ID") ?? ""
                let newToken = result.token
                if Auth.auth().currentUser != nil{
                    self.uploadNotifTokens(oldToken: oldToken, newToken: newToken)
                }
                else{
                    KeychainWrapper.standard.set(newToken, forKey: "NOTIF_ID")
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
    
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        likeQueue.removeAll()
        
        DispatchQueue.global(qos: .background).sync {
            cache.clearMemory()
        }
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
    class func topViewController(base: UIViewController? = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController) -> UIViewController? {
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


extension UIApplication{
    func checkAuthStatus(completed: @escaping () -> ()){
        Auth.auth().currentUser?.getIDTokenForcingRefresh(true) { (idToken, error) in
            if error != nil, error?.localizedDescription == "There is no user record corresponding to this identifier. The user may have been deleted."{
                self.logout(withMessage: "Your account has been deactivated", segueToFirstScreen: true)
            }
            completed()
        }
    }
    
    func logout(withMessage: String?, segueToFirstScreen: Bool){
        
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
                            userInfo = UserInfo()
                            self.deleteAllCachedProducts()
                            uploadingComments.removeAll()
                            uploadingPosts.removeAll()
                            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                            if segueToFirstScreen{
                                if let navVC: UINavigationController = mainStoryboard.instantiateViewController(withIdentifier: "LoginVC") as? UINavigationController{
                                    if let loginVC = navVC.viewControllers.first as? FirstViewController{
                                        loginVC.textToSet = withMessage
                                    }
                                    window?.rootViewController = navVC
                                    window?.makeKeyAndVisible()
                                }
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

extension UIViewController{
    func checkAuthStatus(completed: @escaping () -> ()){
        UIApplication.shared.checkAuthStatus {
            completed()
        }
    }
}
