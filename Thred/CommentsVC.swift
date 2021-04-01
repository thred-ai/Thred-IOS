//
//  CommentsVC.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-03-21.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import ColorCompatibility
import SDWebImage
import Firebase
import FirebaseFirestore
import PopupDialog
import FirebaseAnalytics

var uploadingComments = [String]()

class Comment{
    
    var timestamp: Date!
    var message: String!
    var timestampDiff: String!
    var commentID: String!
    var picID: String!
    var productID: String!
    var userInfo = UserInfo()
    
    
    init(timestamp: Date!, message: String!, commentID: String!, userInfo: UserInfo, picID: String!, productID: String!) {
        self.timestamp = timestamp
        self.message = message
        self.commentID = commentID
        self.userInfo = userInfo
        self.picID = picID
        self.productID = productID
    }
    
    convenience init() {
        self.init(timestamp: nil, message: nil, commentID: nil, userInfo: UserInfo(), picID: nil, productID: nil)
    }
}


class CommentsVC: UIViewController, UITextViewDelegate, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate {
    
    var imagesToUpload = [UIImage]()
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imagesToUpload.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoDisplayCell", for: indexPath) as? PhotoDisplayCell
        cell?.photoImgView.setImage(imagesToUpload[indexPath.item], for: .normal)
        cell?.photoImgView.setRadiusWithShadow()
        
