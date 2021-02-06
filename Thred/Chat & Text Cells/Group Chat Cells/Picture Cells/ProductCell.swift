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
import PopupDialog
import AVKit
import FirebaseAnalytics

let window = UIApplication.shared.windows.first

var likeQueue = [String: Bool]()
var commentQueue = [String: Bool]()

class ProductCell: UITableViewCell, UITextViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var privateBanner: UIView!
    
    @IBAction func privateBannerTapped(_ sender: UIButton) {
        
    }
    @IBOutlet weak var viewFullProductView: UIView!
    
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
        let same = all.tees.first(where: {$0.productCode == product?.productType})
        return same?.supportedSides.count ?? 0
    }
    
    
    func checkForDesign(cell: ProductDesignCell?, indexPath: IndexPath, shouldDownload: Bool){
        
        let feedVC = self.vc as? FeedVC
        let userVC = self.vc as? UserVC
        let friendVC = self.vc as? FriendVC
        let fullVC = self.vc as? FullProductVC
        cell?.vc = vc
        cell?.cell = self
        cell?.setGestureRecognizers()
        cell?.usernameLbl.text = product.name
        cell?.imageView.backgroundColor = nil
        cell?.usernameLbl.removeShadow()
        cell?.usernameLbl.setRadiusWithShadow()
        
        cell?.usernameLbl.isHidden = vc is FeedVC
        
        guard let product = product else{return}
        
        let color = all.tees.first(where: {$0.productCode == product.productType})?.colors.first(where: {$0.code == product.templateColor})?.getColor()

        let tableView = feedVC?.tableView ?? fullVC?.tableView
        
        cell?.imageView.image = nil
        
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
                            designCell.imageView.image = imgFromCache
                            designCell.imageView.backgroundColor = color
                            designCell.circularProgress.isHidden = true
                        }
                    }
                    if let full = self.vc as? FullProductVC{
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            full.navigationItem.hidesBackButton = false
                            if full.selectedComment != nil, product.isAvailable{
                                full.performSegue(withIdentifier: "toComments", sender: nil)
                            }
                        }
                    }
                }
                else if shouldDownload{
                    self.checkAndDownload(picID: product.picID!, cp: cell?.circularProgress, side: .front, completed: { imgDownloaded, picID in
                        let products = feedVC?.loadedProducts ?? userVC?.loadedProducts ?? friendVC?.loadedProducts

                        let index = products?.firstIndex(where: {$0.productID == product.picID!}) ?? 0
                        
                        if let cell = tableView?.cellForRow(at: IndexPath(row: index, section: 0)) as? ProductCell{
                            cell.collectionView.reloadData()
                        }
                    })
                }
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
                            designCell.imageView.backgroundColor = color
                            designCell.imageView.image = imgFromCache
                            designCell.circularProgress.isHidden = true
                        }
                    }
                }
            }
        }
    }
    
    
    func checkForPic(cell: ProductPicCell?, indexPath: IndexPath, shouldDownload: Bool, side: DisplaySide){
        
        let feedVC = self.vc as? FeedVC
        let userVC = self.vc as? UserVC
        let friendVC = self.vc as? FriendVC
        let fullVC = self.vc as? FullProductVC
        guard let product = product else{return}

        let tableView = feedVC?.tableView ?? fullVC?.tableView
        
        cell?.imageView.image = nil
        
        for view in cell?.canvasDisplayViews ?? []{
            view.imageView?.image = nil
            view.setImage(nil, for: .normal)
        }
        cell?.circularProgress.isHidden = true
        cell?.vc = vc
        cell?.cell = self
        cell?.setGestureRecognizers()
        let type = all.tees.first(where: {$0.productCode == product.productType})
        cell?.addConstraints(template: type, displaySide: side)
        
        if let full = self.vc as? FullProductVC{
            if full.selectedComment != nil{
                full.navigationItem.hidesBackButton = true
            }
        }
        
        DispatchQueue(label: "cache").async {
            
            guard let color = all.tees.first(where: {$0.productCode == product.productType})?.colors?.first(where: {$0.code == product.templateColor})
            else{return}
            var picID = product.picID
            var data: Data!

            if side == .back{
                data = color.imgBack
                picID = "BACK_\(product.picID ?? "")"
            }
            else{
                data = color.img
            }
            
            let image = UIImage(data: data)
            
            let img = cache.imageFromCache(forKey: picID)
            
            
            
            DispatchQueue.main.async {
                if let imgFromCache = img{
                    let products = feedVC?.loadedProducts ?? userVC?.loadedProducts ?? friendVC?.loadedProducts

                    let index = products?.firstIndex(where: {$0.productID == product.picID!}) ?? 0
                        
                    if let cell = tableView?.cellForRow(at: IndexPath(row: index, section: 0)) as? ProductCell{
                        if let picCell = cell.collectionView.cellForItem(at: indexPath) as? ProductPicCell{
                            picCell.imageView.image = image
                            for view in picCell.canvasDisplayViews{
                                view.imageView?.image = imgFromCache
                                view.setImage(imgFromCache, for: .normal)
                            }
                            picCell.circularProgress.isHidden = true
                        }
                        if let designCell = cell.collectionView.cellForItem(at: indexPath) as? ProductDesignCell{
                            designCell.imageView.image = imgFromCache
                            designCell.circularProgress.isHidden = true
                        }
                    }
                    if let full = self.vc as? FullProductVC{
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            full.navigationItem.hidesBackButton = false
                            if full.selectedComment != nil, product.isAvailable{
                                full.performSegue(withIdentifier: "toComments", sender: nil)
                            }
                        }
                    }
                }
                else if shouldDownload{
                    self.checkAndDownload(picID: product.picID!, cp: cell?.circularProgress, side: side, completed: { imgDownloaded, picID in
                        let products = feedVC?.loadedProducts ?? userVC?.loadedProducts ?? friendVC?.loadedProducts

                        let index = products?.firstIndex(where: {$0.productID == product.picID!}) ?? 0
                        
                        if let cell = tableView?.cellForRow(at: IndexPath(row: index, section: 0)) as? ProductCell{
                            cell.collectionView.reloadData()
                        }
                    })
                }
                else{
                    cell?.imageView.image = image
                    cell?.circularProgress.isHidden = true
                    if let full = self.vc as? FullProductVC{
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            full.navigationItem.hidesBackButton = false
                            if full.selectedComment != nil, product.isAvailable{
                                full.performSegue(withIdentifier: "toComments", sender: nil)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        /*
        if let picCell = cell as? ProductPicCell{
            if picCell.canvasDisplayView.image == nil{
                checkForPic(cell: picCell, indexPath: indexPath, shouldDownload: false)
            }
        }
        else if let designCell = cell as? ProductDesignCell{
            if designCell.imageView.image == nil{
                checkForDesign(cell: designCell, indexPath: indexPath, shouldDownload: false)
            }
        }
 */
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "productPic", for: indexPath) as? ProductPicCell
        if indexPath.item == 0{
            checkForPic(cell: cell, indexPath: indexPath, shouldDownload: product?.supportedSides.contains("Front") ?? false, side: .front)
        }
        else{
            checkForPic(cell: cell, indexPath: indexPath, shouldDownload: product?.supportedSides.contains("Back") ?? false, side: .back)
        }
        return cell!
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let x = scrollView.contentOffset.x
        let w = scrollView.bounds.size.width
        let currentPage = Int(ceil(x/w))
        pageControl.currentPage = currentPage
    }
    
    func checkAndDownload(picID: String, cp: CircularProgress?, side: DisplaySide, completed: @escaping (UIImage?, String?) -> ()){
        
        var prefix = ""
        if side == .back{
            prefix = "BACK_"
        }

        let picString = "\(prefix)\(picID)"
        cp?.isHidden = false

        let ref = Storage.storage().reference().child("Users/" + product.userInfo.uid! + "/" + "Products/" + picID + "/" + picString + ".png")
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
                                    cache.storeImageData(toDisk: imgData, forKey: picString)
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
                                                cache.storeImageData(toDisk: imgData, forKey: picString)
                                            }
                                            else{
                                                cache.storeImage(toMemory: image, forKey: picString)
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
    
    @IBOutlet weak var userInfoView: UIView!
    
    var product: Product!{
        didSet{
            let same = all.tees.first(where: {$0.productCode == product.productType})
            pageControl.numberOfPages = same?.supportedSides.count ?? 0
        }
    }
    
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
            if product.likes == 0{
                likesLbl.text = "No likes yet"
            }
            else{
                var grammar = ""
                if product.likes > 1{
                    grammar = "s"
                }
                likesLbl.text = "\((product.likes).kmFormatted) like\(grammar)"
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
                if product.userInfo.uid == pUserInfo.uid{
                    vc?.tabBarController?.selectedIndex = 4
                    return
                }
            }
            
            (vc as? FullProductVC)?.friendInfo = product.userInfo
            (vc as? FeedVC)?.selectedUser = product.userInfo
            vc?.performSegue(withIdentifier: "toFriend", sender: nil)
        }
        if let userVC = vc as? UserVC{
            userVC.collectionView.setContentOffset(CGPoint(x: 0, y: -userVC.view.safeAreaInsets.top), animated: true)
        }
        if let friendVC = vc as? FriendVC{
            friendVC.collectionView.setContentOffset(CGPoint(x: 0, y: -friendVC.view.safeAreaInsets.top), animated: true)
        }
    }

    
    @objc func doubleTapped(_ sender: UITapGestureRecognizer) {
        likeDesign(likeBtn)
    }
    
    
    
    
    func sharePost(_ sender: UIButton?) {
        
        if uploadingPosts.contains(where: {$0.productID == product.productID}){
            return
        }
                
        product?.sharePost(progressView: progressView)
        
    }
    
    
    @IBAction func commentOnDesign(_ sender: UIButton) {
        
        if uploadingPosts.contains(where: {$0.productID == product.productID}){
            return
        }
        
        let productToOpen = Product(userInfo: product.userInfo, picID: product.picID, description: product.description, productID: product.productID, timestamp: product.timestamp, index: product.index, timestampDiff: product.timestampDiff, blurred: product.blurred, price: product.price, name: product.name, templateColor: product.templateColor, likes: product.likes, liked: product.liked, designImage: product.designImage, comments: product.comments, link: nil, isAvailable: product.isAvailable, isPublic: product.isPublic, productType: product.productType, displaySide: product.displaySide, supportedSides: product.supportedSides)
                
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
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        if uploadingPosts.contains(where: {$0.productID == product.productID}) || !(product.isPublic ?? true) {
            return
        }
        
        sender.isEnabled = false
        isUserInteractionEnabled = false
        likeQueue.removeValue(forKey: product.productID)
        if !isLiked{
            product.likes += 1
            isLiked = true
            likeQueue.updateValue(true, forKey: product.productID)
            animateLike()
            Analytics.logEvent("fluttered_design", parameters: [
                "name": "Fluttered Design",
                "full_text": "User fluttered another design"
            ])
        }
        else{
            
            switch product.likes{
            case 0:
                let products = (vc as? FeedVC)?.loadedProducts ?? (vc as? UserVC)?.loadedProducts ?? (vc as? FriendVC)?.loadedProducts
                    pUserInfo.userLiked.removeAll(where: {$0 == self.product.productID})
                    UserDefaults.standard.set(pUserInfo.userLiked, forKey: "LikedPosts")
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
                product.likes -= 1
            }
            isLiked = false
            likeQueue.updateValue(false, forKey: product.productID)
            
            animateUnlike()
            Analytics.logEvent("unfluttered_design", parameters: [
                "name": "Unfluttered Design",
                "full_text": "User unfluttered another design"
            ])
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
        
        guard let uid = pUserInfo.uid else{return}
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
                        pUserInfo.userLiked.append(self.product.productID)
                    }
                    else{
                        pUserInfo.userLiked.removeAll(where: {$0 == self.product.productID})
                    }
                    UserDefaults.standard.set(pUserInfo.userLiked, forKey: "LikedPosts")
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
        uploadView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.5)

        
        likeBtn.setImage(unlikedImage, for: .normal)
        likeBtn.tintColor = UIColor.label
        
        if let dpMask = self.dpMaskingViews.first{
            dpMask.layer.cornerRadius = dpMask.frame.height / 2
            dpMask.clipsToBounds = true
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(toProfile(_:)))
        userInfoView.addGestureRecognizer(tap)
        
        //shareBtn.setImage(UIImage(nameOrSystemName: "arrowshape.turn.up.right", systemPointSize: 17, iconSize: 7), for: .normal)
        
        let tapper2 = UITapGestureRecognizer(target: self, action: #selector(segueToFull(_:)))
        tapper2.numberOfTapsRequired = 1
        infoStack?.addGestureRecognizer(tapper2)
        
        
        let tapper = UITapGestureRecognizer(target: self, action: #selector(doubleTapped(_:)))
        tapper.numberOfTapsRequired = 2
        collectionView.addGestureRecognizer(tapper)

    }
    
    @IBAction @objc func segueToFull(_ sender: Any){
        
        guard !(vc is FullProductVC) else{return}
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
                if username != pUserInfo.username, username != (vc as? FriendVC)?.friendInfo.username{
                    let user = UserInfo(uid: nil, dp: nil, dpID: nil, username: username, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: [], profileLink: nil, verified: nil)
                    (vc as? FriendVC)?.selectedUser = user
                    (vc as? UserVC)?.selectedUser = user
                    (vc as? FeedVC)?.selectedUser = user
                    (vc as? FullProductVC)?.friendInfo = user
                    vc?.performSegue(withIdentifier: "toFriend", sender: nil)
                }
            }
            else if scheme.starts(with: "hashtag"){
                let tag = URL.absoluteString.replacingOccurrences(of: "hashtag:", with: "")
                let hashtag = Hashtag(postsCount: nil, array: nil, display: tag, offset: 0, downloading: [], tagDownloading: [], blurred: nil, topPost: nil)
                (vc as? FriendVC)?.hashtagToOpen = hashtag
                (vc as? UserVC)?.hashtagToOpen = hashtag
                (vc as? FeedVC)?.hashtagToOpen = hashtag
                (vc as? FullProductVC)?.hashtagToOpen = hashtag
                
                vc?.performSegue(withIdentifier: "toHashtag", sender: nil)

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

    
    func editProduct(){
        
        guard product != nil else{return}
        
        (vc as? FeedVC)?.productToOpen = product
        vc?.performSegue(withIdentifier: "toEdit", sender: nil)
    }
    
    func reportProduct(){
        (vc as? FriendVC)?.reportType = .post
        (vc as? FriendVC)?.selectedReportID = product.productID
        (vc as? FeedVC)?.selectedReportID = product.productID
        (vc as? FeedVC)?.selectedReportUID = product.userInfo.uid

        vc?.performSegue(withIdentifier: "toReport", sender: nil)
    }
    
    @IBAction func openOptionMenu(_ sender: UIButton?) {
        
        var buttonArray = [DefaultButton]()
        guard let productName = all.tees.first(where: {$0.productCode == product.productType})?.templateDisplayName
        else{return}
        let shareBtn = DefaultButton(title: "SHARE", dismissOnTap: true) {
            self.sharePost(nil)
        }
        buttonArray.append(shareBtn)
        
        let title = "\(self.product.name ?? "<null>") • \(productName)"
        switch product.userInfo.uid {
        case pUserInfo.uid:
            let editBtn = DefaultButton(title: "EDIT", dismissOnTap: true) {
                self.editProduct()
            }
            buttonArray.append(editBtn)
        default:
            let reportBtn = DefaultButton(title: "REPORT", dismissOnTap: true) {
                self.reportProduct()
            }
            buttonArray.append(reportBtn)
        }

        let cancelBtn = DefaultButton(title: "CANCEL", dismissOnTap: true) {
            
        }
        buttonArray.append(cancelBtn)
        
        vc?.showPopUp(title: title, message: nil, image: nil, buttons: buttonArray, titleColor: .label, blurBack: false)
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        spinner.animate()

        userImage.layer.cornerRadius = userImage.frame.height / 2
        userImage.clipsToBounds = true
        userImage.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
        userImage.layer.borderWidth = userImage.frame.height / 17.75
        
        privateBanner.layer.cornerRadius = privateBanner.frame.height / 4
        privateBanner.clipsToBounds = true
        
        viewFullProductView.layer.cornerRadius = viewFullProductView.frame.height / 4
        viewFullProductView.clipsToBounds = true

        
    }

    override func prepareForReuse() {
        super.prepareForReuse()
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

extension UILabel{
    func setVerified(name: String){
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = UIImage(systemName: "checkmark.seal.fill")?.withTintColor(UIColor(named: "LoadingColor")!)
        let sizeSide: CGFloat = 15
        let iconsSize = CGRect(x: CGFloat(0),
                               y: (font.capHeight - sizeSide) / 2,
                               width: sizeSide,
                               height: sizeSide)
        imageAttachment.bounds = iconsSize

        let fullString = NSMutableAttributedString(string: name)
        fullString.append(NSAttributedString(attachment: imageAttachment))
        self.attributedText = fullString
        sizeToFit()
        
    }
    
    func setMute(text: String){
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = UIImage(systemName: "speaker.slash")?.withTintColor(.tertiaryLabel)
        let sizeSide: CGFloat = 10
        let iconsSize = CGRect(x: CGFloat(0),
                               y: (font.capHeight - sizeSide) / 2,
                               width: sizeSide,
                               height: sizeSide)
        imageAttachment.bounds = iconsSize

        let fullString = NSMutableAttributedString(string: text)
        fullString.append(NSAttributedString(attachment: imageAttachment))
        self.attributedText = fullString
    }
    
    func setSeenLbl(text: String){
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = UIImage(systemName: "checkmark.circle")?.withTintColor(textColor)
        let sizeSide: CGFloat = 12
        let iconsSize = CGRect(x: CGFloat(0),
                               y: (font.capHeight - sizeSide) / 2,
                               width: sizeSide,
                               height: sizeSide)
        imageAttachment.bounds = iconsSize

        let fullString = NSMutableAttributedString(string: text)
        fullString.append(NSAttributedString(attachment: imageAttachment))
        self.attributedText = fullString
    }
    
    func setArrow(name: String){
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = UIImage(systemName: "chevron.compact.right")?.withTintColor(textColor)
        let sizeSide: CGFloat = 10
        let iconsSize = CGRect(x: CGFloat(0),
                               y: (font.capHeight - sizeSide) / 2,
                               width: sizeSide,
                               height: sizeSide)
        imageAttachment.bounds = iconsSize

        let fullString = NSMutableAttributedString(string: name)
        fullString.append(NSAttributedString(attachment: imageAttachment))
        self.attributedText = fullString
        sizeToFit()
        
    }
}

extension UIButton{
    func setVerified(name: String){
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = UIImage(systemName: "checkmark.seal.fill")?.withTintColor(UIColor(named: "LoadingColor")!)
        let sizeSide: CGFloat = 15
        let iconsSize = CGRect(x: CGFloat(0),
                               y: ((titleLabel?.font.capHeight ?? 14) - sizeSide) / 2,
                               width: sizeSide,
                               height: sizeSide)
        imageAttachment.bounds = iconsSize

        let fullString = NSMutableAttributedString(string: name)
        fullString.append(NSAttributedString(attachment: imageAttachment))
        self.titleLabel?.attributedText = fullString
        self.setAttributedTitle(fullString, for: .normal)
        sizeToFit()
    }
}

extension UIProgressView{
    func animateProgressBar(value: CGFloat){
        self.setProgress(Float(value), animated: true)
    }
}

extension Product{
    
    func getLink(progressView: UIProgressView?, completed: @escaping (URL?) -> ()){
        progressView?.animateProgressBar(value: 0.4)
        if link == nil{
            generateLink(progressView: progressView, completed: { link in
                self.link = link
                progressView?.animateProgressBar(value: 0.8)
                completed(link)
            })
        }
        else{
            completed(link)
        }
    }
    
    func getThumbnailURL(completed: @escaping (URL?) -> ()){
        guard let productUID = userInfo.uid else{
            completed(nil)
            return
        }
        let ref = Storage.storage().reference().child("Users/" + productUID + "/" + "Products/" + productID + "/" + "link_" + productID + ".png")
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
    
    func generateLink(progressView: UIProgressView?, completed: @escaping (URL?) -> ()){
        guard let productUID = userInfo.uid else{
            completed(nil)
            return
        }
        guard let link = URL(string: "https://thredapps.com/users/\(productUID)/product/\(productID)") else {
            completed(nil)
            return }
        let dynamicLinksDomainURIPrefix = "https://thred.thredapps.com"
        let linkBuilder = DynamicLinkComponents(link: link, domainURIPrefix: dynamicLinksDomainURIPrefix)
        linkBuilder?.iOSParameters = DynamicLinkIOSParameters(bundleID: "thred.Thred")
        linkBuilder?.androidParameters = DynamicLinkAndroidParameters(packageName: "com.example.android")
        linkBuilder?.iOSParameters?.appStoreID = "1506286170"
        var descriptionToAdd = ""
        var fullNameToAdd = ""
        
        if let description = description, !description.isEmpty{
            descriptionToAdd = " - \(description)"
        }
        if let fullName = userInfo.fullName{
            fullNameToAdd = "\(fullName)'s "
        }
        linkBuilder?.socialMetaTagParameters = DynamicLinkSocialMetaTagParameters()
        linkBuilder?.socialMetaTagParameters?.title = "\(fullNameToAdd)Thred post: \"\(name ?? "")\(descriptionToAdd)\""
        linkBuilder?.options = DynamicLinkComponentsOptions()
        linkBuilder?.options?.pathLength = .short
        getThumbnailURL(completed: { url in
            progressView?.animateProgressBar(value: 0.6)
            linkBuilder?.socialMetaTagParameters?.imageURL = url

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
     
    
    func sharePost(progressView: UIProgressView?){
        progressView?.animateProgressBar(value: 0.2)
        
        
        Analytics.logEvent("share_product", parameters: [
        "name": "Product Share",
        "full_text": "A product was shared with a Dynamic Link"
        ])
        
        getLink(progressView: progressView, completed: { url in
            guard let url = url else{return}
            progressView?.animateProgressBar(value: 1.0)
            guard let productName = all.tees.first(where: {$0.productCode == self.productType})?.templateDisplayName?.lowercased()
            else {return}
            var shareMessage = "Check out this \(productName) on Thred!"
            if self.userInfo.uid == pUserInfo.uid{
                shareMessage = "Check out my \(productName) on Thred!"
            }
            let activity = UIActivityViewController(
                  activityItems: [shareMessage, url],
                  applicationActivities: nil
                )
            
            UIApplication.topViewController()?.present(activity, animated: true, completion: nil)
            DispatchQueue.main.async {
                progressView?.setProgress(0.0, animated: false)
            }
        })
    }
    
}


