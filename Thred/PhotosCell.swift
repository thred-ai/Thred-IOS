//
//  PhotosCell.swift
//  Thred
//
//  Created by Arta Koroushnia on 2019-11-22.
//  Copyright © 2019 Thred Apps Inc. All rights reserved.
//

import UIKit

class PhotosCell: UICollectionViewCell {

    @IBOutlet weak var photoImageView: UIImageView!
    
    var photo: UIImage? = nil{
        didSet{
            photoImageView.image = photo
            if photo == nil{
                isUserInteractionEnabled = false
            }
            else{
                isUserInteractionEnabled = true
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func prepareForReuse() {
        photoImageView.image = nil
        photoImageView.alpha = 1.0
    }
    
    override var isSelected: Bool{
        didSet{
            if isSelected{
                photoImageView.alpha = 0.8
            }
            else{
                photoImageView.alpha = 1.0
            }
        }
    }
}
