//
//  NewsSection.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-09-20.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit

class NewsSection: UIView {

    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var detailsView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var blurView: UIView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var titleView: UIView!
    
    override func awakeFromNib() {
        titleLbl.text = nil
        blurView.addBackgroundBlur(blurEffect: UIBlurEffect(style: UIBlurEffect.Style.systemUltraThinMaterial))
        blurView.alpha = 0.95
    }
    @IBAction func openLink(_ sender: UIButton) {
        guard
            let announcement = (getViewController() as? ExploreViewController)?.announcements.first,
            let link = announcement.link
        else{return}
        
        UIApplication.shared.open(link, options: self.convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
    }
    
    override func layoutSubviews() {
        contentView.layer.cornerRadius = 10
        contentView.clipsToBounds = true
        
        contentView.setRadiusWithShadowHeavy()
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
