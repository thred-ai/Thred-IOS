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
import FirebaseAuth
import FirebaseStorage
import SDWebImage
import GoogleSignIn
//



var currentTheme: AppTheme? = KeychainWrapper.standard.object(forKey: "current_theme") as? AppTheme

class AppTheme: NSCoding{
    
    func encode(with coder: NSCoder) {
        
    }
    
    required init?(coder: NSCoder) {
        
    }
    
    
    var name: String!
    var primaryColor: AppColor?
    var secondaryColor: AppColor?
    var tertiaryColor: AppColor?
    
    init(name: String!, primaryColor: AppColor!, secondaryColor: AppColor!, tertiaryColor: AppColor!) {
        self.name = name
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.tertiaryColor = tertiaryColor
    }
    
}

class AppColor: NSCoding{
    
    var r: CGFloat!
    var g: CGFloat!
    var b: CGFloat!
    var a: CGFloat!
    
    func encode(with coder: NSCoder) {
        
    }
    
    required init?(coder: NSCoder) {
        
    }
    
    init(r: Double!, g: Double!, b: Double!, a: Double!) {
        self.r = CGFloat(r)
        self.g = CGFloat(g)
        self.b = CGFloat(b)
        self.a = CGFloat(a)
    }
}

extension UIApplication{
    func getColors(){
        let visibleVC = (UIApplication.shared.delegate as? AppDelegate)?.visibleViewController()
        
        Firestore.firestore().collection("Themes").whereField("Active", isEqualTo: true).limit(to: 2).getDocuments(completion: { snaps, error in
            if let err = error{
                print(err.localizedDescription)
            }
            else{
                
                guard let doc = snaps?.documents.first,
                      
                let primary = doc["PrimaryColor"] as? [Double],
                let secondary = doc["SecondaryColor"] as? [Double],
                let tertiary = doc["TertiaryColor"] as? [Double],
                let name = doc["Name"] as? String

                else{return}
                
                let primaryColor = AppColor(r: primary[0], g: primary[1], b: primary[2], a: 1.0)
                    
                let secondaryColor = AppColor(r: secondary[0], g: secondary[1], b: secondary[2], a: 1.0)
                
                let tertiaryColor = AppColor(r: tertiary[0], g: tertiary[1], b: tertiary[2], a: 1.0)
                
                currentTheme = AppTheme(name: name, primaryColor: primaryColor, secondaryColor: secondaryColor, tertiaryColor: tertiaryColor)
                
                KeychainWrapper.standard.set(currentTheme!, forKey: "current_theme")
                
                visibleVC?.updateColors()
            }
        })
    }
}

