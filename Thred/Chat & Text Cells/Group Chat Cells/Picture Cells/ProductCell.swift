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
import FirebaseDynamicLinks

let window = UIApplication.shared.windows.first

var likeQueue = [String: Bool]()

class ProductCell: UITableViewCell, UITextViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var pageControl: UIPageControl!
    
    var collectionViewOffset: CGFloat {
        get {
            return collectionView.contentOffset.x
        }

        set {
            scrollViewDidScroll(collectionView)
            collectionView.contentOffset.x = newValue
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }
    
    func checkForDesign(cell: ProductDesignCell?, indexPath: IndexPath){
        
        let feedVC = self.vc as? FeedVC
        let userVC = self.vc as? UserVC
        let friendVC = self.vc as? FriendVC
        let fullVC = self.vc as? FullProductVC
        cell?.vc = vc
        cell?.cell = self
        cell?.setGestureRecognizers()
        cell?.usernameLbl.text = product.name
        cell?.usernameLbl.removeShadow()
        cell?.usernameLbl.setRadiusWithShadow()
        guard let product = product else{return}
        

        let tableView = friendVC?.tableView ?? userVC?.tableView ?? feedVC?.tableView ?? fullVC?.tableView
        
        cell?.imageView.image = nil
        cell?.imageView.backgroundColor = ColorCompatibility.tertiarySystemGroupedBackground
        
        if let username = product.userInfo.username{
            cell?.usernameLbl.text = "@\(username)"
            cell?.usernameLbl.removeShadow()
            cell?.usernameLbl.setRadiusWithShadow()
        }
        
        if let picCell = collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? ProductPicCell{
            cell?.circularProgress.setProgressWithAnimation(duration: 0.0, value: picCell.circularProgress.progressValue, from: 0, finished: true){
                
            }
        }
        
        DispatchQueue(label: "cache").async {
            let img = cache.imageFromCache(forKey: product.picID)
            
            DispatchQueue.main.async {
                if let imgFromCache = img{
                    let products = feedVC?.loadedProducts ?? userVC?.loadedProducts ?? friendVC?.loadedProducts

                    let index = products?.firstIndex(where: {$0.productID == product.picID!}) ?? 0
                        
                    if let cell = tableView?.cellForRow(at: IndexPath(row: index, section: 0)) as? ProductCell{
                        if let designCell = cell.collectionView.cellForItem(at: indexPath) as? ProductDesignCell{
                            designCell.imageView.backgroundColor = UIColor(named: product.templateColor)
                            designCell.imageView.image = imgFromCache
                            designCell.circularProgress.isHidden = true
                        }
                    }
                }
            }
        }
        
    }
    
    func checkForPic(cell: ProductPicCell?, indexPath: IndexPath, shouldDownload: Bool){
        
        let feedVC = self.vc as? FeedVC
        let userVC = self.vc as? UserVC
        let friendVC = self.vc as? FriendVC
        let fullVC = self.vc as? FullProductVC
        guard let product = product else{return}

        let tableView = friendVC?.tableView ?? userVC?.tableView ?? feedVC?.tableView ?? fullVC?.tableView
        
        cell?.imageView.image = nil
        cell?.canvasDisplayView.image = nil
        cell?.circularProgress.isHidden = true
        cell?.vc = vc
        cell?.cell = self
        cell?.setGestureRecognizers()
        
        if let full = self.vc as? FullProductVC{
            if full.selectedComment != nil{
                full.navigationItem.hidesBackButton = true
            }
        }
        
        DispatchQueue(label: "cache").async {
            let img = cache.imageFromCache(forKey: product.picID)
            let bundlePath = Bundle.main.path(forResource: product.templateColor, ofType: "png")
            let image = UIImage(contentsOfFile: bundlePath!)
            
            DispatchQueue.main.async {
                if let imgFromCache = img{
                    let products = feedVC?.loadedProducts ?? userVC?.loadedProducts ?? friendVC?.loadedProducts

                    let index = products?.firstIndex(where: {$0.productID == product.picID!}) ?? 0
                        
                    if let cell = tableView?.cellForRow(at: IndexPath(row: index, section: 0)) as? ProductCell{
                        if let picCell = cell.collectionView.cellForItem(at: indexPath) as? ProductPicCell{
                            picCell.imageView.image = image
                            picCell.canvasDisplayView.image = imgFromCache
                            picCell.circularProgress.isHidden = true
                            picCell.imageView.removeShadow()
                            picCell.imageView.addShadowToImageNotLayer()
                        }
                        if let designCell = cell.collectionView.cellForItem(at: indexPath) as? ProductDesignCell{
                            designCell.imageView.image = imgFromCache
                            designCell.circularProgress.isHidden = true
                        }
                    }
                    if let full = self.vc as? FullProductVC{
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            full.navigationItem.hidesBackButton = false
                            if full.selectedComment != nil{
                                full.performSegue(withIdentifier: "toComments", sender: nil)
                            }
                        }
                    }
                }
                else if shouldDownload{
                    self.checkAndDownload(picID: product.picID!, cp: cell?.circularProgress, completed: { imgDownloaded, picID in
                        let products = feedVC?.loadedProducts ?? userVC?.loadedProducts ?? friendVC?.loadedProducts

                        let index = products?.firstIndex(where: {$0.productID == product.picID!}) ?? 0
                        
                        if let cell = tableView?.cellForRow(at: IndexPath(row: index, section: 0)) as? ProductCell{
                            cell.collectionView.reloadData()
                        }
                    })
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        if let picCell = cell as? ProductPicCell{
            if picCell.canvasDisplayView.image == nil{
                checkForPic(cell: picCell, indexPath: indexPath, shouldDownload: false)
            }
        }
        else if let designCell = cell as? ProductDesignCell{
            if designCell.imageView.image == nil{
                checkForDesign(cell: designCell, indexPath: indexPath)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        

        if indexPath.row == 0{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "productPic", for: indexPath) as? ProductPicCell
            checkForPic(cell: cell, indexPath: indexPath, shouldDownload: true)
            return cell!
        }
        else{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "productDesign", for: indexPath) as? ProductDesignCell
            checkForDesign(cell: cell, indexPath: indexPath)
            return cell!
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let x = scrollView.contentOffset.x
        let w = scrollView.bounds.size.width
        let currentPage = Int(ceil(x/w))
        pageControl.currentPage = currentPage
    }
    
    func checkAndDownload(picID: String, cp: CircularProgress?, completed: @escaping (UIImage?, String?) -> ()){
        let pic_id = picID
        //if product?.blurred ?? false{
         //   pic_id = "blur_\(pic_id)"
        //}
        
        //if vc is FullProductVC{
        //    pic_id = "thumbnail_\(picID)"
        //}
        cp?.isHidden = false

        let ref = Storage.storage().reference().child("Users/" + product.userInfo.uid! + "/" + "Products/" + picID + "/" + pic_id + ".png")
        ref.downloadURL(completion: { url, error in
            if error != nil{
                print(error?.localizedDescription ?? "")
                completed(nil, picID)
            }
            else{
                var dub: CGFloat = 0
                var oldDub: CGFloat = 0
                downloader.requestImage(with: url, options: [.highPriority, .continueInBackground, .scaleDownLargeImages], context: nil, progress: { (receivedSize: Int, expectedSize: Int, link) -> Void in
                    dub = CGFloat(receivedSize) / CGFloat(expectedSize)
                    print("Progress \(dub)")
                    print("Old Progress \(oldDub)")
                    DispatchQueue.main.async {
                        
                        cp?.setProgressWithAnimation(duration: 0.0, value: dub, from: oldDub, finished: true){
                            oldDub = dub
                        }
                    }
                }, completed: {(image, data, error, finished) in
                    if error != nil{
                        print(error?.localizedDescription ?? "")
                        completed(nil, picID)
                    }
                    else{
                        if let imgData = data{
                            completed(image, picID)
                            if self.vc is FullProductVC{
                                DispatchQueue(label: "store").async {
                                    cache.storeImageData(toDisk: imgData, forKey: pic_id)
                                }
                            }
                            else{
                                let feedVC = self.vc as? FeedVC
                                let userVC = self.vc as? UserVC
                                let friendVC = self.vc as? FriendVC

                                if let products = feedVC?.loadedProducts ?? userVC?.loadedProducts ?? friendVC?.loadedProducts {
                                    if let index = products.firstIndex(where: {$0.productID == self.product.productID}){
                                        DispatchQueue(label: "store").async {
                                            if index <= 7{
                                                cache.storeImageData(toDisk: imgData, forKey: picID)
                                            }
                                            else{
                                                cache.storeImage(toMemory: image, forKey: picID)
                                            }
                                        }
                                    }
                                    else{
                                        
                                    }
                                }
                                else{
                                    
                                }
                            }
                        }
                    }
                })
            }
        })
    }
    

    @IBOutlet weak var progressView: UIProgressView!
    
    @IBOutlet weak var shareBtn: UIButton!
    
    @IBOutlet var dpMaskingViews: [UIView]!
    @IBOutlet weak var infoStack: UIStackView!
    
    @IBOutlet weak var spinner: MapSpinnerView!
    @IBOutlet var nameMaskingViews: [UIView]!
    
    @IBOutlet weak var uploadView: UIView!
    @IBOutlet weak var commentBtn: UIButton!
    
    @IBOutlet weak var timestampLbl: UILabel!
    
    @IBOutlet weak var dpSkeletonView: SkeletonView!
    
    @IBOutlet weak var nameSkeletonView: SkeletonView!
    
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var fullName: UILabel!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var imageStackBar: UIStackView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var likeBtn: UIButton!
    @IBOutlet weak var likesLbl: UILabel!
    
    @IBOutlet weak var productDescription: UITextView!
    
    @IBOutlet weak var price: UILabel!
    @IBOutlet weak var title: UIButton!
    weak var vc: UIViewController?
    @IBOutlet weak var optionMenuActionBtn1: UIButton!
    @IBOutlet weak var optionMenuCancelBtn: UIButton!
    @IBOutlet weak var optionMenu: UIView!
    
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
                if product.userInfo.uid == userInfo.uid{
                    vc?.tabBarController?.selectedIndex = 4
                    return
                }
            }
            
            (vc as? FullProductVC)?.friendInfo = product.userInfo
            (vc as? FeedVC)?.selectedUser = product.userInfo
            vc?.performSegue(withIdentifier: "toFriend", sender: nil)
        }
        if let userVC = vc as? UserVC{
            userVC.tableView.setContentOffset(CGPoint(x: 0, y: -userVC.view.safeAreaInsets.top), animated: true)
        }
        if let friendVC = vc as? FriendVC{
            friendVC.tableView.setContentOffset(CGPoint(x: 0, y: -friendVC.view.safeAreaInsets.top), animated: true)
        }
    }
    
    func animateProgressBar(value: CGFloat){
        self.progressView.setProgress(Float(value), animated: true)
    }
    
    @objc func doubleTapped(_ sender: UITapGestureRecognizer) {
        likeDesign(likeBtn)
    }
    
    
    
    
    @IBAction func sharePost(_ sender: UIButton) {
        
        if uploadingPosts.contains(product.productID){
            return
        }
                
        animateProgressBar(value: 0.2)
        
        getLink(completed: { url in
            guard let url = url else{return}
            self.animateProgressBar(value: 1.0)
            var shareMessage = "Check out this t-shirt on Thred!"
            if self.product.userInfo.uid == userInfo.uid{
                shareMessage = "Check out my t-shirt on Thred!"
            }
            let activity = UIActivityViewController(
                  activityItems: [shareMessage, url],
                  applicationActivities: nil
                )
            //activity.popoverPresentationController?.bu
                // 3
            self.getViewController()?.present(activity, animated: true, completion: nil)
            DispatchQueue.main.async {
                self.progressView.setProgress(0.0, animated: false)
            }
        })
    }
    
    func getLink(completed: @escaping (URL?) -> ()){
        self.animateProgressBar(value: 0.4)
        if product.link == nil{
            generateLink(product: product, completed: { link in
                self.product.link = link
                self.animateProgressBar(value: 0.8)
                completed(link)
            })
        }
        else{
            completed(product.link)
        }
    }
    
    func getThumbnailURL(completed: @escaping (URL?) -> ()){
        guard let productUID = product.userInfo.uid else{
            completed(nil)
            return
        }
        let ref = Storage.storage().reference().child("Users/" + productUID + "/" + "Products/" + product.productID + "/" + "link_" + product.productID + ".png")
        ref.downloadURL(completion: { url, error in
            if error != nil{
                print(error?.localizedDescription ?? "")
                completed(nil)
            }
            else{
                completed(url)
            }
        })
        
    }
    
    func generateLink(product: Product, completed: @escaping (URL?) -> ()){
        guard let productUID = product.userInfo.uid else{
            completed(nil)
            return
        }
        guard let link = URL(string: "https://thredapps.com/users/\(productUID)/product/\(product.productID)") else {
            completed(nil)
            return }
        let dynamicLinksDomainURIPrefix = "https://thred.thredapps.com"
        let linkBuilder = DynamicLinkComponents(link: link, domainURIPrefix: dynamicLinksDomainURIPrefix)
        linkBuilder?.iOSParameters = DynamicLinkIOSParameters(bundleID: "thred.Thred")
        linkBuilder?.androidParameters = DynamicLinkAndroidParameters(packageName: "com.example.android")
        linkBuilder?.iOSParameters?.appStoreID = "1506286170"
        var descriptionToAdd = ""
        var fullNameToAdd = ""
        
        if let description = product.description, !description.isEmpty{
            descriptionToAdd = " - \(description)"
        }
        if let fullName = product.userInfo.fullName{
            fullNameToAdd = "\(fullName)'s "
        }
        linkBuilder?.socialMetaTagParameters = DynamicLinkSocialMetaTagParameters()
        linkBuilder?.socialMetaTagParameters?.title = "\(fullNameToAdd)Thred post: \"\(product.name ?? "")\(descriptionToAdd)\""
        linkBuilder?.options = DynamicLinkComponentsOptions()
        linkBuilder?.options?.pathLength = .short
        getThumbnailURL(completed: { url in
            self.animateProgressBar(value: 0.6)
            linkBuilder?.socialMetaTagParameters?.imageURL = url
            guard let longDynamicLink = linkBuilder?.url else {
                completed(nil)
                return }
            print("The long URL is: \(longDynamicLink)")
            linkBuilder?.shorten() { url, warnings, error in
                if let err = error{
                    print(err.localizedDescription)
                    completed(nil)
                }
                else{
                    completed(url)
                    guard let url = url else { return }
                    print("The short URL is: \(url)")
                }
            }
        })
    }
    
    @IBAction func commentOnDesign(_ sender: UIButton) {
        
        if uploadingPosts.contains(product.productID){
            return
        }
        
        let productToOpen = Product(userInfo: product.userInfo, picID: product.picID, description: product.description, productID: product.productID, timestamp: product.timestamp, index: product.index, timestampDiff: product.timestampDiff, blurred: product.blurred, price: product.price, name: product.name, templateColor: product.templateColor, likes: product.likes, liked: product.liked, designImage: product.designImage, comments: product.comments, link: nil)
        
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
        
        if uploadingPosts.contains(product.productID){
            return
        }
        
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
        guard let productUID = product.userInfo.uid else{return}

        let data = [
            "product_id" : product.productID,
            "creator_uid" : productUID,
            "uid" : uid,
            "is_liking" : isLiked
            ] as [String : Any]
        
        vc?.checkAuthStatus {
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
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.frame.width, height: self.frame.width)
    }
    
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        productDescription.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "ProductPicCell", bundle: nil), forCellWithReuseIdentifier: "productPic")
        collectionView.register(UINib(nibName: "ProductDesignCell", bundle: nil), forCellWithReuseIdentifier: "productDesign")

        title.titleLabel?.adjustsFontSizeToFitWidth = true
        title.titleLabel?.minimumScaleFactor = 0.5
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
        uploadView.backgroundColor = ColorCompatibility.systemBackground.withAlphaComponent(0.5)

        
        likeBtn.setImage(unlikedImage, for: .normal)
        likeBtn.tintColor = UIColor.lightGray
        
        if let dpMask = self.dpMaskingViews.first{
            dpMask.layer.cornerRadius = dpMask.frame.height / 2
            dpMask.clipsToBounds = true
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(toProfile(_:)))
        userInfoView.addGestureRecognizer(tap)
        
        shareBtn.setImage(UIImage(nameOrSystemName: "arrowshape.turn.up.right", systemPointSize: 17, iconSize: 7), for: .normal)
        
        let tapper2 = UITapGestureRecognizer(target: self, action: #selector(segueToFull(_:)))
        tapper2.numberOfTapsRequired = 1
        infoStack.addGestureRecognizer(tapper2)
        
        
        
        optionMenu.backgroundColor = ColorCompatibility.systemBackground.withAlphaComponent(0.9)
        let gesture = UITapGestureRecognizer.init(target: self, action: #selector(openOptionMenu(_:)))
        optionMenu.addGestureRecognizer(gesture)

        let tapper = UITapGestureRecognizer(target: self, action: #selector(doubleTapped(_:)))
        tapper.numberOfTapsRequired = 2
        collectionView.addGestureRecognizer(tapper)

    }
    
    @IBAction @objc func segueToFull(_ sender: Any){
        
        guard !(self.vc is FullProductVC) else{return}
        (self.vc as? UserVC)?.productToOpen = self.product
        (self.vc as? FriendVC)?.productToOpen = self.product
        (self.vc as? FeedVC)?.productToOpen = self.product
        self.vc?.performSegue(withIdentifier: "toFull", sender: nil)
        
    }
    
    
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        
        if let scheme = URL.scheme{
            if interaction == .preview{
                return false
            }
            if scheme.starts(with: "mention"){
                let username = URL.absoluteString.replacingOccurrences(of: "mention:", with: "")
                if username != userInfo.username, username != (vc as? FriendVC)?.friendInfo.username{
                    let user = UserInfo(uid: nil, dp: nil, dpID: nil, username: username, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: [], profileLink: nil)
                    (vc as? FriendVC)?.selectedUser = user
                    (vc as? UserVC)?.selectedUser = user
                    (vc as? FeedVC)?.selectedUser = user
                    (vc as? FullProductVC)?.friendInfo = user
                    vc?.performSegue(withIdentifier: "toFriend", sender: nil)
                }
            }
            else{
                return true
            }
        }
        return false
    }
    
    
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
         userImage.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
    }
    
    
    @IBOutlet weak var openOptionMenuBtn: UIButton!
    
    @IBAction func optionMenuAction1(_ sender: UIButton){
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
        (vc as? FriendVC)?.selectedReportID = product.productID
        (vc as? FeedVC)?.selectedReportID = product.productID
        (vc as? FeedVC)?.selectedReportUID = product.userInfo.uid

        vc?.performSegue(withIdentifier: "toReport", sender: nil)
    }
    
    @IBAction func openOptionMenu(_ sender: UIButton?) {
        
        if optionMenu.isHidden{
            optionMenu.isHidden = false
            optionMenu.superview?.bringSubviewToFront(optionMenu)
            let tableView = (vc as? FeedVC)?.tableView ?? (vc as? UserVC)?.tableView ?? (vc as? FriendVC)?.tableView
            if let indexPath = tableView?.indexPath(for: self){
                tableView?.scrollToRow(at: indexPath, at: .top, animated: true)
            }
            tableView?.isScrollEnabled = false
            tableView?.allowsSelection = false
            if product?.userInfo.uid == userInfo.uid{
                optionMenuActionBtn1.titleLabel?.text = "Edit"
                optionMenuActionBtn1.setTitle("Edit", for: .normal)
            }
            else{
                optionMenuActionBtn1.titleLabel?.text = "Report"
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
            optionMenu.isHidden = true
        }
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        spinner.animate()

        self.userImage.layer.cornerRadius = self.userImage.frame.height / 2
        self.userImage.clipsToBounds = true
        self.userImage.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
        self.userImage.layer.borderWidth = self.userImage.frame.height / 17.75
        
        if let superView1 = optionMenuActionBtn1.superview, let superView2 = optionMenuCancelBtn.superview{
            superView1.layer.cornerRadius = superView1.frame.height / 2
            superView1.clipsToBounds = true
            superView1.backgroundColor = ColorCompatibility.tertiarySystemFill
            
            superView2.layer.cornerRadius = superView2.frame.height / 2
            superView2.clipsToBounds = true
            superView2.backgroundColor = ColorCompatibility.tertiarySystemFill
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        optionMenu.isHidden = true
        //Stop or reset anything else that is needed here
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


