//
//  ExploreTopView.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-09-21.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit

class ExploreTopView: UIView {

    lazy var newsSection: NewsSection! = {
        return loadNewsSectionFromNib()
    }()
    lazy var featuredView: FeaturedPostView! = {
        return loadFeaturedHeaderFromNib()
    }()
    var vc: UIViewController!{
        didSet{
            featuredView.vc = vc
            featuredView.collectionView.reloadData()
        }
    }
    
    func setFeaturedHeightConstraints(height: CGFloat){
        if !(featuredView.constraints.contains(where: {$0.constant == height})){
            if let constraint = featuredView.constraints.first(where: {$0.firstAttribute == .height}){
                featuredView.removeConstraint(constraint)
            }
            featuredView.heightAnchor.constraint(equalToConstant: height).isActive = true
        }
    }
    
    func setNewsSectionHeightConstraints(height: CGFloat){
        if !(newsSection.constraints.contains(where: {$0.constant == height})){
            if let constraint = newsSection.constraints.first(where: {$0.firstAttribute == .height}){
                newsSection.removeConstraint(constraint)
            }
            newsSection.heightAnchor.constraint(equalToConstant: height).isActive = true
        }
    }
    
    @IBOutlet weak var stackView: UIStackView!
    
    
    override func awakeFromNib() {
        
        stackView.addArrangedSubview(newsSection)
        stackView.addArrangedSubview(featuredView)
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
