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
    var notif: UserNotification!{
        didSet{
            if notifLbl.text.isEmpty || notifLbl.text == nil{
                setNotifMessage()
            }
            let name = notif.userInfo?.fullName ?? ""
            setName(name: name)
        }
    }
    @IBOutlet weak var notifLbl: UITextView!
    @IBOutlet weak var timestampLbl: UILabel!
    weak var vc: NotificationVC!
    
    @IBAction func toUser(_ sender: UIButton){
        if let user = notif.userInfo{
            vc.selectedObject = user
            vc.performSegue(withIdentifier: "toFriend", sender: nil)
        }
    }
    
    func setName(name: String?){
        nameBtn.titleLabel?.text = name
        nameBtn.setTitle(name, for: .normal)
    }
    
    func setNotifMessage(){
        
        guard !notif.deleted else{return}
        
        if notif.notifType == "Follow"{
            notifLbl.text = "started following you"
            notifLbl.textColor = ColorCompatibility.secondaryLabel
        }
        else if notif.notifType == "Like"{
            notifLbl.text = "liked your post"
            notifLbl.textColor = ColorCompatibility.secondaryLabel
        }
        else if notif.notifType == "Buy"{
            notifLbl.text = "purchased your post"
            notifLbl.textColor = UIColor(named: "ActiveColor")
        }
        else if notif.notifType == "Comment"{
            notifLbl.text = "commented on your post: \(notif.commentMessage ?? "This comment cannot be displayed")"
            notifLbl.textColor = ColorCompatibility.secondaryLabel
        }
        else if notif.notifType == "Mention"{
            notifLbl.text = "mentioned you in a comment: \(notif.commentMessage ?? "This comment cannot be displayed")"
            notifLbl.textColor = ColorCompatibility.secondaryLabel
        }
        else if notif.notifType == "Bio_Mention"{
            notifLbl.text = "mentioned you in their bio"
            notifLbl.textColor = ColorCompatibility.secondaryLabel
        }
        else if notif.notifType == "Post_Mention"{
            notifLbl.text = "mentioned you in their post"
            notifLbl.textColor = ColorCompatibility.secondaryLabel
        }
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
                notifPic.layer.borderWidth = 0
            }
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        notifPic.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
