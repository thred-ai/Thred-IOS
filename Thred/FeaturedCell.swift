//
//  FeaturedCell.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-04-09.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import ColorCompatibility

class FeaturedCell: UICollectionViewCell {

    @IBOutlet weak var dotLabel: UILabel!
    @IBOutlet weak var thredIcon: UIImageView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var priceLbl: UILabel!
    @IBOutlet weak var likesLbl: UILabel!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var circularProgress: CircularProgress!
    
    lazy var canvasDisplayView: UIImageView = {
        let view = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        view.isUserInteractionEnabled = true
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        circularProgress.progressColor = (UIColor(named: "loadingColor") ?? UIColor(red: 0.4235, green: 0.7863, blue: 0.9882, alpha: 1)) /* #e0e0e0 */
        circularProgress.trackColor = ColorCompatibility.systemFill
        
        infoView.backgroundColor = UIColor(named: "ProfileMask")?.withAlphaComponent(0.4)
        
        imageView.addSubview(canvasDisplayView)
        
        NSLayoutConstraint(item: canvasDisplayView, attribute: .centerX, relatedBy: .equal, toItem: imageView, attribute: .centerX, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: canvasDisplayView, attribute: .centerY, relatedBy: .equal, toItem: imageView, attribute: .centerY, multiplier: 1.0, constant: -20).isActive = true
        NSLayoutConstraint(item: canvasDisplayView, attribute: .width, relatedBy: .equal, toItem: imageView, attribute: .width, multiplier: 0.25, constant: 0).isActive = true
        NSLayoutConstraint(item: canvasDisplayView, attribute: .height, relatedBy: .equal, toItem: canvasDisplayView, attribute: .width, multiplier: canvasInfo.aspectRatio, constant: 0).isActive = true
    }
    
    override func layoutSubviews() {
    }
    
    
    override func prepareForReuse() {
        roundCorners([.bottomRight, .bottomLeft], radius: 0)
    }

}

extension UISegmentedControl {

    func setTitleColor(_ color: UIColor, state: UIControl.State = .normal) {
        var attributes = titleTextAttributes(for: state) ?? [:]
        attributes[.foregroundColor] = color
        setTitleTextAttributes(attributes, for: state)
    }

    func setTitleFont(_ font: UIFont, state: UIControl.State = .normal) {
        var attributes = titleTextAttributes(for: state) ?? [:]
        attributes[.font] = font
        setTitleTextAttributes(attributes, for: state)
    }

}
