//
//  HashtagHeaderView.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-08-09.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit

class HashtagHeaderView: UICollectionReusableView {
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var backgroundMaskView: UIView!
    @IBOutlet weak var hashtagLbl: UILabel!
    @IBOutlet weak var numPostsLbl: UILabel!
    @IBOutlet weak var featuredLbl: UILabel!
    @IBOutlet weak var viewFullProductView: UIView!
    @IBOutlet weak var viewFullProductBtn: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundMaskView.alpha = 0.90
        featuredLbl.text = nil
    }
    
    @IBAction func viewFullProduct(_ sender: UIButton) {
        
        guard let vc = getViewController() as? ColorSectionVC else{return}
        vc.productToOpen = vc.hashtag?.topPost
        vc.performSegue(withIdentifier: "toFull", sender: nil)
    }
    
    override func layoutSubviews() {
        viewFullProductView.layer.cornerRadius = viewFullProductView.frame.height / 4
        viewFullProductView.clipsToBounds = true
    }
}
