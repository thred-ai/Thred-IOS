//
//  StoriesCell.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-09-09.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit

class StoriesCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    
    }
    
    override func layoutSubviews() {
        DispatchQueue.main.async {
            self.imageView.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
            self.imageView.layer.borderWidth = self.imageView.frame.height / 17.75
            self.imageView.layer.cornerRadius = self.imageView.frame.height / 2
            self.imageView.clipsToBounds = true
        }
    }

}
