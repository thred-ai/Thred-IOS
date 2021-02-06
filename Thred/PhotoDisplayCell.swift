//
//  PhotoDisplayCell.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-08-04.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit

class PhotoDisplayCell: UICollectionViewCell {

    @IBOutlet weak var photoImgView: UIButton!
    @IBOutlet weak var cancelBtn: UIButton!
    
    @IBAction func removePhoto(_ sender: UIButton) {
        if let vc = getViewController() as? CommentsVC{
            vc.imagesToUpload.removeAll()
            vc.reloadChosenPhotoCollectionView(clear: true)
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        photoImgView.imageView!.contentMode = .scaleAspectFit
        photoImgView.contentVerticalAlignment = .fill
        photoImgView.contentHorizontalAlignment = .fill
        // Initialization code
    }

}