        return cell!
    }
    
    lazy var swiper: UIPanGestureRecognizer = {
       
        let gesture = UIPanGestureRecognizer()
        gesture.addTarget(self, action: #selector(checkSwipe(_:)))
        return gesture
    }()
    
    @objc func checkSwipe(_ sender: UIPanGestureRecognizer){
        
        if sender.state == .began || sender.state == .changed {
            let translation = sender.translation(in: zoomableView)
            if let view = sender.view{
                view.center.y += translation.y
                sender.setTranslation(CGPoint.zero, in: zoomableView)
            }
        }
        if sender.state == .ended{
            if self.zoomableView.frame.origin.y >= 100{
                
                print(self.zoomableView.frame.origin.y)
                //Switch for other app
                /*
                if let vc = self.getViewController(){
                    (vc as? EditProfileVC)?.hideProfileCam{}
                    (vc as? DesignViewController)?.closeCamera(nil)
                    (vc as? CommentsVC)?.closeCamera(nil)
                    (vc as? ChatVC)?.closeCamera(nil)
                }
                */
                hideZoomableView(sender)
                self.zoomableView.frame.origin.y = 0
            }
            else{
                UIView.animate(withDuration: 0.2, animations: {
                    self.zoomableView.frame.origin.y = 0
                }, completion: {finished in
                    if finished{
                        sender.setTranslation(CGPoint.zero, in: self.zoomableView)
                    }
                })
            }
        }
    }
    
    @objc func showFullImageMenu(_ sender: UIButton){

        let popup = PopupDialog(title: nil, message: nil, image: nil, buttonAlignment: .vertical, transitionStyle: .bounceUp, preferredWidth: self.view.frame.width, tapGestureDismissal: true, panGestureDismissal: true, hideStatusBar: true, completion: nil)
        let dialogAppearance = PopupDialogDefaultView.appearance()
        
        dialogAppearance.backgroundColor = .secondarySystemBackground
        // Create buttons
        
        // This button will not the dismiss the dialog
        let button = DefaultButton(title: "SAVE IMAGE", dismissOnTap: false) {
            let imageView = self.zoomableView.subviews.first as? UIImageView
            imageView?.image?.saveToPhotos(completion: { success in
                DispatchQueue.main.async {
                    popup.shake()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        popup.dismiss()
                    }
                }
            })
        }
        let cancelBtn = CancelButton(title: "DONE", dismissOnTap: true) {}
        cancelBtn.titleFont = UIFont(name: "NexaW01-Heavy", size: 16)
        cancelBtn.backgroundColor = .tertiarySystemBackground
        cancelBtn.setTitleColor(UIColor.secondaryLabel, for: .normal)
        
        button.titleFont = UIFont(name: "NexaW01-Heavy", size: 16)
        button.backgroundColor = .tertiarySystemBackground
        button.setTitleColor(UIColor(named: "LoadingColor"), for: .normal)
        
        popup.addButtons([button, cancelBtn])
     
        self.present(popup, animated: true, completion: {
            
        })
        
        
    }
    
    func showZoomableView(sender: UIButton){
        zoomableView.isHidden = false
        textView.resignFirstResponder()
        self.navigationItem.leftBarButtonItem?.isEnabled = false
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        self.openedBtn = sender
        let imageView = zoomableView.subviews.first as? UIImageView
        imageView?.frame = sender.globalFrame!
        imageView?.contentMode = .scaleAspectFill
        imageView?.image = nil
        imageView?.image = sender.imageView?.image
        zoomableView.alpha = 0.0
        zoomableView.backgroundColor = .clear
        self.navigationController?.setNavigationBarHidden(true, animated: true)

        UIView.animate(withDuration: 0.2, animations: {
            self.zoomableView.alpha = 1.0
            imageView?.frame = CGRect(x: 0, y: 0, width: self.zoomableView.frame.width, height: self.zoomableView.frame.height)
            imageView?.contentMode = .scaleAspectFit
        }, completion: { finished in
            if finished{
                self.zoomableView.backgroundColor = UIColor.black.withAlphaComponent(0.90)
            }
        })
    }
    
    var openedBtn: UIButton!
    
    @objc func hideZoomableView(_ sender: Any){
        zoomableView.alpha = 1.0
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.navigationItem.leftBarButtonItem?.isEnabled = true
        let imageView = zoomableView.subviews.first as? UIImageView
        zoomableView.backgroundColor = .clear
        UIView.animate(withDuration: 0.2, animations: {
            imageView?.contentMode = .scaleAspectFill
            imageView?.frame = self.openedBtn.globalFrame!
            self.zoomableView.alpha = 0.0
        }, completion: { finished in
            if finished{
                self.openedBtn = nil
                self.zoomableView.isHidden = true
            }
        })
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
            }) { _ in}
        }
    }
    
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        
        switch gesture.state {
        case .began, .changed:
            let translation = gesture.translation(in: self.zoomableView)
            gesture.view?.center = CGPoint(x: gesture.view!.center.x + translation.x, y: gesture.view!.center.y + translation.y)
            gesture.setTranslation(.zero, in: self.zoomableView)
            break;
        default:
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
                gesture.view?.center = self.zoomableView.center
                gesture.setTranslation(.zero, in: self.zoomableView)
            }) { _ in}
            break
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return true
    }
    
    lazy var zoomableView: UIView = {
        
        let view = UIView.init(frame: self.view.frame)
        view.backgroundColor = UIColor.black.withAlphaComponent(0.90)
        let tapper = UITapGestureRecognizer.init(target: self, action: #selector(hideZoomableView(_:)))
        view.addGestureRecognizer(tapper)
        view.addGestureRecognizer(swiper)

        let imageView = UIImageView.init(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        imageView.center = view.center
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handleZoom(_:)))
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.minimumNumberOfTouches = 2
        pan.maximumNumberOfTouches = 2
        pan.delegate = self
        pinch.delegate = self
        imageView.addGestureRecognizer(pinch)
        imageView.addGestureRecognizer(pan)
        view.addSubview(imageView)
        
        let doneZoomingBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        doneZoomingBtn.setImage(UIImage(nameOrSystemName: "xmark", systemPointSize: 18, iconSize: 9), for: .normal)
        doneZoomingBtn.tintColor = UIColor(named: "LoadingColor")
        doneZoomingBtn.frame.origin.y = self.view.safeAreaInsets.top + doneZoomingBtn.frame.height
        doneZoomingBtn.addTarget(self, action: #selector(hideZoomableView(_:)), for: .touchUpInside)
        doneZoomingBtn.setRadiusWithShadow()
        
        let saveMenuBtn = UIButton(frame: CGRect(x: view.frame.maxX - 50, y: 0, width: 50, height: 50))
        saveMenuBtn.setImage(UIImage(nameOrSystemName: "ellipsis", systemPointSize: 18, iconSize: 9), for: .normal)
        saveMenuBtn.tintColor = UIColor(named: "LoadingColor")
        saveMenuBtn.frame.origin.y = self.view.safeAreaInsets.top + doneZoomingBtn.frame.height
        saveMenuBtn.addTarget(self, action: #selector(showFullImageMenu(_:)), for: .touchUpInside)
        saveMenuBtn.setRadiusWithShadow()
        
        view.addSubview(doneZoomingBtn)
        view.addSubview(saveMenuBtn)

        return view
    }()
    

    @IBOutlet weak var bottomBar: UIView!
    @IBOutlet weak var bottomBarHeight: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    fileprivate var keyBoardHeight: CGFloat = 0
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var bottomBarInnerView: UIView!
    var post: Product!
    var comments = [Comment]()
    var selectedUser: UserInfo!
    var hashtagToOpen: Hashtag?
    var loadedUsers = [UserInfo]()
    var selectedComment: Comment!

    func sendText(){
        
        Analytics.logEvent("commented_on_design", parameters: [
            "name": "Commented Design",
            "full_text": "User commented on another design"
        ])
        
        //sender.isEnabled = false
        if (textView.text == nil || textView.text.isEmpty) && imagesToUpload.isEmpty{
            return
        }
        guard let uid = pUserInfo.uid else{return}
        guard let postUID = post.userInfo.uid else{return}
        let commentInServer = Firestore.firestore().collection("Users/" + postUID + "/Products/" + post.productID + "/Comments").document()

        let hasPic = !imagesToUpload.isEmpty
        
        var data = [
            
            "product_id" : post.productID,
            "creator_uid" : postUID,
            "uid" : uid,
            "is_adding" : true,
            "tagged" : [],
            "comment_id" : commentInServer.documentID,
            "has_pic" : hasPic
        ] as [String : Any]
        
        
        let comment = Comment(timestamp: Date(), message: nil, commentID: commentInServer.documentID, userInfo: pUserInfo, picID: nil, productID: post.productID)
        
        if let text = textView.text?.prepared(), !text.isEmpty{
            data["message"] = text
            comment.message = text
        }
        
        if hasPic{
            comment.picID = commentInServer.documentID
        }
        
        cache.storeImage(toMemory: imagesToUpload.first, forKey: "cm_\(commentInServer.documentID)")
        
        self.comments.insert(comment, at: 0)
        uploadingComments.append(commentInServer.documentID)
        let indexPath = IndexPath(row: 0, section: 0)
        tableView.performBatchUpdates({
            tableView.insertRows(at: [indexPath], with: .none)
        }, completion: { finished in
            if finished{
                self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
            }
        })
        
        
        textView.text.removeAll()
        imagesToUpload.removeAll()

        textViewDidChange(textView)
        reloadChosenPhotoCollectionView(clear: true)
        //sender.isEnabled = true
        post.comments += 1

        checkAuthStatus {
            self.checkToUploadImage(uid: self.post.userInfo.uid!, imgID: commentInServer.documentID, productID: self.post.productID){
                Functions.functions().httpsCallable("updateComment").call(data, completion: { result, error in
                    uploadingComments.removeAll(where: {$0 == commentInServer.documentID})
                    if let index = self.comments.firstIndex(where: {$0.commentID == commentInServer.documentID}){
                        self.tableView.performBatchUpdates({
                            self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                        }, completion: nil)
                    }
                    if let err = error{
                        self.post.comments -= 1
                        print(err.localizedDescription)
                    }
                    else{
                        print(result ?? "")
                    }
                })
            }
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        cameraRollCollectionView.hidePhotosCollectionView {
            
        }
    }
    
    func checkToUploadImage(uid: String, imgID: String, productID: String, completed: @escaping () -> ()){
        guard let image = cache.imageFromMemoryCache(forKey: "cm_\(imgID)"), let data = (image.jpegData(compressionQuality: 1.0))
        else{
            completed()
            return
        }

        let ref = Storage.storage().reference().child("Users/" + uid + "/Products/" + productID + "/Comments/" + "cm_" + imgID + ".jpeg")
        ref.putData(data, metadata: nil, completion: { metaData, error in
            if let err = error{
                completed()
                print(err.localizedDescription)
            }
            else{
                completed()
            }
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
        textView.resignFirstResponder()
    }

    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            sendText()
            return false
        }
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        textView.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        textView.returnKeyType = .send
        self.chosenPhotoCollectionView.register(UINib(nibName: "PhotoDisplayCell", bundle: nil), forCellWithReuseIdentifier: "PhotoDisplayCell")
        if !self.view.subviews.contains(self.zoomableView){
            self.view.addSubview(self.zoomableView)
            self.zoomableView.isHidden = true
        }

        chosenPhotoCollectionView.delegate = self
        chosenPhotoCollectionView.dataSource = self
        chosenPhotoCollectionView.superview?.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
        navigationController?.delegate = self

        initialWidth = textView.frame.width
        initialHeight = textView.frame.height
        previousHeight = textView.frame.height
        textViewDidChange(textView)
        bottomBarInnerView.layer.cornerRadius = bottomBarInnerView.frame.height / 4
        bottomBarInnerView.clipsToBounds = true
        bottomBarInnerView.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
        bottomBarInnerView.layer.borderWidth = 1.5
        setPlaceholder(textView: textView, textColor: .tertiaryLabel)
        view.addSubview(taggingTableView)
        taggingTableView.isHidden = true
        
        reloadChosenPhotoCollectionView(clear: true)

        if selectedComment != nil{
            self.comments.append(selectedComment)
            DispatchQueue.main.async {
                self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            }
        }
        
        isLoading = true
        guard let userUID = pUserInfo.uid else{return}
        checkAuthStatus {
            self.refreshLists(userUID: userUID){
                self.getComments(isRefreshing: true){
                    self.isLoading = false
                }
            }
        }
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        
        if viewController != self{
            let vcs = navigationController.viewControllers.filter({$0 is FullProductVC || $0 is UserVC || $0 is FriendVC || $0 is FeedVC})
            print(vcs)
            for viewController in vcs{
                
                switch viewController{
                case let vc as FullProductVC:
                    vc.fullProduct.comments = post.comments
                    vc.tableView.reloadRows(indexPaths: [IndexPath(row: 0, section: 0)]){}
                case let vc as UserVC:
                    guard let index = vc.loadedProducts.firstIndex(where: {$0.productID == post.productID}) else{return}
                    vc.loadedProducts[index].comments = post.comments
                case let vc as FriendVC:
                    guard let index = vc.loadedProducts.firstIndex(where: {$0.productID == post.productID}) else{return}
                    vc.loadedProducts[index].comments = post.comments
                case let vc as FeedVC:
                    guard let index = vc.loadedProducts.firstIndex(where: {$0.productID == post.productID}) else{return}
                    vc.loadedProducts[index].comments = post.comments
                    vc.tableView.reloadRows(indexPaths: [IndexPath(row: index, section: 0)]){}
                default:
                    return
                }
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        initialWidth = textView.frame.width
        initialHeight = textView.frame.height
        previousHeight = textView.frame.height
    }
    
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if tableView == self.tableView{
            return UITableView.automaticDimension
        }
        else{
            return 55
        }
    }
    
    var isLoading = false

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if tableView.contentOffset.y >= (tableView.contentSize.height - tableView.frame.size.height) / 2{
            print("fromScroll")
            if !isLoading, canLoadMore{
                isLoading = true
                getComments(isRefreshing: false){
                    self.isLoading = false
                }
            }
        }
    }
    
    var canLoadMore = false
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        let translation = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        if translation.y > 0 {
            canLoadMore = false
            // swipes from top to bottom of screen -> down
        } else {
            canLoadMore = true
            // swipes from bottom to top of screen -> up
        }
    }
    
    
    
    var lastDocument: DocumentSnapshot!
    
    func getComments(isRefreshing: Bool, completed: @escaping () -> ()){
        
        var query: Query! = nil
        guard let postUID = post.userInfo.uid else{completed(); return}

        if isRefreshing{
            query = Firestore.firestore().collection("Users").document(postUID).collection("Products/\(post.productID)/Comments").limit(to: 15).order(by: "Timestamp", descending: false)
        }
        else{
            guard let last = lastDocument else{return}
            query = Firestore.firestore().collection("Users").document(postUID).collection("Products/\(post.productID)/Comments").limit(to: 15).order(by: "Timestamp", descending: false).start(afterDocument: last)
        }
        query.getDocuments(completion: { (snapDocuments, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                completed()
                return
            }
            else{
                if snapDocuments?.isEmpty ?? true{
                    completed()
                }
                else{
                    guard let snaps = snapDocuments?.documents else
                    {return}
                    self.lastDocument = snaps.last
                    for snap in snaps{
                        
                        let uid = snap["UID"] as! String
                        if self.comments.contains(where: {$0.commentID == snap.documentID}) || (pUserInfo.usersBlocking.contains(uid)){
                            continue
                        }
                        let timestamp = (snap["Timestamp"] as? Timestamp)?.dateValue()
                        let message = snap["Message"] as? String
                        let productID = snap["Product_ID"] as? String

                        
                        let userInfo = UserInfo(uid: uid, dp: nil, dpID: nil, username: nil, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: [], profileLink: nil, verified: nil)
                        
                        let comment = Comment(timestamp: timestamp, message: message, commentID: snap.documentID, userInfo: userInfo, picID: nil, productID: productID)
                        
                        if snap["Has_Pic"] as? Bool ?? false{
                            comment.picID = snap.documentID
                        }
                        self.comments.append(comment)
                        
                        self.tableView.performBatchUpdates({
                            self.tableView.insertRows(at: [IndexPath(row: self.comments.count - 1, section: 0)], with: .none)
                        }, completion: { finished in
                            if finished{
                                if snap == snaps.last{
                                    completed()
                                }
                            }
                        })
                    }
                }
            }
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.tableView{
            return comments.count
        }
        else{
            return loadedUsers.count
        }
    }
    
    var downloadingProfiles = [String]()
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == self.tableView{
            let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath) as? CommentCell
            cell?.backgroundColor = .systemBackground
            let comment = comments[indexPath.row]
            cell?.comment = comment
            cell?.fullNameLbl.text = nil
            cell?.fullNameLbl.attributedText = nil
            cell?.usernameLbl.text = nil
            cell?.profilePicture.image = nil
            cell?.spinner.isHidden = true
            cell?.alpha = 1.0
            guard let uid = comment.userInfo.uid else{return cell!}
            guard let userUID = pUserInfo.uid else{return cell!}
            
            if let attr = cell?.messageView.attributedText.mutableCopy() as? NSMutableAttributedString{
                attr.removeAttribute(NSAttributedString.Key.link, range: NSMakeRange(0, attr.length))
                attr.setAttributes([NSAttributedString.Key.font : UIFont(name: "NexaW01-Regular", size: cell?.messageView.font?.pointSize ?? 16)!], range: NSMakeRange(0, attr.length))
                cell?.messageView.attributedText = attr
            }
            cell?.messageView.text = nil
            cell?.vc = self
            cell?.messageView.text = comment.message
            cell?.messageView.addLinks(isNotification: false, prefix: "@")
            cell?.messageView.addLinks(isNotification: false, prefix: "#")

            cell?.commentImgViewBack.isHidden = comment.picID == nil
            if let id = comment.picID{
                downloadCommentImg(cp: cell?.circularProgress, uid: post.userInfo.uid ?? "", productID: comment.productID, imgID: id) { img in
                    if let index = self.comments.firstIndex(where: {$0.commentID == comment.commentID}){
                        if let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? CommentCell{
                            cell.circularProgress.isHidden = true
                            cell.commentImgView.imageView?.image = img
                            cell.commentImgView.setImage(img, for: .normal)
                        }
                    }
                }
            }
            
            tableView.checkCommentTimes(comment: comment, timestampLbl: cell?.timestampLbl)

            if comment.userInfo.usersBlocking.contains(userUID){
                cell?.alpha = 0.2
            }
            if uploadingComments.contains(comment.commentID){
                cell?.spinner.isHidden = false
                cell?.spinner.animate()
            }
            
            if comment.userInfo.username != nil{
                cell?.fullNameLbl.text = comment.userInfo.fullName ?? "null"
                if comment.userInfo.verified{
                    cell?.fullNameLbl.setVerified(name: comment.userInfo.fullName ?? "")
                }
                cell?.usernameLbl.text = "@\(comment.userInfo.username ?? "null")"
                if let dp = comment.userInfo.dp{
                    cell?.profilePicture.image = UIImage(data: dp)
                }
            }
            else{
                switch comments.compactMap({$0.userInfo}).first(where: {$0.uid == uid}){
                case let same:
                    if same?.username != nil, same?.dp != nil{
                        if same != nil{
                            comment.userInfo.username = same?.username
                            comment.userInfo.fullName = same?.fullName
                            comment.userInfo.dpID = same?.dpID
                            comment.userInfo.bio = same?.bio
                            comment.userInfo.dp = same?.dp
                            comment.userInfo.usersBlocking = same?.usersBlocking ?? []
                            comment.userInfo.verified = same?.verified ?? false
                            cell?.fullNameLbl.text = comment.userInfo.fullName ?? "null"
                            if comment.userInfo.verified{
                                cell?.fullNameLbl.setVerified(name: comment.userInfo.fullName ?? "")
                            }
                            cell?.usernameLbl.text = "@\(comment.userInfo.username ?? "null")"
                            if let dp = comment.userInfo.dp{
                                cell?.profilePicture.image = UIImage(data: dp)
                            }
                        }
                        else{
                            fallthrough
                        }
                    }
                    else{
                        fallthrough
                    }
                default:
                    if !downloadingProfiles.contains(uid){
                        downloadingProfiles.append(uid)
                        self.downloadUserInfo(uid: uid, userVC: nil, feedVC: nil, downloadingPersonalDP: false, doNotDownloadDP: false, userInfoToUse: comment.userInfo, queryOnUsername: false, completed: { uid, fullName, username, dpUID, notifID, bio, img, userFollowing, usersBlocking, postNotifs, postCount, followersCount, followingCount, verified  in
                            self.downloadingProfiles.removeAll(where: {$0 == uid})
                            
                            if usersBlocking.contains(userUID){
                                cell?.alpha = 0.2
                            }
                            comment.userInfo.username = username ?? "null"
                            comment.userInfo.fullName = fullName ?? "null"
                            comment.userInfo.dpID = dpUID
                            comment.userInfo.bio = bio
                            comment.userInfo.dp = img
                            comment.userInfo.usersBlocking = usersBlocking
                            comment.userInfo.postCount = postCount
                            comment.userInfo.followerCount = followersCount
                            comment.userInfo.followingCount = followingCount
                            comment.userInfo.verified = verified ?? false
                            cell?.fullNameLbl.text = fullName ?? "null"
                            cell?.usernameLbl
                                .text = "@\(username ?? "null")"
                            
                            if let dp = comment.userInfo.dp{
                                cell?.profilePicture.image = UIImage(data: dp)
                            }
                            
                            if let indices = tableView.indexPathsForVisibleRows{
                                for index in indices{
                                    if self.comments[index.row].userInfo.uid == uid{
                                        
                                        self.comments[index.row].userInfo = comment.userInfo
                                        
                                        
                                        if let cell = tableView.cellForRow(at: index){
                                            switch cell{
                                            case let c as CommentCell:
                                                c.fullNameLbl.text = fullName
                                                if comment.userInfo.verified{
                                                    c.fullNameLbl.setVerified(name: comment.userInfo.fullName ?? "")
                                                }
                                                c.usernameLbl.text = "@" + (username ?? "null")
                                                if let dp = comment.userInfo.dp{
                                                    c.profilePicture.image = UIImage(data: dp)
                                                }
                                            default:
                                                continue
                                            }
                                        }
                                    }
                                }
                            }
                        })
                    }
                }
            }
            return cell!
        }
        else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "search", for: indexPath) as? SearchUserTableViewCell
            cell?.fullnameLbl.text = nil
            cell?.fullnameLbl.attributedText = nil
            cell?.usernameLbl.text = nil
            let user = self.loadedUsers[indexPath.row]
            cell?.userImageView.image = nil

            if let dp = user.dp{
                cell?.spinner.isHidden = true
                cell?.userImageView.image = UIImage(data: dp)
            }
            else{
                cell?.spinner.isHidden = false
                cell?.spinner.animate()
            }
            cell?.usernameLbl.text = "@" + (user.username ?? "null")
            cell?.fullnameLbl.text = user.fullName
            if user.verified{
                cell?.fullnameLbl.setVerified(name: user.fullName ?? "")
            }
            return cell!
        }
    }
    
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.hideCenterBtn()
        setKeyBoardNotifs()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        textView.becomeFirstResponder()
        if selectedComment != nil{
            if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)){
                UIView.animate(withDuration: 0.25, animations: {
                    cell.backgroundColor = .tertiarySystemGroupedBackground
                })
            }
        }
    }
    
    
    func setKeyBoardNotifs(){
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        
        if (notification.userInfo?[UIResponder.keyboardIsLocalUserInfoKey] as? Bool ?? true){
            textView.scrollRangeToVisible(NSRange(location: 0, length: 0))
            UIView.animate(withDuration: 0.2, animations: {
                self.bottomBar.transform = CGAffineTransform.identity
                self.chosenPhotoCollectionView.superview?.transform = CGAffineTransform.identity
                self.tableView.contentInset.bottom = 0
                self.tableView.verticalScrollIndicatorInsets.bottom = 0
            })
        }
    }
    
    lazy var cameraView: CameraView = {
        let cameraView = CameraView.init(frame: CGRect(x: 0, y: bottomBar.frame.maxY, width: view.frame.width, height: view.frame.height))
        cameraView.bottomBar.frame.size.height = cameraView.bottomBar.frame.height + view.safeAreaInsets.bottom
        cameraView.bottomBar.frame.origin.y = cameraView.frame.height - (cameraView.bottomBar.frame.height)
        cameraView.dismissBtn.addTarget(self, action: #selector(closeCamera(_:)), for: .touchUpInside)
        view.addSubview(cameraView)
        return cameraView
        
    }()
    
    @objc func closeCamera(_ sender: UIButton?){
        bottomBar.isHidden = false

        cameraView.hideCameraAnimate(viewToCarry: bottomBar) {
            self.cameraView.resetDisplayImage()
        }
    }
    
    @objc func usePhoto(_ sender: UIButton?){
        
        var selectedImage: UIImage!
        
        if !cameraView.isHidden{
            selectedImage = cameraView.selectedImage
            hideCameraAndSwitchToKeyboard()
        }
        else if !cameraRollCollectionView.isHidden{
            selectedImage = cameraRollCollectionView.selectedImage
            hideCameraRollAndSwitchToKeyboard()
        }
        
        imagesToUpload.removeAll()
        
        
        let image = selectedImage ?? UIImage()

        imagesToUpload.append(image)
        
        DispatchQueue.main.async {
            self.reloadChosenPhotoCollectionView(clear: false)
        }
        
        
        //doneBtn.isHidden = false
        
        
    }
    
    lazy var cameraRollCollectionView: PhotosView = {
        
        let y = view.frame.midY
        let collectionView = PhotosView.init(frame: CGRect(x: 0, y: view.frame.height - y, width: view.frame.width, height: y))
        
        view.addSubview(collectionView)
        collectionView.isHidden = true

        return collectionView
    }()
    
    @IBOutlet weak var chosenPhotoCollectionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var chosenPhotoCollectionView: UICollectionView!
    
    func reloadChosenPhotoCollectionView(clear: Bool){
        switch clear{
        case true:
            chosenPhotoCollectionViewHeight.constant = 0
        case false:
            chosenPhotoCollectionViewHeight.constant = 65
        }
        DispatchQueue.main.async {
            self.chosenPhotoCollectionView.reloadData()
        }
    }
    
    @IBAction func configurePhotos(_ sender: UIButton) {
        if self.cameraRollCollectionView.isHidden{
            sender.tintColor = .cyan
            //exitTapper.isEnabled = true
            self.textView.resignFirstResponder()
            showCamRoll(sender: sender)
        }
        else{
            sender.tintColor = UIColor(named: "LoadingColor")
            cameraRollCollectionView.animatehideCameraRoll(viewToCarry: self.bottomBar, backgroundView: view, tableView: nil){
            }
        }
    }
    
    fileprivate func hideCameraRollAndSwitchToKeyboard(){
        DispatchQueue.main.async {
            UIView.setAnimationsEnabled(false)
            self.textView.becomeFirstResponder()
            UIView.setAnimationsEnabled(true)
            self.openPhotosBtn.tintColor = UIColor(named: "LoadingColor")
            self.cameraRollCollectionView.hidePhotosCollectionView {
            }
        }
    }
    
    fileprivate func hideCameraAndSwitchToKeyboard(){
        DispatchQueue.main.async {
            
            self.bottomBar.isHidden = false
            self.cameraView.hideCameraAnimate(viewToCarry: self.bottomBar) {
                self.cameraView.resetDisplayImage()
                self.textView.becomeFirstResponder()
            }
        }
    }
    
    func showCamRoll(sender: UIButton?){
        let y = view.frame.midY
        let btnMaxY = bottomBar.frame.maxY
        bottomBar.transform = CGAffineTransform(translationX: 0, y: (y - btnMaxY))
        cameraRollCollectionView.showCameraRollAnimate(completed: { openedRoll in
            if !openedRoll{
                self.cameraRollCollectionView.animatehideCameraRoll(viewToCarry: self.bottomBar, backgroundView: self.view, tableView: self.tableView){
                }
            }
        })
    }
    
    @IBAction func openCamera(_ sender: UIButton) {
        //self.animateOptionMenuCameraRollButton(didOpen: false)
        cameraView.isHidden = true
        UIView.setAnimationsEnabled(false)
        textView.resignFirstResponder()
        UIView.setAnimationsEnabled(true)
        cameraRollCollectionView.hidePhotosCollectionView {
            openPhotosBtn.tintColor = UIColor(named: "LoadingColor")
            cameraView.isHidden = false
            let cameraBtnMaxY = bottomBar.frame.maxY
            cameraView.openCameraAnimate(backgroundView: view, viewToCarry: bottomBar, viewMaxY: cameraBtnMaxY){
                self.bottomBar.isHidden = true
            }
        }
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {

        let bottomPadding = self.view.safeAreaInsets.bottom

        if textView.isFirstResponder{
            if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                if (notification.userInfo?[UIResponder.keyboardIsLocalUserInfoKey] as? Bool ?? true){
                    let keyboardRectangle = keyboardFrame.cgRectValue
                    let keyboardHeight = keyboardRectangle.height
                    self.keyBoardHeight = keyboardHeight
                    UIView.animate(withDuration: 0.2, animations: {
                        self.bottomBar.transform = CGAffineTransform(translationX: 0, y: -(keyboardHeight - bottomPadding))
                        self.chosenPhotoCollectionView.superview?.transform = CGAffineTransform(translationX: 0, y: -(keyboardHeight - bottomPadding))

                        self.tableView.contentInset.bottom = keyboardHeight - bottomPadding
                        self.tableView.verticalScrollIndicatorInsets.bottom = keyboardHeight - bottomPadding
                    }, completion: { finished in
                        if finished{}
                    })
                }
            }
        }
    }
    
    @IBOutlet weak var openPhotosBtn: UIButton!
    
    @IBOutlet weak var openCameraBtn: UIButton!
    
    
    
    
    var initialWidth = CGFloat()
    var initialHeight = CGFloat()
    var previousHeight = CGFloat()
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        return false
    }
    
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
        
        let check = (self.view.frame.height - self.view.frame.height / 2) - (textView.sizeThatFits(CGSize(width: initialWidth, height: CGFloat.greatestFiniteMagnitude)).height)
        print(check)
        if check > 100{
            textView.isScrollEnabled = false
            let size = textView.sizeThatFits(CGSize(width: initialWidth, height: CGFloat.greatestFiniteMagnitude)).height
            self.bottomBarHeight.constant = size + 50
            DispatchQueue.main.async {
                if self.bottomBarHeight.constant > self.previousHeight + 50{
                    let difference = self.bottomBarHeight.constant - (self.previousHeight - 50)
                    self.tableView.contentOffset.y -= difference
                }
                else if self.bottomBarHeight.constant < self.previousHeight + 50{
                    let difference = (self.previousHeight + 50) - self.bottomBarHeight.constant
                    self.tableView.contentOffset.y += difference
                }
            }
            self.previousHeight = self.bottomBarHeight.constant - 50
        }
        else{
            let string = textView.text.replacingOccurrences(of: " ", with: "")
            if string.count > 1000{
                textView.text.removeLast(textView.text.count - 1000)
            }
            if !textView.isScrollEnabled{
                DispatchQueue.main.async {
                    textView.isScrollEnabled = true
                }
            }
        }
        
        bottomBar.setNeedsLayout()
        bottomBar.layoutIfNeeded()

        if let lastText = textView.text.components(separatedBy: " ").last{
            if lastText.starts(with: "@"){
                let username = String(lastText.dropFirst())
                searchTaggingView(searchText: username)
            }
            else{
                if !taggingTableView.isHidden{
                    setTag(index: nil)
                    resetTaggingTableView()
                }
            }
        }
        else{
            if !taggingTableView.isHidden{
                resetTaggingTableView()
            }
        }
    }
    
    
    
    func searchTaggingView(searchText: String){
        
        
        if self.taggingTableView.isHidden{
            self.taggingTableView.isHidden = false
            self.taggingTableView.frame.origin.y = bottomBar.frame.origin.y + bottomBar.transform.ty
            let height = bottomBar.frame.origin.y - 45
            print(height)
            
            
            self.taggingTableView.frame.size.height = height
            
            UIView.animate(withDuration: 0.2, animations: {
                self.taggingTableView.frame.origin.y = 45
            })
        }
        
        if searchText == ""{
            loadedUsers.removeAll()
            taggingTableView.reloadData()
            //self.getFollowers()
        }
        else{
            //searchBar.isLoading = true
            let lowerCaseSearchText = searchText.lowercased()
            Firestore.firestore().collection("Users").whereField("Username", isGreaterThanOrEqualTo: lowerCaseSearchText).whereField("Username", isLessThanOrEqualTo: lowerCaseSearchText + "\u{f8ff}").limit(to: 8).getDocuments(completion: { query, error in
                
                //searchBar.isLoading = false
                if error != nil{
                    print(error?.localizedDescription ?? "null")
                }
                else{
                    if let documents = query?.documents{
                        if documents.count != 0{
                            print(documents)
                            for document in documents{
                                let uid = document.documentID
                                let username = document["Username"] as? String
                                let fullname = document["Full_Name"] as? String
                                let bio = document["Bio"] as? String
                                let dpLink = document["ProfilePicID"] as? String
                                let userFollowing = document["Following_List"] as? [String]
                                let followerCount = document["Followers_Count"] as? Int
                                let followingCount = document["Following_Count"] as? Int
                                let postCount = document["Posts_Count"] as? Int
                                let usersBlocking = document["Users_Blocking"] as? [String]
                                let verified = document["Verified"] as? Bool ?? false
                                if pUserInfo.usersBlocking.contains(uid){
                                    if document == documents.first, documents.count < 1{

                                        self.loadedUsers.removeAll()
                                    }
                                    continue
                                }
                                else{
                                    if document == documents.first{
                                        self.loadedUsers.removeAll()
                                    }
                                }
                                
                                let user = UserInfo(uid: uid, dp: nil, dpID: dpLink, username: username, fullName: fullname, bio: bio, notifID: nil, userFollowing: userFollowing ?? [], userLiked: [], followerCount: followerCount ?? 0, postCount: postCount ?? 0, followingCount: followingCount ?? 0, usersBlocking: usersBlocking ?? [], profileLink: nil, verified: verified)

                                self.loadedUsers.append(user)
                                self.taggingTableView.reloadData()
                                
                                if uid == pUserInfo.uid{
                                    user.dp = pUserInfo.dp
                                    user.dpID = pUserInfo.dpID
                                    continue
                                }
                                let infoMapped = self.comments.compactMap({$0.userInfo})
                                
                                if let same = infoMapped.first(where: {$0.uid == uid}), let dp = same.dp, let dpID = same.dpID{
                                    user.dp = dp
                                    user.dpID = dpID
                                    continue
                                }
                                let ref = Storage.storage().reference()
                                ref.child("Users/" + uid + "/" + "profile_pic-" + (dpLink ?? "null") +
                                    ".jpeg").downloadURL(completion: { url, error in
                                    if error != nil{
                                        print(error?.localizedDescription ?? "")
                                    }
                                    else{
                                        downloader.requestImage(with: url, options: [.scaleDownLargeImages, .refreshCached], context: nil, progress: nil, completed: { (image, data, error, finished) in
                                            if error != nil{
                                                print(error?.localizedDescription ?? "")
                                                return
                                            }
                                            else{
                                                user.dp = data
                                                if let index = self.loadedUsers.firstIndex(where: {$0.uid == uid}){
                                                    self.taggingTableView.performBatchUpdates({
                                                        self.taggingTableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                                                    }, completion: nil)
                                                }
                                            }
                                        })
                                    }
                                })
                            }
                        }
                        else{
                            self.taggingTableView.reloadData() //No Results
                        }
                    }
                }
            })
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        if scrollView == self.tableView{
            if(velocity.y < 0) {
                print("Hide")
                if self.textView.isFirstResponder{
                    self.textView.resignFirstResponder()
                }
            } else {
                print("Unhide")
            }
        }
    }
    
    lazy var taggingTableView: UITableView = {
        let tableView = UITableView.init(frame: CGRect(x: 0, y: bottomBar.frame.origin.y, width: view.frame.width, height: 100))
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.95)
        tableView.register(UINib(nibName: "SearchUserTableViewCell", bundle: nil), forCellReuseIdentifier: "search")
        tableView.separatorStyle = .none
        
        return tableView
    }()
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == taggingTableView{
            setTag(index: indexPath.row)
            resetTaggingTableView()
        }
    }
    
    func setTag(index: Int?){
        var components = textView.text.components(separatedBy: " ")
        guard !components.isEmpty else{return}
        
        if let index = index{
            guard let username = loadedUsers[index].username else{return}
            components.removeLast()
            components.append("@\(username)")
            textView.text.removeAll()
            for component in components{
                textView.text.append("\(component) ")
            }
        }
    }
    
    func resetTaggingTableView(){
        loadedUsers.removeAll()
        taggingTableView.reloadData()
        taggingTableView.isHidden = true
    }
    
    var placeholderLabel = UILabel()

    
    func setPlaceholder(textView: UITextView, textColor: UIColor?){
        
        
        placeholderLabel.text = "Say something..."
        placeholderLabel.font = UIFont(name: "NexaW01-Regular", size: 15)
        placeholderLabel.sizeToFit()
        placeholderLabel.backgroundColor = UIColor.clear
        placeholderLabel.textColor = textColor
        
        if !textView.subviews.contains(placeholderLabel){
            textView.addSubview(placeholderLabel)
            placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
            placeholderLabel.centerYAnchor.constraint(equalTo: textView.centerYAnchor).isActive = true
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor,  constant: 5).isActive = true
            placeholderLabel.isHidden = !textView.text.isEmpty
        }
        
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        if tableView == self.tableView && comments.indices.contains(indexPath.row) && comments[indexPath.row].userInfo.username != nil{
            
            return true
        }
        return false
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        var actions = [UIContextualAction]()
        let reply = UIContextualAction(style: .normal, title: nil,
          handler: { (action, view, completionHandler) in
            if self.comments.indices.contains(indexPath.row), let username = self.comments[indexPath.row].userInfo.username{
                let text = self.textView.text ?? ""
                self.textView.text = "@\(username) \(text)"
                self.textViewDidChange(self.textView)
                completionHandler(true)
            }
        })
        
        reply.image = UIImage(systemName: "arrow.turn.down.left")
        reply.backgroundColor = UIColor.systemGray
        actions.append(reply)
        
        if self.comments.indices.contains(indexPath.row) && self.comments[indexPath.row].userInfo.uid == pUserInfo.uid || self.post.userInfo.uid == pUserInfo.uid{
            let delete = UIContextualAction(style: .destructive, title: nil,
              handler: { (action, view, completionHandler) in
                let comment = self.comments[indexPath.row]
                let message = self.comments[indexPath.row].message ?? ""
                self.comments.remove(at: indexPath.row)
                DispatchQueue.main.async {
                    self.tableView.performBatchUpdates({
                        self.tableView.deleteRows(at: [indexPath], with: .fade)
                    }, completion: nil)
                }
                self.deleteComment(comment: comment, message: message)
            })
            
            delete.image = UIImage(systemName: "trash")
            delete.backgroundColor = UIColor.red
            actions.append(delete)
        }
        
        let configuration = UISwipeActionsConfiguration(actions: actions)
        return configuration
        
        
    }
    
    func deleteComment(comment: Comment, message: String){
        
        guard let commentUID = comment.userInfo.uid else{return}
        guard let commentID = comment.commentID else{return}
        guard let postUID = post.userInfo.uid else{return}
        let hasPic = comment.picID != nil

        self.post.comments -= 1

        let data = [
            
            "product_id" : post.productID,
            "creator_uid" : postUID,
            "uid" : commentUID,
            "message" : message,
            "is_adding" : false,
            "tagged" : [],
            "comment_id" : commentID,
            "has_pic" : hasPic
            
        ] as [String : Any]
        checkAuthStatus {
            Functions.functions().httpsCallable("updateComment").call(data, completion: { result, error in
                if let err = error{
                    print(err.localizedDescription)
                    self.post.comments += 1
                }
                else{
                    print(result ?? "")
                }
            })
        }
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let friendVC = segue.destination as? FriendVC{
            friendVC.friendInfo = selectedUser
        }
        else if let colorSectionVC = segue.destination as? ColorSectionVC{
            colorSectionVC.hashtag = hashtagToOpen
        }
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }

}


