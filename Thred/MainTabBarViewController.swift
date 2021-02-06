//
//  MainTabBarViewController.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-01-13.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import AudioToolbox
import ColorCompatibility
import Firebase
import FirebaseFirestore


class MainTabBarViewController: UITabBarController, UITabBarControllerDelegate {

    var posted: Bool!
    var deletingPost: Bool!
    var product: ProductInProgress!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        tabBar.isTranslucent = false
        
        selectedIndex = 1
       // if let userVC = viewControllers?.last as? UserVC{
            //userVC.setPageInfo()
       // }
        
        // Do any additional setup after loading the view.
    }
    
    func checktoHideBubble(){
        speechBubble.isHidden = !(selectedIndex == 4 && pUserInfo.postCount == 0)
        
        DispatchQueue.main.async {
            if !self.speechBubble.isHidden{
                UIView.animate(withDuration: 0.8, delay: 0, options: [.autoreverse, .repeat], animations: {
                    self.speechBubble.transform = CGAffineTransform(translationX: 0, y: -5)
                }, completion: nil)
            }
        }
    }
        
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        

        checktoHideBubble()
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        
        if viewControllers?.firstIndex(of: viewController) == 2{
            return false
        }

        if let vc = (viewController as? UINavigationController)?.viewControllers.first{
            if selectedViewController == viewController{

                var y: CGFloat = 0
                if vc is UITableViewController || vc is UICollectionViewController{
                    y = -(vc.view.safeAreaInsets.top)
                }
                (vc as? UITableViewController)?.tableView?.setContentOffset(CGPoint(x: 0, y: y), animated: true)
                (vc as? NotificationVC)?.tableView?.setContentOffset(CGPoint(x: 0, y: y), animated: true)
                (vc as? ExploreViewController)?.tableView?.setContentOffset(CGPoint(x: 0, y: y), animated: true)
                (vc as? UserVC)?.collectionView?.setContentOffset(CGPoint(x: 0, y: y), animated: true)
            }
        }
        return true
    }
    
    @IBAction func unwindToTabBar(segue:  UIStoryboardSegue) {
        
        if posted ?? false{
            selectedIndex = 4
            posted = false
            if let profileVC = (viewControllers?[selectedIndex] as? UINavigationController)?.viewControllers.first as? UserVC{
                profileVC.uploadPost(post: product, isRetryingWithID: nil)
            }
        }
        else{
            if product != nil{
                if let vc = (selectedViewController as? UINavigationController)?.viewControllers.last{
                    vc.checkAuthStatus {
                        if let tableView = (vc as? UITableViewController)?.tableView ?? (vc as? FullProductVC)?.tableView{
                            if self.deletingPost{
                                tableView.deletingPost(post: self.product, vc: vc){
                                    self.product = nil
                                }
                            }
                            else{
                                tableView.updatePost(post: self.product, vc: vc){
                                    self.product = nil
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    
    
    let notificationCenter = NotificationCenter.default

    var spinner: MapSpinnerView!
    
    lazy var button: UIButton = {
        let tabHeight = tabBar.frame.size.height
        let width = (view.frame.width / 3) - 65
        let height = width
        let x = (view.frame.width / 3) + 32.5
        let y = view.frame.maxY - tabHeight - (height / 3)
        
        let button = UIButton.init(type: .custom)
        button.frame = CGRect(x: x, y: y, width: width, height: height)
        button.backgroundColor = .systemBackground
            //UIColor.init(red: 0.976, green: 0.976, blue: 0.976, alpha: 1.0)
        button.tintColor = .label
        button.imageView?.contentMode = .scaleAspectFill
        button.layer.borderColor = UIColor(named: "LoadingColor")?.cgColor 
        button.layer.borderWidth = 6.5
        button.layer.cornerRadius = button.frame.height / 2
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(segueToCreationScreen(_:)), for: .touchUpInside)
        print(view.frame.width)
        let ratio = CGFloat(20.0/375.0)
        
        let size = self.view.frame.width * ratio
        print(size)
        let img = UIImage(nameOrSystemName: "paintbrush.fill", systemPointSize: size, iconSize: 9)!
        button.setImage(img, for: .normal)
        button.setRadiusWithShadow()
        
        spinner = MapSpinnerView(frame: CGRect(x: button.frame.minX - 3, y: button.frame.minY - 3, width: button.frame.width + 6, height: button.frame.height + 6))
        view.addSubview(spinner)
        spinner.isHidden = true
        
        
        return button
    }()
    
    @objc func segueToCreationScreen(_ sender: UIButton){
        AudioServicesPlaySystemSound(1520) // Actuate `Pop` feedback (strong boom)
        performSegue(withIdentifier: "new", sender: nil)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {

    }
    
    
       
    
    func animatePhotoBtn(){
       
        let colorAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.borderColor))
        colorAnimation.fromValue = UIColor.cyan
        colorAnimation.toValue = UIColor.blue
        let widthAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.borderWidth))
        widthAnimation.fromValue = 11.25
        widthAnimation.toValue = 12
        let bothAnimations = CAAnimationGroup()
        bothAnimations.duration = 1
        bothAnimations.animations = [colorAnimation, widthAnimation]
        bothAnimations.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        bothAnimations.repeatCount = .infinity
        bothAnimations.autoreverses = true
        button.layer.add(bothAnimations, forKey: "color/width")
    }
    
    var speechBubble: SpeechBubble!
    
    override func viewDidLayoutSubviews() {
        
        if !view.subviews.contains(button){
            view.insertSubview(button, aboveSubview: tabBar)
            speechBubble = SpeechBubble(baseView: button, text: "Tap to create", subtitle: "a new design", fontSize: 16)
            speechBubble.borderWidth = 0
            view.addSubview(speechBubble)
        }
        view.bringSubviewToFront(button)
        view.bringSubviewToFront(spinner)
        view.bringSubviewToFront(speechBubble)
        
        checktoHideBubble()

        //let bubbleView = SpeechBubble(baseView: button, text: "Yay! Bark!", fontSize: 16.0)
    
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension UITableView{
    
    func updatePost(post: ProductInProgress, vc: UIViewController?, completed: @escaping () -> ()){
        
        var index = 0
        
        guard let productID = post.productID else{return}
        uploadingPosts.append(post)
        
        if let products = (vc as? FeedVC)?.loadedProducts ?? (vc as? UserVC)?.loadedProducts{
            guard let matchingIndex = products.firstIndex(where: {$0.productID == productID}) else{return}
            index = matchingIndex
            products[index].description = post.caption
            products[index].name = post.name
            products[index].price = (post.price ?? 2000) / 100
            products[index].isPublic = post.isPublic ?? true
        }
        else{
            guard let product = (vc as? FullProductVC)?.fullProduct else{return}
            product.description = post.caption
            product.name = post.name
            product.price = (post.price ?? 2000) / 100
            product.isPublic = post.isPublic ?? true
        }
        let indexPath = IndexPath(row: index, section: 0)
        (vc as? FullProductVC)?.editedPost = true

        performBatchUpdates({
            reloadRows(at: [indexPath], with: .none)
        }, completion: { finished in
            if finished{
                self.scrollToRow(at: IndexPath(row: index, section: 0), at: .top, animated: true)
            }
        })
        let doc = Firestore.firestore().collection("Users").document(post.uid).collection("Products").document(productID)
        let data = [
            "Name": post.name!,
            "Search_Name" : post.name.lowercased(),
            "Description" : post.caption ?? "",
            "Price_Cents" : post.price ?? "2000",
            "Public" : post.isPublic ?? true
        ] as [String : Any]
        
        doc.updateData(data, completion: { error in
            completed()
            if let err = error{
                uploadingPosts.removeAll(where: {$0.productID == productID})
                print(err.localizedDescription)
            }
            else{
                uploadingPosts.removeAll(where: {$0.productID == productID})
                self.performBatchUpdates({
                    self.reloadRows(at: [indexPath], with: .none)
                }, completion: { finished in
                    if finished{
                        self.scrollToRow(at: IndexPath(row: index, section: 0), at: .top, animated: true)
                    }
                })
            }
        })
    }
    
    func deletingPost(post: ProductInProgress, vc: UIViewController?, completed: @escaping () -> ()){
        
        guard let productID = post.productID else{
            
            return}
        let topVC = vc?.navigationController?.viewControllers.first
                
        (vc as? FeedVC)?.loadedProducts.removeAll(where: {$0.productID == productID})
        
        (vc as? FeedVC)?.loadedProducts.saveAllObjects(type: "FeedProducts")
        (topVC as? FeedVC)?.loadedProducts.removeAll(where: {$0.productID == productID})
        (topVC as? UserVC)?.loadedProducts.removeAll(where: {$0.productID == productID})
        (topVC as? FeedVC)?.loadedProducts.saveAllObjects(type: "FeedProducts")
        (topVC as? UserVC)?.loadedProducts.saveAllObjects(type: "Products")

        if vc is FeedVC{
            DispatchQueue.main.async {
                self.reloadData()
            }
        }
        else{
            if let collectionView = (topVC as? UserVC)?.collectionView{
                DispatchQueue.main.async {
                    collectionView.reloadData()
                }
            }
            vc?.navigationController?.popViewController(animated: true)
        }
        
        let doc = Firestore.firestore().collection("Users").document(post.uid).collection("Products").document(productID)

        doc.updateData(["Available" : false], completion: { error in
            completed()
            if let err = error{
                print(err.localizedDescription)
            }
            else{
                
            }
        })

    }
}

extension UINavigationController{
    
    func segueToCart(){
        
        let cartStoryboard: UIStoryboard = UIStoryboard(name: "ShoppingCartVC", bundle: nil)
        if let cart: ShoppingCartVC = cartStoryboard.instantiateViewController(withIdentifier: "CartVC") as? ShoppingCartVC{
            pushViewController(cart, animated: true)
        }
    }
    
    func segueToSales(){
        
        let salesVC: UIStoryboard = UIStoryboard(name: "SalesVC", bundle: nil)

        if let sales: SalesVC = salesVC.instantiateViewController(withIdentifier: "SalesVC") as? SalesVC{
            pushViewController(sales, animated: true)
        }
 
    }
    
    func segueToDMs(){
           
        let allChatVC: UIStoryboard = UIStoryboard(name: "AllChatsVC", bundle: nil)

        if let allChats: AllChatsVC = allChatVC.instantiateViewController(withIdentifier: "Chats") as? AllChatsVC{
            pushViewController(allChats, animated: true)
        }
    
    }
}
