//
//  ProductCell.swift
//  Thred
//
//  Created by Arta Kouroshnia on 2019-12-17.
//  Copyright © 2019 Thred Apps Inc. All rights reserved.
//

import UIKit
import FirebaseUI
import ColorCompatibility
import FirebaseFunctions

let window = UIApplication.shared.windows.first

var likeQueue = [String: Bool]()

class ProductCell: UITableViewCell {

    @IBOutlet weak var quickLikeproductBtn: UIButton!
    
    @IBOutlet var dpMaskingViews: [UIView]!
    
    @IBOutlet var nameMaskingViews: [UIView]!
    
    @IBOutlet weak var commentBtn: UIButton!
    
    @IBOutlet weak var timestampLbl: UILabel!
    
    @IBOutlet weak var dpSkeletonView: SkeletonView!
    
    @IBOutlet weak var nameSkeletonView: SkeletonView!
    
    @IBOutlet weak var joinProductBtn: UIButton!
    
    
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var fullName: UILabel!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var productPicture: UIImageView!
    @IBOutlet weak var imageStackBar: UIStackView!
    
    @IBOutlet weak var likeBtn: UIButton!
    @IBOutlet weak var likesLbl: UILabel!
    
    @IBOutlet weak var productDescription: UITextView!
    
    @IBOutlet weak var price: UILabel!
    @IBOutlet weak var title: UITextField!
    weak var vc: UIViewController?
    
    @IBOutlet weak var userInfoView: UIView!
    
    var product: Product!
    
     var isLiked: Bool = false {
        didSet {
            if isLiked {
                likeBtn.setImage(likedImage?
                    .imageWithColor(selectedColor), for: .normal)
                product.liked = true
            } else {
                likeBtn.imageView?.stopAnimating()
                likeBtn.setImage(unlikedImage, for: .normal)
                product.liked = false
            }
        }
    }
    
    let circularProgress = CircularProgress(frame: CGRect(x: 0, y: 0, width: 80, height: 80))

    var imageCenter: CGPoint!
    
    let selectedColor = UIColor(red: 1, green: 0, blue: 0.3137, alpha: 0.9) /* #ff0050 */
    
    @objc func toProfile(_ sender: UITapGestureRecognizer) {
        if vc is FeedVC || vc is FullProductVC{
            
            switch vc {
            case let full as FullProductVC:
                if full.isRasterizing{
                    return
                }
                if let vcs = full.navigationController?.viewControllers{
                    if vcs.indices.contains(vcs.count - 2){
                        let secondLastVC = vcs[vcs.count - 2]
                        if secondLastVC.isKind(of: UserVC.self) || secondLastVC.isKind(of: FriendVC.self){
                            full.navigationController?.popViewController(animated: true)
                            return
                        }
                        else{
                            fallthrough
                        }
                    }
                }
            default:
                if product.uid == userInfo.uid{
                    vc?.tabBarController?.selectedIndex = 4
                    return
                }
            }
            
            let info = UserInfo(uid: product.uid, dp: self.userImage.image, dpID: product.userImageID ?? "null", username: product.username ?? "", fullName: product.fullName ?? "", bio: "", notifID: "", userFollowing: [], userLiked: [], followerCount: nil, postCount: nil, followingCount: nil, usersBlocking: [])
            (vc as? FullProductVC)?.friendInfo = info
            (vc as? FeedVC)?.selectedUser = info
            vc?.performSegue(withIdentifier: "toFriend", sender: nil)
        }
        else if let userVC = vc as? UserVC ?? vc as? FriendVC{
            userVC.tableView.setContentOffset(CGPoint(x: 0, y: -userVC.view.safeAreaInsets.top), animated: true)
        }
    }
    
    
    
    
    @IBAction func commentOnDesign(_ sender: UIButton) {
        
        
        let productToOpen = Product(uid: product.uid, picID: product.picID, description: product.description, fullName: product.fullName, username: product.username, productID: product.productID, userImageID: product.userImageID, timestamp: product.timestamp, index: product.index, timestampDiff: product.timestampDiff, blurred: product.blurred, price: product.price, name: product.name, templateColor: product.templateColor, likes: product.likes, liked: product.liked, designImage: product.designImage, comments: product.comments)
        
        switch vc{
            
        case let feed as FeedVC:
            feed.productToOpen = productToOpen
        case let friend as FriendVC:
            friend.productToOpen = productToOpen
        case let user as UserVC:
            user.productToOpen = productToOpen
        default:
            break
        }
        
        vc?.performSegue(withIdentifier: "toComments", sender: nil)
    }
    
    
    let likedImage = UIImage(named: "liked")
    let unlikedImage = UIImage(named: "like")
    
