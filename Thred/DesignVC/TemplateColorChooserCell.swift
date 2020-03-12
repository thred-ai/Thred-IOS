//
//  TemplateColorChooserCell.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-03-07.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit

class TemplateColorChooserCell: UICollectionViewCell {
    
    @IBOutlet weak var colorView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func layoutSubviews() {
        self.colorView.layer.cornerRadius = self.colorView.frame.height / 2
        self.colorView.clipsToBounds = true
        if isSelected{
            self.colorView.layer.borderColor = UIColor(named: "LoadingColor")?.withAlphaComponent(0.75).cgColor
        }
        else{
            self.colorView.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
        }
        self.colorView.layer.borderWidth = self.colorView.frame.height / 17.75
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if isSelected{
            self.colorView.layer.borderColor = UIColor(named: "LoadingColor")?.withAlphaComponent(0.75).cgColor
        }
        else{
            self.colorView.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
        }
    }
    
    override var isSelected: Bool {
        didSet {
            if self.isSelected {
                self.colorView.layer.borderColor = UIColor(named: "LoadingColor")?.withAlphaComponent(0.75).cgColor
            } else {
                self.colorView.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
            }
        }
    }
}
