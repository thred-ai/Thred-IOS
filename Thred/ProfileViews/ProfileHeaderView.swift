//
//  ProfileHeaderView.swift
//  Thred
//
//  Created by Arta Kouroshnia on 2019-11-02.
//  Copyright © 2019 Thred Apps Inc. All rights reserved.
//

import UIKit
import ColorCompatibility

class ProfileHeaderView: UIView, UITextViewDelegate{

    var selectedList: UserListType!
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    @IBAction func showMessage(_ sender: UIButton) {
        getViewController()?.showAuthMessage {
            
        }
    }
    
    @IBAction func toFollowingList(_ sender: UITapGestureRecognizer) {
        selectedList = .following
        getViewController()?.performSegue(withIdentifier: "toUserList", sender: nil)
    }
    
    @IBAction func toFollowerList(_ sender: UITapGestureRecognizer) {
        selectedList = .followers
        getViewController()?.performSegue(withIdentifier: "toUserList", sender: nil)
    }
    
    @IBAction func showPosts(_ sender: UITapGestureRecognizer) {
        
    }
    
    
    
    
    
    override func draw(_ rect: CGRect) {
    }
    @IBOutlet weak var optionBtn: UIButton!
    
    
    @IBOutlet weak var followingNum: UILabel!
    @IBOutlet weak var followerNum: UILabel!
    @IBOutlet weak var postNum: UILabel!
    
    @IBOutlet weak var emailNotSetView: UIButton!
    
    @IBOutlet weak var userContentView: UIView!
    @IBOutlet weak var fullnameLbl: UILabel!
    @IBOutlet weak var usernameLbl: UILabel!
    @IBOutlet weak var bioView: UITextView!
    @IBOutlet weak var actionBtn: UIButton!
    @IBOutlet weak var profileImgView: UIImageView!
    var headerActionBtnTitle: String = "Loading"
    var vc: UIViewController!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = UIColor.clear
        bioView.delegate = self
    }
    
    
    
    func clearAll(actionBtnTitle: String){
        usernameLbl.text = nil
        fullnameLbl.text = nil
        bioView.text = nil
        actionBtn.setTitle(actionBtnTitle, for: .normal)
        profileImgView.image = nil
        setNeedsLayout()
        layoutIfNeeded()
    }

    func adjustBioHeight(){
        let width = self.bioView.frame.width
        let newBioHeight = self.bioView.sizeThatFits(CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)).height
        if newBioHeight < self.bioView.frame.height{
             let difference = self.bioView.frame.height - newBioHeight
             self.frame.size.height -= difference
        }
        else if newBioHeight > self.bioView.frame.height{
            let difference = newBioHeight - self.bioView.frame.height
            print(self.bioView.frame.height)
            print(newBioHeight)
            print(difference)
            
            self.frame.size.height += difference
        }
    }
    

    func updateFollowBtn(didFollow: Bool, animated: Bool){
        var animationDuration = 0.0
        
        if animated{
            animationDuration = 0.2
        }
        if didFollow{
            headerActionBtnTitle = "Following"
            actionBtn.setTitleColor(.white, for: .normal)
            UIView.animate(withDuration: animationDuration, animations: {
                self.actionBtn .backgroundColor = UIColor(named: "LoadingColor")
            })
        }
        else{
            headerActionBtnTitle = "Follow"
            actionBtn.setTitleColor(ColorCompatibility.label, for: .normal)
            UIView.animate(withDuration: animationDuration, animations: {
                self.actionBtn.backgroundColor = ColorCompatibility.quaternarySystemFill
            })
        }
        actionBtn.titleLabel?.text = headerActionBtnTitle
        actionBtn.setTitle(headerActionBtnTitle, for: .normal)
    }
    
    func setUpInfo(username: String?, fullname: String?, bio: String?, notifID: String?, dpUID: String?, image: Data?, actionBtnTitle: String, followerCount: Int, followingCount : Int, postCount: Int){
        
        if let attr = bioView.attributedText.mutableCopy() as? NSMutableAttributedString{
            attr.removeAttribute(NSAttributedString.Key.link, range: NSMakeRange(0, attr.length))
            attr.setAttributes([NSAttributedString.Key.font : UIFont(name: "NexaW01-Regular", size: bioView.font?.pointSize ?? 16)!], range: NSMakeRange(0, attr.length))
            bioView.attributedText = attr
        }
        bioView?.text = nil
        usernameLbl.text = "@" + (username ?? "null")
        fullnameLbl.text = fullname ?? "null"
        bioView.text = bio
        bioView.addLinks(isNotification: false)
        bioView.textAlignment = .center
        followerNum.text = "\(followerCount)"
        followingNum.text = "\(followingCount)"
        postNum.text = "\(postCount)"
        actionBtn.titleLabel?.text = actionBtnTitle
        actionBtn.setTitle(actionBtnTitle, for: .normal)
        setNeedsLayout()
        layoutIfNeeded()
        guard let img = image else{
            return}
        profileImgView.image = UIImage(data: img)
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        
        if let scheme = URL.scheme{
            if interaction == .preview{
                return false
            }
            if scheme.starts(with: "mention"){
                let username = URL.absoluteString.replacingOccurrences(of: "mention:", with: "")
                if username != userInfo.username, username != (vc as? FriendVC)?.friendInfo.username{
                    let user = UserInfo(uid: nil, dp: nil, dpID: nil, username: username, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: [])
                    (vc as? FriendVC)?.selectedUser = user
                    (vc as? UserVC)?.selectedUser = user
                    vc?.performSegue(withIdentifier: "toFriend", sender: nil)
                }
            }
            else{
                return true
            }
        }
        return false
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        profileImgView.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        adjustBioHeight()
        userContentView.layer.cornerRadius =  userContentView.frame.width / 25
        userContentView.clipsToBounds = true
        userContentView.backgroundColor = UIColor(named: "ProfileMask")?.withAlphaComponent(0.25)
        profileImgView.layer.cornerRadius =  profileImgView.frame.height / 2
        profileImgView.clipsToBounds = true
        profileImgView.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
        profileImgView.layer.borderWidth = profileImgView.frame.width / 17.75
        actionBtn.layer.cornerRadius = actionBtn.frame.height / 4
        actionBtn.clipsToBounds = true
        if vc == nil{
            vc = getViewController()
        }
    }
}