    @IBAction func likeDesign(_ sender: UIButton) {
        
        sender.isEnabled = false
        isUserInteractionEnabled = false
        likeQueue.removeValue(forKey: product.productID)
        if !isLiked{
            isLiked = true
            likeQueue.updateValue(true, forKey: product.productID)
            likesLbl.text = "\((product.likes) + 1)"
            product.likes += 1
            animateLike()
        }
        else{
            isLiked = false
            likeQueue.updateValue(false, forKey: product.productID)
            
            switch product.likes{
            case 0:
                let products = (vc as? FeedVC)?.loadedProducts ?? (vc as? UserVC)?.loadedProducts ?? (vc as? FriendVC)?.loadedProducts
                    userInfo.userLiked.removeAll(where: {$0 == self.product.productID})
                    UserDefaults.standard.set(userInfo.userLiked, forKey: "LikedPosts")
                    if vc is FeedVC{
                        products?.saveAllObjects(type: "FeedProducts")
                    }
                    else if vc is UserVC{
                        products?.saveAllObjects(type: "Products")
                    }
                    sender.isEnabled = true
                    isUserInteractionEnabled = true
                return
            default:
                likesLbl.text = "\((product.likes) - 1)"
                product.likes -= 1
            }
            animateUnlike()
        }
        UserDefaults.standard.set(likeQueue, forKey: "likeQueue")
        setProductInArray()
        if let feed = vc as? FeedVC{
            updateLiking(loadedProducts: feed.loadedProducts, saveType: "FeedProducts")
        }
        else if let user = vc as? UserVC{
            updateLiking(loadedProducts: user.loadedProducts, saveType: "Products")
        }
        else{
            updateLiking(loadedProducts: nil, saveType: nil)
        }
    }
    
    lazy var uploadView: UIView = {
      
        let view = UIView(frame: bounds)
        view.backgroundColor = ColorCompatibility.systemBackground.withAlphaComponent(0.5)
        var cp: MapSpinnerView! = MapSpinnerView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        cp.accessibilityIdentifier = "uploadSpinner"
        view.addSubview(cp)
        cp.center = view.center
        let retryBtn = view
        
        return view
    }()
    
    func setProductInArray(){
        let products = (vc as? FeedVC)?.loadedProducts ?? (vc as? FriendVC)?.loadedProducts ?? (vc as? UserVC)?.loadedProducts
        guard let productInArray = products?.first(where: {$0.productID == product.productID}) ?? (vc as? FullProductVC)?.fullProduct else{return}
        productInArray.likes = product.likes
        productInArray.liked = product.liked
    }
    
    func animateLike(){
        likeBtn.alpha = 0.0
        likeBtn.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
        UIView.animate(withDuration: 0.2, animations: {
            self.likeBtn.transform = CGAffineTransform.identity
            self.likeBtn.alpha = 1.0
        }, completion: { finished in
            if finished{
                self.likeBtn.isEnabled = true
                self.isUserInteractionEnabled = true
                if self.isLiked{
                    self.likeBtn.imageView?.startAnimating()
                }
            }
        })
    }
    
    func animateUnlike(){
        likeBtn.alpha = 0.0
        likeBtn.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
        UIView.animate(withDuration: 0.2, animations: {
            self.likeBtn.transform = CGAffineTransform.identity
            self.likeBtn.alpha = 1.0
        }, completion: { finished in
            self.isUserInteractionEnabled = true
            self.likeBtn.isEnabled = true
        })
    }
    
