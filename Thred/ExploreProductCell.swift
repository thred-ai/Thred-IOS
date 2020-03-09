//
//  ExploreProductCell.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-02-26.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import ColorCompatibility

class ExploreProductCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    let circularProgress = CircularProgress(frame: CGRect(x: 0, y: 0, width: 40, height: 40))

    override func awakeFromNib() {
        super.awakeFromNib()
        self.setUpCircularProgress()
        // Initialization code
        
        
    }

    func setUpCircularProgress(){
        
        if !self.imageView.subviews.contains(circularProgress){
            circularProgress.isHidden = true
            circularProgress.progressColor = (UIColor(named: "loadingColor") ?? UIColor(red: 0.4235, green: 0.7863, blue: 0.9882, alpha: 1)) /* #e0e0e0 */
            circularProgress.trackColor = ColorCompatibility.systemFill
            circularProgress.translatesAutoresizingMaskIntoConstraints = false
            self.imageView.addSubview(circularProgress)
            self.bringSubviewToFront(circularProgress)
            NSLayoutConstraint.activate([
                circularProgress.heightAnchor.constraint(equalToConstant: 40),
                circularProgress.widthAnchor.constraint(equalToConstant: 40),
                circularProgress.centerXAnchor.constraint(equalTo: self.imageView.centerXAnchor),
                circularProgress.centerYAnchor.constraint(equalTo: self.imageView.centerYAnchor)
            ])
        }
    }
}
