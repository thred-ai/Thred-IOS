//
//  NotificationCell.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-03-15.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit

class NotificationCell: UITableViewCell {

    @IBOutlet weak var notifPic: UIImageView!
    
    @IBOutlet weak var notifLbl: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
