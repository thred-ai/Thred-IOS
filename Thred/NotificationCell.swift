//
//  NotificationCell.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-03-15.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit

class NotificationCell: UITableViewCell{

    @IBOutlet weak var notifPic: UIImageView!
    
    @IBOutlet weak var notifLbl: UITextView!
    @IBOutlet weak var timestampLbl: UILabel!
    weak var vc: NotificationVC!
    
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
