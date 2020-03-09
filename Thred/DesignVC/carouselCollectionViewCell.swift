//
//  carouselCollectionViewCell.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-02-29.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import ColorCompatibility

class CanvasInfo{
    var heightCM: CGFloat {
        return 30.48
    }
    var widthCM: CGFloat {
        return 19.685
    }
    var aspectRatio: CGFloat {
        return heightCM / widthCM
    }
}

var canvasInfo = CanvasInfo()

class carouselCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    lazy var canvasDisplayView: UIImageView = {
        let view = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 1
        view.isUserInteractionEnabled = true
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var touchHereLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 10, y: 0, width: canvasDisplayView.frame.width - 20, height: 20))
        label.text = "Add a Design"
        label.textColor = ColorCompatibility.label
        label.font = UIFont(name: "NexaW01-Heavy", size: 16)
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    
    override func prepareForReuse() {
        
    }
    
    private func setup() {
        backgroundColor = .clear
        clipsToBounds = true
        
        NSLayoutConstraint(item: backgroundImageView!, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: backgroundImageView!, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: backgroundImageView!, attribute: .left, relatedBy: .equal, toItem: contentView, attribute: .left, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: backgroundImageView!, attribute: .right, relatedBy: .equal, toItem: contentView, attribute: .right, multiplier: 1.0, constant: 0).isActive = true
        
        addSubview(canvasDisplayView)
        
        NSLayoutConstraint(item: canvasDisplayView, attribute: .centerX, relatedBy: .equal, toItem: contentView, attribute: .centerX, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: canvasDisplayView, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1.0, constant: -20).isActive = true
        NSLayoutConstraint(item: canvasDisplayView, attribute: .width, relatedBy: .equal, toItem: contentView, attribute: .width, multiplier: 0.25, constant: 0).isActive = true
        NSLayoutConstraint(item: canvasDisplayView, attribute: .height, relatedBy: .equal, toItem: canvasDisplayView, attribute: .width, multiplier: canvasInfo.aspectRatio, constant: 0).isActive = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(maximiseDrawingArea(_:)))
        canvasDisplayView.addGestureRecognizer(tap)
        
        canvasDisplayView.addSubview(touchHereLabel)
        
        NSLayoutConstraint(item: touchHereLabel, attribute: .centerX, relatedBy: .equal, toItem: canvasDisplayView, attribute: .centerX, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: touchHereLabel, attribute: .centerY, relatedBy: .equal, toItem: canvasDisplayView, attribute: .centerY, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: touchHereLabel, attribute: .width, relatedBy: .equal, toItem: canvasDisplayView, attribute: .width, multiplier: 1.0, constant: -20).isActive = true
        touchHereLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
    }
    
    
    
    @objc func maximiseDrawingArea(_ sender: UITapGestureRecognizer){
        
        
        if let designVC = self.parentViewController as? DesignViewController{
            designVC.maximiseDrawingArea(displayView: sender.view as! UIImageView)
        }
    }
    
    func parseData(forSlide slide: TemplateCarouselSlide) {
        if let image = slide.slideImage {
            self.backgroundImageView.image = image
        }
        if let color = slide.canvasBackColor {
            self.canvasDisplayView.backgroundColor = color
        }
        
        return
    }
    
    override func layoutSubviews() {
        
    }
    

}

final public class TemplateCarouselSlide : NSObject {
    
    public var slideImage : UIImage?
    public var canvasBackColor: UIColor?
    public var canvasColorName: String?
    
    public init(image: UIImage?, canvasColor: UIColor?, canvasName: String?) {
        slideImage = image
        
        canvasBackColor = canvasColor
        canvasColorName = canvasName
    }
    
    override init() {
        super.init()
    }
    
}

