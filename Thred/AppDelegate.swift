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
    
    func handlePasswordlessSignIn(_ URL: URL) -> Bool{
        let url = URL.absoluteString
        guard let email = UserDefaults.standard.string(forKey: "EMAIL") else{return false}

        if Auth.auth().isSignIn(withEmailLink: url){
            if let user = Auth.auth().currentUser{
                let credential = EmailAuthProvider.credential(withEmail: email, link: url)
                if user.email != nil{
                    user.updateEmail(to: email, completion: {error in
                        if let err = error{
                            print(err.localizedDescription)
                            if err.localizedDescription == "This operation is sensitive and requires recent authentication. Log in again before retrying this request."{
                                self.window?.rootViewController?.logout(withMessage: err.localizedDescription)
                            }
                        }
                        else{
                            
                        }
                    })
                }
                else{
                    user.link(with: credential, completion: { result, error in
                        if let err = error{
                            print(err.localizedDescription)
                        }
                    })
                }
            }
            else{
                Auth.auth().signIn(withEmail: email, link: url, completion: { result, error in
                    if let err = error{
                        print(err.localizedDescription)
                    }
                    else{
                        guard let uid = result?.user.uid else{return}
                        guard let phoneNumber = result?.user.phoneNumber else{return}
                        guard let email = result?.user.email else{return}

                        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                        
                        UserDefaults.standard.set(phoneNumber, forKey: "PHONE_NUM")
                        UserDefaults.standard.set(email, forKey: "EMAIL")
                        UserDefaults.standard.set(uid, forKey: "UID")

                        if let signedInVC: UINavigationController = mainStoryboard.instantiateViewController(withIdentifier: "SignedInVC") as? UINavigationController{
                            signedInVC.loadUser(userUID: uid, completed: { success in
                                if success{
                                    self.beginSignIn()
                                }
                            })
                        }
                    }
                })
            }
        }
        return false
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        
        return userActivity.webpageURL.map(handlePasswordlessSignIn)!
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
    
    

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
      // If you are receiving a notification message while your app is in the background,
      // this callback will not be fired till the user taps on the notification launching the application.
      // TODO: Handle data of notification

      // With swizzling disabled you must let Messaging know about the message, for Analytics
      // Messaging.messaging().appDidReceiveMessage(userInfo)
      // Print message ID.
        if Auth.auth().currentUser != nil{
            if let payload = userInfo["aps"] as? [String : String]{
                print(payload)
            }
            let rootViewController = self.window!.rootViewController as? MainTabBarViewController
            rootViewController?.selectedIndex = 3
        }
        
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
        if let uid = userInfo.uid ?? UserDefaults.standard.string(forKey: "UID"){
            cache.clearDisk(onCompletion: {
                let ref = Firestore.firestore().collection("Users").document(uid)
                let oldToken = KeychainWrapper.standard.string(forKey: "NOTIF_ID") ?? ""
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
                do{
                    try Auth.auth().signOut()
                }catch{}
                
                ref.updateData(["notification_tokens" : FieldValue.arrayRemove([oldToken])], completion: { error in
                    if let err = error{
                        print(err.localizedDescription)
                        return
                    }
                    else{
                    }
                })
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

