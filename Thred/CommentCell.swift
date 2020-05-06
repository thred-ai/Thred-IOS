//
//  CommentCell.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-03-22.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit

class CommentCell: UITableViewCell, UITextViewDelegate {
    
    @IBOutlet weak var fullNameLbl: UILabel!
    @IBOutlet weak var usernameLbl: UILabel!
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var messageView: UITextView!
    @IBOutlet weak var timestampLbl: UILabel!
    
    @IBOutlet weak var userInfoView: UIStackView!
    
    weak var vc: CommentsVC!
    weak var comment: Comment!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        profilePicture.layer.cornerRadius = profilePicture.frame.height / 2
        profilePicture.clipsToBounds = true
        messageView.delegate = self
        // Initialization code
        
        let tapper = UITapGestureRecognizer(target: self, action: #selector(toProfile(_:)))
        let tapper2 = UITapGestureRecognizer(target: self, action: #selector(toProfile(_:)))
        userInfoView.addGestureRecognizer(tapper)
        profilePicture.addGestureRecognizer(tapper2)
        profilePicture.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
        profilePicture.layer.borderWidth = profilePicture.frame.width / 17.75
    }
    
    override func layoutSubviews() {
        
    }
    
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        profilePicture.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
    }
    
    @objc func toProfile(_ sender: UITapGestureRecognizer){
  
        guard comment != nil else{return}
        let commentUserInfo = comment.userInfo
        guard commentUserInfo.uid != userInfo.uid else{return}
        vc.selectedUser = UserInfo(uid: commentUserInfo.uid, dp: commentUserInfo.dp, dpID: commentUserInfo.dpID, username: commentUserInfo.username, fullName: commentUserInfo.fullName, bio: commentUserInfo.bio, notifID: commentUserInfo.notifID, userFollowing: commentUserInfo.userFollowing, userLiked: commentUserInfo.userLiked, followerCount: commentUserInfo.followerCount, postCount: commentUserInfo.postCount, followingCount: commentUserInfo.followingCount, usersBlocking: commentUserInfo.usersBlocking)
        vc.performSegue(withIdentifier: "toFriend", sender: nil)
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        
        if let scheme = URL.scheme{
            if interaction == .preview{
                return false
            }
            if scheme.starts(with: "mention"){
                let username = URL.absoluteString.replacingOccurrences(of: "mention:", with: "")
                if username != userInfo.username{
                    if let sameUser = vc?.comments.first(where: {$0.userInfo.username == username})?.userInfo{
                        vc.selectedUser = sameUser
                    }
                    else{
                        vc.selectedUser = UserInfo(uid: nil, dp: nil, dpID: nil, username: username, fullName: nil, bio: nil, notifID: nil, userFollowing: [], userLiked: [], followerCount: 0, postCount: 0, followingCount: 0, usersBlocking: [])
                    }
                    vc.performSegue(withIdentifier: "toFriend", sender: nil)
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

}