    func updateLiking(loadedProducts: [Product]?, saveType: String?){
        
        guard let uid = userInfo.uid else{return}

        let data = [
            "product_id" : product.productID,
            "creator_uid" : product.uid,
            "uid" : uid,
            "is_liking" : isLiked
            ] as [String : Any]
        Functions.functions().httpsCallable("updateLiking").call(data, completion: { result, error in
            if error != nil{
                print(error?.localizedDescription ?? "")
            }
            else{
                if self.isLiked{
                    userInfo.userLiked.append(self.product.productID)
                }
                else{
                    userInfo.userLiked.removeAll(where: {$0 == self.product.productID})
                }
                UserDefaults.standard.set(userInfo.userLiked, forKey: "LikedPosts")
                guard let type = saveType else{return}
                loadedProducts?.saveAllObjects(type: type)
            }
        })
    }
    
    lazy var canvasDisplayView: UIImageView = {
        let view = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        view.isUserInteractionEnabled = true
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        imageCenter = productPicture.center
        likeBtn.imageView?.animationImages = [
            (likedImage?.imageWithColor(selectedColor))!,
            (UIImage(named: "flap1")?.imageWithColor(selectedColor))!,
            (UIImage(named: "flap2")?.imageWithColor(selectedColor))!,
            (UIImage(named: "flap3")?.imageWithColor(selectedColor))!,
            (UIImage(named: "flap4")?.imageWithColor(selectedColor))!,
            (UIImage(named: "flap3")?.imageWithColor(selectedColor))!,
            (UIImage(named: "flap2")?.imageWithColor(selectedColor))!,
            (UIImage(named: "flap1")?.imageWithColor(selectedColor))!,
            (likedImage?.imageWithColor(selectedColor))!
        ]
        
        likeBtn.imageView?.animationDuration = 0.5
        likeBtn.imageView?.animationRepeatCount = 1
        likeBtn.setRadiusWithShadow()
        
        likeBtn.setImage(unlikedImage, for: .normal)
        likeBtn.tintColor = UIColor.darkGray
        
        if let dpMask = self.dpMaskingViews.first{
            dpMask.layer.cornerRadius = dpMask.frame.height / 2
            dpMask.clipsToBounds = true
        }
        setUpCircularProgress()
        productPicture.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(toProfile(_:)))
        userInfoView.addGestureRecognizer(tap)
        
        productPicture.addSubview(canvasDisplayView)
        addSubview(uploadView)