extension UIViewController{
    func updateColors(){
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate, GIDSignInDelegate {
    
   
    

    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
    }
    
    var window: UIWindow?
    
    
    func adjust(data: [String : Any]){
        Functions.functions().httpsCallable("adjustPostMinimums").call(data, completion: { result, error in
            if let err = error{
                print(err.localizedDescription)
            }
            else{
                
            }
        })
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance().handle(url)
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
                    
        DispatchQueue(label: "Info").async {
            if let stripeKey = Bundle.main.object(forInfoDictionaryKey: "StripeKeyLive") as? String{
                
                STPAPIClient.shared.publishableKey = stripeKey
            }
        }
        Messaging.messaging().delegate = self
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        
        if Auth.auth().currentUser != nil{
            if !UserDefaults.standard.bool(forKey: "Already_Opened"){
                UserDefaults.standard.set(true, forKey: "Already_Opened")
                application.logout(withMessage: nil, segueToFirstScreen: true)
            }
            else{
                if let uid = UserDefaults.standard.string(forKey: "UID"), UserDefaults.standard.string(forKey: "USERNAME") != nil{
                    pUserInfo.uid = uid
                    beginSignIn()
                    guard checkInternetConnection() else{
                        return true
                    }
                }
            }
        }
        return true
    }
    
    func testShipping(){
        Functions.functions().httpsCallable("createShipping").call(completion: { result, error in
            
        })
    }
    
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
                        for doc in pSnaps?.documents ?? []{
                            if doc["Available"] as? Bool ?? false{
                                pCount += 1
                            }
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
        var picID = userInfo["CommentPicID"] as? String
        let chatID = userInfo["chatID"] as? String

        if picID?.isEmpty ?? false{
            picID = nil
        }
        
        guard let visibleViewController = self.visibleViewController(), !(visibleViewController is DesignViewController || visibleViewController is CheckoutVC || visibleViewController is ShoppingCartVC) else{return}
        self.processNotif(type: type, uid: uid, postID: postID, commentID: commentID, commentMsg: commentMsg, timestampString: timestampString, commentPicID: picID, chatID: chatID, rootViewController: visibleViewController)
    }
    
    
   
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
                
        guard let visibleViewController = visibleViewController(), !(visibleViewController is DesignViewController || visibleViewController is CheckoutVC || visibleViewController is ShoppingCartVC), Auth.auth().currentUser != nil else{return}
        let type = notification.request.content.userInfo["Type"] as? String
        let chatID = notification.request.content.userInfo["chatID"] as? String
                
        if type == "Text"{
            UIApplication.shared.applicationIconBadgeNumber = 1
        }
        checkNotifInfo(force: true)

        guard !(visibleViewController is AllChatsVC && type == "Text") else{return}
        
        if let vc = visibleViewController as? ChatVC, vc.chatInfo.chatID == chatID{
            return
        }
        
        notifInfo = notification.request.content.userInfo
        
        
        
        if let options = notification.request.content.userInfo["fcm_options"] as? [String : Any]{
            
            if let imgURL = options["image"] as? String{
                
                self.getImg(urlString: imgURL){ image in
                    self.displayLocalNotification(notification: notification, image: image, isProfilePic: false)
                }
            }
        }
        else{
            
            let uid = notification.request.content.userInfo["UID"] as? String

            visibleViewController.downloadUserInfo(uid: uid, userVC: nil, feedVC: nil, downloadingPersonalDP: false, doNotDownloadDP: false, userInfoToUse: nil, queryOnUsername: false, completed: { uid, fullName, username, dpUID, notifID, bio, imgData, userFollowing, usersBlocking, postNotifs, postCount, followersCount, followingCount, verified in
                
                if let data = imgData, let image = UIImage(data: data){
                    let img = image.sd_roundedCornerImage(withRadius: 20 / 2, corners: [.allCorners], borderWidth: 20 / 17.75, borderColor: UIColor(named: "ProfileMask"))
                    self.displayLocalNotification(notification: notification, image: img, isProfilePic: true)
                }
            })
        }
    }
    
    func displayLocalNotification(notification: UNNotification, image: UIImage?, isProfilePic: Bool){
        guard !(visibleViewController() is UsernameSetupVC) else{return}
        if let payload = notification.request.content.userInfo["aps"] as? [String : Any]{
            if let alert = payload["alert"] as? [String:Any]{
                if let message = alert["body"] as? String{
                    let title = alert["title"] as? String

                    let banner = Banner(title: title, subtitle: message, image: image, backgroundColor: UIColor.secondarySystemBackground)
                    banner.alpha = 1.0
                    banner.detailLabel.textColor = .label
                    banner.titleLabel.textColor = .label
                    banner.dismissesOnTap = true
                    banner.didTapBlock = self.didTapBlock
                    banner.show(duration: 5.0)
                }
            }
        }
    }
    
    
    func getImg(urlString: String, completed: @escaping (UIImage?) -> ()){

        guard let url = URL(string: urlString)
        else{
            completed(nil)
            return
        }
        let options = SDWebImageOptions(arrayLiteral: [.scaleDownLargeImages, .continueInBackground])

        downloader.requestImage(with: url, options: options, context: nil, progress: nil, completed: { (image, data, error, finished) in
            if finished{
                if error != nil{
                    print(error?.localizedDescription ?? "")
                    completed(nil)
                    return
                }
                else{
                    completed(image)
                }
            }
        })
    }
    
