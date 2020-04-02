//
//  SearchProductTableViewCell.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-03-29.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit

class SearchProductTableViewCell: UITableViewCell {
    
    @IBOutlet weak var productImageView: UIImageView!
    @IBOutlet weak var productNameLbl: UILabel!
    @IBOutlet weak var fullnameLbl: UILabel!
    @IBOutlet weak var usernameLbl: UILabel!
    @IBOutlet weak var likesLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        productImageView.layer.cornerRadius = productImageView.frame.height / 8
        productImageView.clipsToBounds = true
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
