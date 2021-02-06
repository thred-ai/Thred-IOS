//
//  ProductInfoCell.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-09-08.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit

class ProductInfoCell: UITableViewCell {
    
    @IBOutlet weak var infoLbl: UILabel!
    @IBOutlet weak var infoView: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
