//
//  NotificationCell.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-03-15.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import ColorCompatibility

class NotificationCell: UITableViewCell{

    @IBOutlet weak var notifPic: UIImageView!
    @IBOutlet weak var nameBtn: UIButton!
    @IBOutlet weak var followBtn: UIButton!
    var notif: UserNotification!{
        didSet{
            if notifLbl.text.isEmpty || notifLbl.text == nil{
                setNotifMessage()
            }
            
            let name = notif?.userInfo?.fullName ?? ""
            let verified = notif?.userInfo?.verified ?? false

            setName(name: name, verified: verified)
        }
    }
    var salesProduct: ProductInCart!{
        didSet{
            if notifLbl.text.isEmpty || notifLbl.text == nil{
                guard let quantity = salesProduct.quantity else{return}
                guard let price = salesProduct.product.price else{return}
                notifLbl.text = "\(quantity) x \((price).formatPrice(addCurrency: salesProduct.currency?.shortenCurrency() ?? ""))"
            }
            let name = salesProduct.product?.userInfo.fullName ?? ""
            let verified = salesProduct.product?.userInfo.verified ?? false

            setName(name: name, verified: verified)
        }
    }
    @IBOutlet weak var notifLbl: UITextView!
    @IBOutlet weak var timestampLbl: UILabel!
    weak var vc: UIViewController!
    @IBOutlet weak var dpBtn: UIButton!
    
    @IBAction func toUser(_ sender: UIButton){
        let user = notif?.userInfo ?? salesProduct?.product?.userInfo

        if user?.uid == pUserInfo.uid{
            (vc as? SalesVC)?.tabBarController?.selectedIndex = 4
            return
        }
        (vc as? NotificationVC)?.selectedObject = user
        (vc as? SalesVC)?.selectedObject = user
        vc.performSegue(withIdentifier: "toFriend", sender: nil)
    }
    
    func setName(name: String?, verified: Bool){
        nameBtn.titleLabel?.text = name
        nameBtn.setTitle(name, for: .normal)
        
        if verified{
            nameBtn.setVerified(name: name ?? "")
        }
    }
    
    func checkFollow(){
        guard let uid = notif?.uid else{
            return}
        if !notif.shouldShowDP{
            followBtn.isHidden = true
            return
        }
        let following = pUserInfo.userFollowing
        let didFollow = following.contains(uid)
        updateFollowBtn(didFollow: didFollow, animated: false)
    }
    
    @IBAction func followUser(_ sender: UIButton?) {
        guard let notifVC = vc as? NotificationVC else{return}
        let following = pUserInfo.userFollowing
        guard let uid = notif.uid else{
            return}
        let didFollow = !following.contains(uid)
        updateFollowBtn(didFollow: didFollow, animated: true)
        notifVC.updateFollowInDatabase(friendInfo: notif.userInfo, didFollow: didFollow)
    }
    
    var headerActionBtnTitle: String = "Loading"

    
    func updateFollowBtn(didFollow: Bool, animated: Bool){
        var animationDuration = 0.0
        
        if animated{
            animationDuration = 0.2
        }
        if didFollow{
            headerActionBtnTitle = "Following"
            followBtn?.setTitleColor(.white, for: .normal)
            UIView.animate(withDuration: animationDuration, animations: {
                self.followBtn?.backgroundColor = UIColor(named: "LoadingColor")
            })
        }
        else{
            headerActionBtnTitle = "Follow"
            followBtn?.setTitleColor(.label, for: .normal)
            UIView.animate(withDuration: animationDuration, animations: {
                self.followBtn?.backgroundColor = .quaternarySystemFill
            })
        }
        followBtn?.titleLabel?.text = headerActionBtnTitle
        followBtn?.setTitle(headerActionBtnTitle, for: .normal)
    }
    
    func setNotifMessage(){
        
        guard let notif = notif, !notif.deleted else{return}
        
        if notif.notifType == "Follow"{
            notifLbl.text = "started following you"
            notifLbl.textColor = .secondaryLabel
        }
        else if notif.notifType == "Like"{
            notifLbl.text = "fluttered your post"
            notifLbl.textColor = .secondaryLabel
        }
        else if notif.notifType == "Buy"{
            guard let name = all.tees.first(where: {$0.productCode == notif.product?.productType})?.templateDisplayName.lowercased().capitalized
            else {return}
            notifLbl.text = "purchased your \(name)"
            notifLbl.textColor = UIColor(named: "ActiveColor")
        }
        else if notif.notifType == "Comment"{
            var commentText = "\(notif.commentMessage ?? "")"
            if notif.hasCommentPic ?? false{
                commentText.append(contentsOf: " <photo>")
            }
            notifLbl.text = "commented on your post: \(commentText)"
            notifLbl.textColor = .secondaryLabel
        }
        else if notif.notifType == "Mention"{
            var commentText = "\(notif.commentMessage ?? "")"
            if notif.hasCommentPic ?? false{
                commentText.append(contentsOf: " <photo>")
            }
            notifLbl.text = "mentioned you in a comment: \(commentText)"
            notifLbl.textColor = .secondaryLabel
        }
        else if notif.notifType == "Bio_Mention"{
            notifLbl.text = "mentioned you in their bio"
            notifLbl.textColor = .secondaryLabel
        }
        else if notif.notifType == "Post_Mention"{
            notifLbl.text = "mentioned you in their post"
            notifLbl.textColor = .secondaryLabel
        }
        else if notif.notifType.contains("Report"){
            if notif.notifType == "Report:Post"{
                notifLbl.text = "your post has been reported"
            }
            else{
                notifLbl.text = "your account has been reported"
            }
            notifLbl.textColor = .systemRed
        }
    }
    
    override func layoutSubviews() {
        followBtn.layer.cornerRadius = followBtn.frame.height / 8
    }
    
    @IBOutlet weak var removedNotifView: UIView!
    var isDP: Bool = false{
        
        didSet{
            notifPic.setNeedsLayout()
            notifPic.layoutIfNeeded()
            if isDP{
                notifPic.layer.cornerRadius = notifPic.frame.height / 2
                notifPic.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
                notifPic.layer.borderWidth = notifPic.frame.height / 17.75
            }
            else{
                notifPic.layer.cornerRadius = notifPic.frame.height / 8
                notifPic.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
                notifPic.layer.borderWidth = 1
            }
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        notifPic.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
    }
    
    @IBAction func tappedDPBtn(_ sender: UIButton) {
        (vc as? SalesVC)?.showBankMessage(product: salesProduct, completed: {
            
        })
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        dpBtn.superview?.layer.cornerRadius = (dpBtn.superview?.frame.height ?? 0) / 2
        dpBtn.superview?.clipsToBounds = true
        dpBtn.superview?.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
        dpBtn.superview?.layer.borderWidth = (dpBtn.superview?.frame.height ?? 0) / 17.75
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
