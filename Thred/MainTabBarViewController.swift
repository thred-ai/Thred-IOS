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
        tabBar.items?[2].isEnabled = false
        
       // if let userVC = viewControllers?.last as? UserVC{
            //userVC.setPageInfo()
       // }
        
        // Do any additional setup after loading the view.
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        
        
        
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if let vc = (viewController as? UINavigationController)?.viewControllers.first{
            if selectedViewController == viewController{
                if let tableView =
                    (vc as? UITableViewController)?.tableView ??
                    (vc as? NotificationVC)?.tableView ?? (vc as? ExploreViewController)?.tableView{
                    var y: CGFloat = 0
                    if vc is UITableViewController{
                        y = -(vc.view.safeAreaInsets.top)
                    }
                    tableView.setContentOffset(CGPoint(x: 0, y: y), animated: true)
                }
            }
        }
        return true
    }
    
    @IBAction func unwindToTabBar(segue:  UIStoryboardSegue) {
        
        if posted ?? false{
            selectedIndex = 4
            if let profileVC = (viewControllers?[selectedIndex] as? UINavigationController)?.viewControllers.first as? UserVC{
                profileVC.uploadPost(post: product, isRetryingWithID: nil)
            }
        }
        else{
            if product != nil{
                if let vc = (selectedViewController as? UINavigationController)?.viewControllers.first{
                    if let tableView = (vc as? UITableViewController)?.tableView ?? (vc as? FullProductVC)?.tableView{
                        if deletingPost{
                            tableView.deletingPost(post: product, vc: vc)
                        }
                        else{
                            tableView.updatePost(post: product, vc: vc)
                        }
                    }
                }
            }
        }
    }
    
    
    
    
    let notificationCenter = NotificationCenter.default

    lazy var button: UIButton = {
        let tabHeight = tabBar.frame.size.height
        let width = (view.frame.width / 3) - 45
        let height = width
        let x = (view.frame.width / 3) + 22.5
        let y = view.frame.maxY - tabHeight - (height / 2)
        
        let button = UIButton.init(frame: CGRect(x: x, y: y, width: width, height: height))
        button.backgroundColor = ColorCompatibility.systemBackground
            //UIColor.init(red: 0.976, green: 0.976, blue: 0.976, alpha: 1.0)
        button.tintColor = ColorCompatibility.label
        button.layer.borderColor = UIColor(named: "LoadingColor")?.cgColor 
        button.layer.borderWidth = 6.5
        button.layer.cornerRadius = button.frame.height / 2
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(segueToCreationScreen(_:)), for: .touchUpInside)
        let img = UIImage(named: "like")?.sd_resizedImage(with: CGSize(width: width / 2, height: height / 2), scaleMode: .aspectFill)?.withRenderingMode(.alwaysTemplate)
        
        button.setImage(img, for: .normal)
        button.setRadiusWithShadow()
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
    
    override func viewDidLayoutSubviews() {
        view.insertSubview(button, aboveSubview: tabBar)
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
    
    func updatePost(post: ProductInProgress, vc: UIViewController?){
        
        var index = 0
        
        guard let productID = post.productID else{return}
        uploadingPosts.append(productID)
        
        if let products = (vc as? FeedVC)?.loadedProducts ?? (vc as? UserVC)?.loadedProducts{
            guard let matchingIndex = products.firstIndex(where: {$0.productID == productID}) else{return}
            index = matchingIndex
            products[index].description = post.caption
            products[index].name = post.name
        }
        else{
            guard let product = (vc as? FullProductVC)?.fullProduct else{return}
            product.description = post.caption
            product.name = post.name
        }
        let indexPath = IndexPath(row: index, section: 0)
        if let cell = cellForRow(at: indexPath) as? ProductCell{
            cell.optionMenu.isHidden = true
            performBatchUpdates({
                reloadRows(at: [indexPath], with: .none)
            }, completion: { finished in
                if finished{
                    self.scrollToRow(at: IndexPath(row: index, section: 0), at: .top, animated: true)
                }
            })
        }
        let doc = Firestore.firestore().collection("Users").document(post.uid).collection("Products").document(productID)
        let data = [
            "Name": post.name!,
            "Search_Name" : post.name.lowercased(),
            "Description" : post.caption ?? "",
        ] as [String : Any]
        
        doc.updateData(data, completion: { error in
            if error != nil{
                print(error?.localizedDescription ?? "")
            }
            else{
                uploadingPosts.removeAll(where: {$0 == productID})
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
    
    func deletingPost(post: ProductInProgress, vc: UIViewController?){
        
        
        guard let productID = post.productID else{return}
        let products = ((vc as? FeedVC)?.loadedProducts ?? (vc as? UserVC)?.loadedProducts)
        let index = products?.firstIndex(where: {$0.productID == productID}) ?? 0
        (vc as? FeedVC)?.loadedProducts.removeAll(where: {$0.productID == productID})
        (vc as? UserVC)?.loadedProducts.removeAll(where: {$0.productID == productID})

        if vc is FeedVC || vc is UserVC{
            let indexPath = IndexPath(row: index, section: 0)
            if let cell = cellForRow(at: indexPath) as? ProductCell{
                cell.optionMenu.isHidden = true
                performBatchUpdates({
                    deleteRows(at: [indexPath], with: .none)
                }, completion: { finished in
                    if finished{
                    }
                })
            }
        }
        else{
            vc?.navigationController?.popViewController(animated: true)
        }
        let data = [
            "uid" : post.uid,
            "product_id" : post.productID
        ]
        Functions.functions().httpsCallable("deletePost").call(data, completion: { result, error in
            if let err = error{
                print(err.localizedDescription)
            }
            else{
                
            }
        })
    }
}
