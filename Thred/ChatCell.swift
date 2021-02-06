//
//  ChatCell.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-08-23.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit

class ChatCell: UITableViewCell {

    @IBOutlet weak var newIcon: UIView!
    @IBOutlet weak var chatPicView: UIImageView!
    @IBOutlet weak var chatNameBtn: UIButton!
    @IBOutlet weak var chatMsgLbl: UILabel!
    @IBOutlet weak var tiimestampLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        chatNameBtn.isUserInteractionEnabled = false
    }
    
    @IBOutlet weak var speakerView: UIImageView!
    override func layoutSubviews() {
        
        DispatchQueue.main.async {
            self.chatPicView.layer.cornerRadius = self.chatPicView.frame.height / 2
            self.chatPicView.clipsToBounds = true
            self.chatPicView.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
            self.chatPicView.layer.borderWidth = self.chatPicView.frame.height / 17.75
            self.newIcon.layer.cornerRadius = self.newIcon.frame.height / 2
            self.newIcon.clipsToBounds = true
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if isSelected{
            self.chatPicView.layer.borderColor = UIColor(named: "LoadingColor")?.withAlphaComponent(0.75).cgColor
        }
        else{
            self.chatPicView.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