    func processNotif(type: String?, uid: String?, postID: String?, commentID: String?, commentMsg: String?, timestampString: String?, commentPicID: String?, chatID: String?, rootViewController: UIViewController){
        
        guard let uid = uid else{return}
        guard let type = type else{return}
        var vcToPush: UIViewController!
        
        guard let timestamp = timestampString?.getDateFromString(timezone: TimeZone(abbreviation: "UTC")) else{return}
        
        switch type {
        case "Follow":
            let friendSB: UIStoryboard = UIStoryboard(name: "FriendVC", bundle: nil)
            if let friendVC: FriendVC = friendSB.instantiateViewController(withIdentifier: "FriendVC") as? FriendVC{
                friendVC.friendInfo = UserInfo(uid: uid, dp: nil, dpID: nil, username: nil, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: [], profileLink: nil, verified: nil)
                vcToPush = friendVC
            }
        case "Text":
            let chatSB: UIStoryboard = UIStoryboard(name: "ChatVC", bundle: nil)
            if let chatVC: ChatVC = chatSB.instantiateViewController(withIdentifier: "ChatVC") as? ChatVC{
                chatVC.chatInfo = GroupChat(uids: [], chatID: chatID ?? "", userImageIDs: [], timestamp: timestamp, isActive: true, index: nil, activeTime: timestamp, activeTimeDiff: nil, timestampDiff: nil, lastText: nil, chatName: nil, displayUserInfo: nil, didMute: false)
            vcToPush = chatVC
        }
        case "Like":
            guard let productID = postID else{return}
            let fullSB: UIStoryboard = UIStoryboard(name: "FullProductVC", bundle: nil)
            if let fullVC: FullProductVC = fullSB.instantiateViewController(withIdentifier: "FullVC") as? FullProductVC{
                fullVC.fullProduct = Product(userInfo: pUserInfo, picID: nil, description: nil, productID: productID, timestamp: nil, index: nil, timestampDiff: nil, blurred: nil, price: nil, name: nil, templateColor: nil, likes: nil, liked: nil, designImage: nil, comments: nil, link: nil, isAvailable: true, isPublic: nil, productType: nil, displaySide: nil, supportedSides: [])
                vcToPush = fullVC
            }
        case "Buy":
            guard let productID = postID else{return}
            let fullSB: UIStoryboard = UIStoryboard(name: "FullProductVC", bundle: nil)
            if let fullVC: FullProductVC = fullSB.instantiateViewController(withIdentifier: "FullVC") as? FullProductVC{
                fullVC.fullProduct = Product(userInfo: pUserInfo, picID: nil, description: nil, productID: productID, timestamp: nil, index: nil, timestampDiff: nil, blurred: nil, price: nil, name: nil, templateColor: nil, likes: nil, liked: nil, designImage: nil, comments: nil, link: nil, isAvailable: true, isPublic: nil, productType: nil, displaySide: nil, supportedSides: [])
                vcToPush = fullVC
            }
        case "Post_Notif":
            guard let productID = postID else{return}
            let fullSB: UIStoryboard = UIStoryboard(name: "FullProductVC", bundle: nil)
            if let fullVC: FullProductVC = fullSB.instantiateViewController(withIdentifier: "FullVC") as? FullProductVC{
                fullVC.fullProduct = Product(userInfo: pUserInfo, picID: nil, description: nil, productID: productID, timestamp: nil, index: nil, timestampDiff: nil, blurred: nil, price: nil, name: nil, templateColor: nil, likes: nil, liked: nil, designImage: nil, comments: nil, link: nil, isAvailable: true, isPublic: nil, productType: nil, displaySide: nil, supportedSides: [])
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
                fullVC.fullProduct = Product(userInfo: UserInfo(), picID: productID, description: nil, productID: productID, timestamp: nil, index: nil, timestampDiff: nil, blurred: nil, price: nil, name: nil, templateColor: nil, likes: nil, liked: nil, designImage: nil, comments: nil, link: nil, isAvailable: true, isPublic: nil, productType: nil, displaySide: nil, supportedSides: [])
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
                fullVC.fullProduct = Product(userInfo: UserInfo(), picID: productID, description: nil, productID: productID, timestamp: nil, index: nil, timestampDiff: nil, blurred: nil, price: nil, name: nil, templateColor: nil, likes: nil, liked: nil, designImage: nil, comments: nil, link: nil, isAvailable: true, isPublic: nil, productType: nil, displaySide: nil, supportedSides: [])
                fullVC.selectedComment = Comment(timestamp: timestamp, message: commentMsg, commentID: commentID, userInfo: UserInfo(uid: uid, dp: nil, dpID: nil, username: nil, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: [], profileLink: nil, verified: nil), picID: commentPicID, productID: postID)
                vcToPush = fullVC
            }
        default:
            return
        }
        if let vcToPush = vcToPush{
            if let vc = rootViewController as? ChatVC, vc.chatInfo.chatID == chatID{
                return
            }
            if all.tees.isEmpty{
                vcToPush.loadDesigns {
                    
                    rootViewController.navigationController?.pushViewController(vcToPush, animated: true)
                }
            }
            else{
                rootViewController.navigationController?.pushViewController(vcToPush, animated: true)
            }
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
                fullVC.fullProduct = Product(userInfo: UserInfo(uid: uid, dp: nil, dpID: nil, username: nil, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: [], profileLink: nil, verified: nil), picID: productID, description: nil, productID: productID, timestamp: nil, index: nil, timestampDiff: nil, blurred: nil, price: nil, name: nil, templateColor: nil, likes: nil, liked: nil, designImage: nil, comments: nil, link: nil, isAvailable: true, isPublic: nil, productType: nil, displaySide: nil, supportedSides: [])
                vcToPush = fullVC
            }
        default:
            if uid == pUserInfo.uid{
                if let tab = visibleViewController.tabBarController{
                    if all.tees.isEmpty{
                        tab.loadDesigns {
                            tab.selectedIndex = 4
                            if let userVC = (tab.selectedViewController as? UINavigationController)?.viewControllers.first as? UserVC{
                                userVC.navigationController?.popToViewController(userVC, animated: true)
                                return
                            }
                        }
                    }
                    else{
                        tab.loadDesigns {
                            tab.selectedIndex = 4
                            if let userVC = (tab.selectedViewController as? UINavigationController)?.viewControllers.first as? UserVC{
                                userVC.navigationController?.popToViewController(userVC, animated: true)
                                return
                            }
                        }
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
            if all.tees.isEmpty{
                vcToPush.loadDesigns {
                    visibleViewController.navigationController?.pushViewController(vcToPush, animated: true)
                }
            }
            else{
                visibleViewController.navigationController?.pushViewController(vcToPush, animated: true)
            }
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
        var picID = userInfo["CommentPicID"] as? String
        let chatID = userInfo["chatID"] as? String

        if picID?.isEmpty ?? false{
            picID = nil
        }


        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let visibleViewController = self.visibleViewController(), !(visibleViewController is DesignViewController || visibleViewController is CheckoutVC || visibleViewController is ShoppingCartVC), Auth.auth().currentUser != nil else{return}
            self.processNotif(type: type, uid: uid, postID: postID, commentID: commentID, commentMsg: commentMsg, timestampString: timestampString, commentPicID: picID, chatID: chatID, rootViewController: visibleViewController)
        }
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    func uploadNotifTokens(oldToken: String, newToken: String){
        guard let uid = pUserInfo.uid else{return}
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
    
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        
        messaging.token(completion: { token, error in
            if let error = error {
                print("Error fetching remote instance ID: \(error)")
            } else if let newToken = token{
                print("Remote instance ID token: \(newToken)")
                let oldToken = KeychainWrapper.standard.string(forKey: "NOTIF_ID") ?? ""
                
                if Auth.auth().currentUser != nil{
                    self.uploadNotifTokens(oldToken: oldToken, newToken: newToken)
                }
                else{
                    KeychainWrapper.standard.set(newToken, forKey: "NOTIF_ID")
                }
            }
        })
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
    
    func checkNotifInfo(force: Bool, application: UIApplication = UIApplication.shared){
        if let tabVC = visibleViewController()?.navigationController?.tabBarController as? MainTabBarViewController{
            if tabVC.selectedIndex != 3{
                if let navVC = tabVC.viewControllers?[3]{
                    if application.applicationIconBadgeNumber > 0{
                        navVC.tabBarItem.badgeColor = UIColor.red.withAlphaComponent(0.75)
                        navVC.tabBarItem.badgeValue = " "
                    }
                    else{
                        getCurrentNotifs(onlyText: false, completed: { notifs in
                            if notifs.isEmpty, !force{
                                navVC.tabBarItem.badgeColor = nil
                                navVC.tabBarItem.badgeValue = nil
                            }
                            else{
                                var color = UIColor(named: "LoadingColor")
                                if let newColor = navVC.tabBarItem.badgeColor{
                                    color = newColor
                                }
                                navVC.tabBarItem.badgeColor = color?.withAlphaComponent(0.75)
                                navVC.tabBarItem.badgeValue = " "
                                
                                let ids = notifs.filter({$0.request.content.userInfo["Type"] as? String != "Text"}).compactMap({$0.request.identifier})
                                
                                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ids)
                            }
                        })
                    }
                }
            }
            else if let notifVC = (tabVC.selectedViewController as? UINavigationController)?.viewControllers.first as? NotificationVC{
                if application.applicationIconBadgeNumber > 0{
                    notifVC.navigationController?.tabBarItem.badgeColor = UIColor.red.withAlphaComponent(0.75)
                    notifVC.navigationController?.tabBarItem.badgeValue = " "
                }
                else{
                    getCurrentNotifs(onlyText: false, completed: { notifs in
                        if notifs.isEmpty, !force{
                            notifVC.navigationController?.tabBarItem.badgeColor = nil
                            notifVC.navigationController?.tabBarItem.badgeValue = nil
                        }
                        else{
                            var color = UIColor(named: "LoadingColor")
                            if let newColor = notifVC.navigationController?.tabBarItem.badgeColor{
                                color = newColor
                            }
                            notifVC.navigationController?.tabBarItem.badgeColor = color?.withAlphaComponent(0.75)
                            notifVC.navigationController?.tabBarItem.badgeValue = " "
                            
                            let ids = notifs.filter({$0.request.content.userInfo["Type"] as? String != "Text"}).compactMap({$0.request.identifier})
                            
                            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ids)
                            
                            notifVC.downloadNotifs {
                                
                            }
                        }
                    })
                }
                notifVC.checkBadge()
            }
        }
    }
    
    /*
    func getOrders(){
        Firestore.firestore().collectionGroup("Orders").getDocuments(completion: { docs, error in
            if let err = error{
                print(err.localizedDescription)
            }
            else{
                var total = 0
                
                for doc in docs?.documents ?? []{
                    let status = doc["status"] as? String
                    
                    if status != "cancelled" && status != "cancelled-print"{
                        total += 12
                    }
                    if doc == docs?.documents.last{
                        print("TOTAL: \(total)")
                    }
                }
            }
        })
    }
 */
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
                
        checkNotifInfo(force: false)
        
        (visibleViewController()?.tabBarController as? MainTabBarViewController)?.checktoHideBubble()
        
    }
    
    
    
    func getCurrentNotifs(onlyText: Bool, completed: @escaping ([UNNotification]) -> ()){
        UNUserNotificationCenter.current().getDeliveredNotifications(completionHandler: { notifs in
            DispatchQueue.main.async {
                if onlyText{
                    completed(notifs.filter({$0.request.content.userInfo["Type"] as? String == "Text"}))
                }
                completed(notifs)
            }
        })
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
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            UIApplication.shared.applicationIconBadgeNumber = 0
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
                            pUserInfo = UserInfo()
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
        let types = ["FeedProducts", "Products", "UploadProducts"]
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

extension AppDelegate{
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
        
        //handle sign-in errors
        if let error = error {
            if (error as NSError).code == GIDSignInErrorCode.hasNoAuthInKeychain.rawValue {
                print("The user has not signed in before or they have since signed out.")
            } else {
            print("error signing into Google \(error.localizedDescription)")
            }
        return
        }
        
        // Get credential object using Google ID token and Google access token
        guard let authentication = user.authentication else { return }
        
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                        accessToken: authentication.accessToken)
        // Authenticate with Firebase using the credential object
        Auth.auth().signIn(with: credential) { (authResult, error) in
            if let error = error {
                print("authentication error \(error.localizedDescription)")
            }
            if let result = authResult{
                self.checkToSignIn(result: result)
            }
        }
    }
    
    func checkForName(result: AuthDataResult, fullname: String?, completed: @escaping () -> ()){
        if let name = fullname{
            let changes = result.user.createProfileChangeRequest()
            changes.displayName = name
            changes.commitChanges(completion: { error in
                completed()
            })
        }
        else{
            completed()
        }
    }
    
    func checkToSignIn(result: AuthDataResult, fullName: String? = nil){
        
        let spinner = (self.visibleViewController() as? FirstViewController)?.spinner

        spinner?.isHidden = false
        spinner?.animate()
        print(result.user.providerData.first?.email ?? "")
        
        UserDefaults.standard.set(result.user.uid, forKey: "UID")
        
        checkForName(result: result, fullname: fullName){
            if result.additionalUserInfo?.isNewUser ?? false{
                DispatchQueue.main.async {
                    (self.visibleViewController() as? FirstViewController)?.performSegue(withIdentifier: "toAccountSetup", sender: nil)
                }
            }
            else{
                DispatchQueue.main.async {
                    (self.visibleViewController() as? FirstViewController)?.downloadInfoOnSignIn(sender: nil)
                }
            }
        }
    }
}