extension UITableView{
    func reloadRows(indexPaths: [IndexPath], completed: @escaping () -> ()){
        self.performBatchUpdates({
            self.reloadRows(at: indexPaths, with: .none)
        }, completion: { finished in
            if finished{
                completed()
            }
        })
    }
}

extension UIViewController{
    
    func downloadCommentImg(cp: CircularProgress?, uid: String, productID: String, imgID: String, completed: @escaping (UIImage?) -> ()){
        cp?.isHidden = false

        if let img = cache.imageFromMemoryCache(forKey: "cm_\(imgID)"){
            DispatchQueue.main.async {
                completed(img)
            }
        }
        else{
            let ref = Storage.storage().reference().child("Users/" + uid + "/Products/" + productID + "/Comments/" + "cm_" + imgID + ".jpeg")

            ref.downloadURL(completion: { url, error in
                if error != nil{
                    print(error?.localizedDescription ?? "")
                    return
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
                          if finished{
                              if error != nil{
                                  print(error?.localizedDescription ?? "")
                                  return
                              }
                              else{
                                if let img = image{
                                    cache.storeImage(toMemory: img, forKey: "cm_\(imgID)")
                                    completed(img)
                                }
                            }
                        }
                    })
                }
            })
        }
    }
}

extension UIView {
    var globalFrame: CGRect? {
        let rootView = UIApplication.shared.windows.first?.rootViewController?.view
        return self.superview?.convert(self.frame, to: rootView)
    }
}
