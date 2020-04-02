//
//  CarouselCollectionViewCell.swift
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

class CarouselCollectionViewCell: UICollectionViewCell {
    
    lazy var backgroundImageView: UIImageView! = {
        let iv = UIImageView(frame: frame)
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    lazy var canvasDisplayView: UIImageView = {
        let view = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 1
        view.isUserInteractionEnabled = true
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
    
    lazy var colorDisplayLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 10, y: 0, width: backgroundImageView.frame.width - 20, height: 30))
        label.text = nil
        label.textColor = ColorCompatibility.secondaryLabel
        label.font = UIFont(name: "NexaW01-Heavy", size: 16)
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override init(frame: CGRect){
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = .clear
        
        addSubview(backgroundImageView)
        
        NSLayoutConstraint(item: backgroundImageView!, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: backgroundImageView!, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: backgroundImageView!, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: backgroundImageView!, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: backgroundImageView!, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: backgroundImageView!, attribute: .height, relatedBy: .equal, toItem: backgroundImageView!, attribute: .height, multiplier: 1, constant: 0).isActive = true
        
        addSubview(canvasDisplayView)
        
        NSLayoutConstraint(item: canvasDisplayView, attribute: .centerX, relatedBy: .equal, toItem: backgroundImageView.superview, attribute: .centerX, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: canvasDisplayView, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1.0, constant: -20).isActive = true
        NSLayoutConstraint(item: canvasDisplayView, attribute: .width, relatedBy: .equal, toItem: backgroundImageView.superview, attribute: .width, multiplier: 0.25, constant: 0).isActive = true
        NSLayoutConstraint(item: canvasDisplayView, attribute: .height, relatedBy: .equal, toItem: canvasDisplayView, attribute: .width, multiplier: canvasInfo.aspectRatio, constant: 0).isActive = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(maximiseDrawingArea(_:)))
        canvasDisplayView.addGestureRecognizer(tap)
        
        canvasDisplayView.addSubview(touchHereLabel)
        
        NSLayoutConstraint(item: touchHereLabel, attribute: .centerX, relatedBy: .equal, toItem: canvasDisplayView, attribute: .centerX, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: touchHereLabel, attribute: .centerY, relatedBy: .equal, toItem: canvasDisplayView, attribute: .centerY, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: touchHereLabel, attribute: .width, relatedBy: .equal, toItem: canvasDisplayView, attribute: .width, multiplier: 1.0, constant: -20).isActive = true
        touchHereLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        backgroundImageView.addSubview(colorDisplayLabel)
        NSLayoutConstraint(item: colorDisplayLabel, attribute: .centerX, relatedBy: .equal, toItem: backgroundImageView, attribute: .centerX, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: colorDisplayLabel, attribute: .bottom, relatedBy: .equal, toItem: backgroundImageView, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: colorDisplayLabel, attribute: .width, relatedBy: .equal, toItem: backgroundImageView, attribute: .width, multiplier: 1.0, constant: -20).isActive = true
        colorDisplayLabel.heightAnchor.constraint(equalToConstant: 30).isActive = true
    }
    
    
    
    @objc func maximiseDrawingArea(_ sender: UITapGestureRecognizer){
        
        
        if let designVC = self.parentViewController as? DesignViewController{
            designVC.maximiseDrawingArea(displayView: sender.view as! UIImageView)
        }
    }
    
    func parseData(forSlide slide: TemplateCarouselSlide) {
        let bundlePath = Bundle.main.path(forResource: slide.canvasColorID, ofType: "png")
        let image = UIImage(contentsOfFile: bundlePath!)
        if let image = image {
            backgroundImageView.image = image
        }
        if let color = slide.canvasBackColor {
            canvasDisplayView.backgroundColor = color
        }
        if let displayName = slide.canvasColorName {
            colorDisplayLabel.text = displayName
        }
        backgroundImageView.removeShadow()
        backgroundImageView.addShadowToImageNotLayer()
        
        return
    }
    
    override func layoutSubviews() {

    }
    

}

final public class TemplateCarouselSlide : NSObject {
    
    public var canvasBackColor: UIColor?
    public var canvasColorName: String?
    public var canvasColorID: String?

    
    public init(canvasColor: UIColor?, canvasName: String?, canvasID: String?) {
        canvasBackColor = canvasColor
        canvasColorName = canvasName
        canvasColorID = canvasID
    }
    
    override init() {
        super.init()
    }
    
}

