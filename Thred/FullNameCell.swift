//
//  FullNameCell.swift
//  Thred
//
//  Created by Arta Koroushnia on 2019-11-25.
//  Copyright © 2019 Thred Apps Inc. All rights reserved.
//

import UIKit
import ColorCompatibility


class FullNameCell: UITableViewCell{

    @IBOutlet weak var fullNameField: UITextField!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.backgroundColor = ColorCompatibility.systemBackground

        // Configure the view for the selected state
    }

}
