//
//  UsernameCell.swift
//  Thred
//
//  Created by Arta Koroushnia on 2019-11-25.
//  Copyright © 2019 ArtaCorp. All rights reserved.
//

import UIKit
import ColorCompatibility


class UsernameCell: UITableViewCell {

    @IBOutlet weak var usernameField: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.backgroundColor = ColorCompatibility.systemBackground
        // Configure the view for the selected state
    }

}
