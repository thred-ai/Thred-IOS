//
//  UsernameCell.swift
//  Thred
//
//  Created by Arta Koroushnia on 2019-11-25.
//  Copyright © 2019 Thred Apps Inc. All rights reserved.
//

import UIKit
import ColorCompatibility


class UsernameCell: UITableViewCell {

    @IBOutlet weak var usernameField: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        usernameField.backgroundColor = .secondarySystemBackground
    }
    
    override func layoutSubviews() {
        usernameField.layer.cornerRadius = usernameField.frame.height / 2
        usernameField.clipsToBounds = true
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.backgroundColor = .systemBackground
        // Configure the view for the selected state
    }

}
