//
//  TemplateColorChooserCellCollectionViewCell.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-03-07.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit

class TemplateColorChooserCellCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var colorView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func layoutSubviews() {
        self.colorView.layer.cornerRadius = self.colorView.frame.height / 2
        self.colorView.clipsToBounds = true
    }
}