        NSLayoutConstraint(item: canvasDisplayView, attribute: .centerX, relatedBy: .equal, toItem: productPicture, attribute: .centerX, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: canvasDisplayView, attribute: .centerY, relatedBy: .equal, toItem: productPicture, attribute: .centerY, multiplier: 1.0, constant: -20).isActive = true
        NSLayoutConstraint(item: canvasDisplayView, attribute: .width, relatedBy: .equal, toItem: productPicture, attribute: .width, multiplier: 0.25, constant: 0).isActive = true
        NSLayoutConstraint(item: canvasDisplayView, attribute: .height, relatedBy: .equal, toItem: canvasDisplayView, attribute: .width, multiplier: canvasInfo.aspectRatio, constant: 0).isActive = true
    }
    
    func setGestureRecognizers(){
        if vc is FullProductVC{
            let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handleZoom(_:)))
            let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            pan.minimumNumberOfTouches = 2
            pan.maximumNumberOfTouches = 2
            pan.delegate = self
            pinch.delegate = self
            imageCenter = productPicture.center
            productPicture.addGestureRecognizer(pinch)
            productPicture.addGestureRecognizer(pan)
        }
        else{
            for gesture in productPicture.gestureRecognizers ?? []{
                gesture.delegate = nil
                imageCenter = nil
                productPicture.removeGestureRecognizer(gesture)
            }
        }
    }
    
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let fullVC = (vc as? FullProductVC) else{return false}
        return !fullVC.isRasterizing
    }
    
    
    
    
    func setUpCircularProgress(){
        
        if !self.productPicture.subviews.contains(circularProgress){
            circularProgress.isHidden = true
            circularProgress.progressColor = (UIColor(named: "loadingColor") ?? UIColor(red: 0.4235, green: 0.7863, blue: 0.9882, alpha: 1)) /* #e0e0e0 */
            circularProgress.trackColor = ColorCompatibility.systemFill
            circularProgress.translatesAutoresizingMaskIntoConstraints = false
            self.productPicture.addSubview(circularProgress)
            self.bringSubviewToFront(circularProgress)
            NSLayoutConstraint.activate([
                circularProgress.heightAnchor.constraint(equalToConstant: 80),
                circularProgress.widthAnchor.constraint(equalToConstant: 80),
                circularProgress.centerXAnchor.constraint(equalTo: self.productPicture.centerXAnchor),
                circularProgress.centerYAnchor.constraint(equalTo: self.productPicture.centerYAnchor)
            ])
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
         userImage.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
    }
    
    
    @IBOutlet weak var openOptionMenuBtn: UIButton!
    
    @objc func optionMenuAction1(_ sender: UIButton){
        if sender.titleLabel?.text == "Edit"{
            editProduct()
        }
        else if sender.titleLabel?.text == "Report"{
            reportProduct()
        }
    }
    
    func editProduct(){
        
        guard product != nil else{return}
        (vc as? UserVC)?.productToOpen = product
        (vc as? FeedVC)?.productToOpen = product
        openOptionMenu(nil)
        vc?.performSegue(withIdentifier: "toEdit", sender: nil)
    }
    
    func reportProduct(){
        openOptionMenu(nil)
        (vc as? FriendVC)?.reportType = .post
        vc?.performSegue(withIdentifier: "toReport", sender: nil)
    }
    
    @IBAction @objc func openOptionMenu(_ sender: UIButton?) {
        
        if !productPicture.subviews.contains(optionMenu){
            productPicture.addSubview(optionMenu)
            let tableView = (vc as? FeedVC)?.tableView ?? (vc as? UserVC)?.tableView ?? (vc as? FriendVC)?.tableView
            if let indexPath = tableView?.indexPath(for: self){
                tableView?.scrollToRow(at: indexPath, at: .top, animated: true)
            }
            tableView?.isScrollEnabled = false
            tableView?.allowsSelection = false
            optionMenu.isHidden = false
            if product?.uid == userInfo.uid{
                optionMenuActionBtn1.setTitle("Edit", for: .normal)
            }
            else{
                optionMenuActionBtn1.setTitle("Report", for: .normal)
            }
            optionMenu.alpha = 0.0
            UIView.animate(withDuration: 0.1, animations: {
                self.optionMenu.alpha = 1.0
            }, completion: {finished in
                
            })
        }
        else{
            let tableView = (vc as? FeedVC)?.tableView ?? (vc as? UserVC)?.tableView ?? (vc as? FriendVC)?.tableView
            tableView?.isScrollEnabled = true
            tableView?.allowsSelection = true
            optionMenu.removeFromSuperview()
        }
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()

        self.userImage.layer.cornerRadius = self.userImage.frame.height / 2
        self.userImage.clipsToBounds = true
        self.userImage.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
        self.userImage.layer.borderWidth = self.userImage.frame.height / 17.75
        
    }
    
    var optionMenuActionBtn1: UIButton!
    var optionMenuCancelBtn: UIButton!

    lazy var optionMenu: UIView = {
        
        let view = UIView(frame: productPicture.bounds)
        
        //view.translatesAutoresizingMaskIntoConstraints = false
       
        view.backgroundColor = ColorCompatibility.systemBackground.withAlphaComponent(0.9)

        let stackView = UIStackView.init(frame: view.bounds)
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.spacing = 0
        stackView.distribution = .fillEqually
        //stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let buttonSize = 75
        
        let optionMenuView1 = UIView.init(frame: CGRect(x: 0, y:0, width: stackView.frame.width / 2, height: stackView.frame.height))
        
        optionMenuActionBtn1 = UIButton.init(frame: CGRect(x: 0, y:0, width: buttonSize, height: buttonSize))
        optionMenuActionBtn1.setTitle("Report", for: .normal)
        optionMenuActionBtn1.backgroundColor = ColorCompatibility.tertiarySystemFill
        optionMenuActionBtn1.setTitleColor(UIColor(named: "LoadingColor"), for: .normal)
        optionMenuActionBtn1.layer.cornerRadius = optionMenuActionBtn1.frame.height / 2
        optionMenuActionBtn1.clipsToBounds = true
        optionMenuActionBtn1.center = optionMenuView1.center
        optionMenuActionBtn1.addTarget(self, action: #selector(optionMenuAction1(_:)), for: .touchUpInside)
        optionMenuView1.addSubview(optionMenuActionBtn1)
        
        let optionMenuView2 = UIView.init(frame: CGRect(x: 0, y:0, width: stackView.frame.width / 2, height: stackView.frame.height))
        optionMenuCancelBtn = UIButton.init(frame: CGRect(x: 0, y:0, width: buttonSize, height: buttonSize))
        optionMenuCancelBtn.setTitle("Cancel", for: .normal)
        optionMenuCancelBtn.backgroundColor = ColorCompatibility.tertiarySystemFill
        optionMenuCancelBtn.setTitleColor(ColorCompatibility.label, for: .normal)
        optionMenuCancelBtn.layer.cornerRadius = optionMenuCancelBtn.frame.height / 2
        optionMenuCancelBtn.clipsToBounds = true
        optionMenuCancelBtn.center = optionMenuView2.center
        optionMenuCancelBtn.addTarget(self, action: #selector(openOptionMenu(_:)), for: .touchUpInside)
        optionMenuView2.addSubview(optionMenuCancelBtn)
        
        let gesture = UITapGestureRecognizer.init(target: self, action: #selector(openOptionMenu(_:)))
        view.addGestureRecognizer(gesture)
        stackView.addArrangedSubview(optionMenuView1)
        stackView.addArrangedSubview(optionMenuView2)
        view.addSubview(stackView)
        
    
        
        
        return view
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        productPicture?.image = nil
        optionMenu.removeFromSuperview()
        //Stop or reset anything else that is needed here
    }
    
    @objc func handleZoom(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began, .changed:
            if gesture.scale >= 1 {
                let scale = gesture.scale
                gesture.view!.transform = CGAffineTransform(scaleX: scale, y: scale)
            }
            break;
        default:
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
              gesture.view!.transform = .identity
            }) { completed in
                if completed{
                    DispatchQueue.main.async {
                        self.likeBtn.isHidden = false
                        self.likesLbl.isHidden = false
                    }
                }
            }
            (vc as? FullProductVC)?.tableView.isScrollEnabled = true
        }
    }
    
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        
        switch gesture.state {
        case .began, .changed:
            self.likeBtn.isHidden = true
            self.likesLbl.isHidden = true
            (vc as? FullProductVC)?.tableView.isScrollEnabled = false
            let translation = gesture.translation(in: self.contentView)
            gesture.view?.center = CGPoint(x: gesture.view!.center.x + translation.x, y: gesture.view!.center.y + translation.y)
            gesture.setTranslation(.zero, in: self.contentView)
            break;
        default:
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
                gesture.view?.center = self.imageCenter
                gesture.setTranslation(.zero, in: self.contentView)
            }) { completed in
                if completed{
                   
                }
            }
            (vc as? FullProductVC)?.tableView.isScrollEnabled = true
            break
        }
    }
}
 
extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}

extension UIImage {
    func imageWithColor(_ color: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale);
        guard let context = UIGraphicsGetCurrentContext(), let cgImage = self.cgImage else { return nil }

        context.translateBy(x: 0, y: self.size.height)
        context.scaleBy(x: 1.0, y: -1.0);
        context.setBlendMode(.normal)
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        context.clip(to: rect, mask: cgImage)
        color.setFill()
        context.fill(rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();

        return newImage
    }
}


