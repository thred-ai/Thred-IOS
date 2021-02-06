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
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var priceLbl: UILabel!
    @IBOutlet weak var likesLbl: UILabel!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var circularProgress: CircularProgress!
    
    @IBOutlet weak var removedTextView: UITextView!
    @IBOutlet weak var productRemovedView: UIView!
    var product: Product!
    @IBAction func toRemovedLink(_ sender: UIButton) {
        
        
    }
    
    var isRemoved = false{
        didSet{
            if let attr = removedTextView.attributedText.mutableCopy() as? NSMutableAttributedString{
                attr.removeAttribute(NSAttributedString.Key.link, range: NSMakeRange(0, attr.length))
                attr.setAttributes([NSAttributedString.Key.font : UIFont(name: "NexaW01-Regular", size: removedTextView.font?.pointSize ?? 16)!], range: NSMakeRange(0, attr.length))
                removedTextView.attributedText = attr
            }
            productRemovedView.isHidden = true
            removedTextView.text = nil
            if isRemoved{
                productRemovedView.isHidden = false
                addGuidelinesLink()
            }
        }
    }
    
    func addGuidelinesLink(){
        let linkWords = "Community Guidelines"

        let guideLineText = "This product has been removed from your order as it violated our \(linkWords). You will receive a full refund for this product."
        
        removedTextView.text = guideLineText
        let attrString = NSMutableAttributedString()
        attrString.setAttributedString(removedTextView.attributedText)
        let nsText = NSString(string: guideLineText)
        let matchRange:NSRange = nsText.range(of: linkWords)
        
        guard let font = UIFont(name: "NexaW01-Heavy", size: removedTextView.font?.pointSize ?? 16) else{return}
        
        let attributes = [
            NSAttributedString.Key.link : "https://thredapps.com/community-guidelines",
            NSAttributedString.Key.font : font
        ] as [NSAttributedString.Key : Any]
        
        attrString.addAttributes(attributes, range: matchRange)

        removedTextView.attributedText = attrString
        removedTextView.textAlignment = .center
        removedTextView.linkTextAttributes = [
            NSAttributedString.Key.foregroundColor : UIColor(named: "LoadingColor")!
        ]
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        circularProgress.progressColor = (UIColor(named: "LoadingColor") ?? UIColor(red: 0.4235, green: 0.7863, blue: 0.9882, alpha: 1)) /* #e0e0e0 */
        circularProgress.trackColor = .systemFill
        productRemovedView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.75)
        

        
        
    }
    
    var topCanvasConstraints = [NSLayoutConstraint]()
    var canvasDisplayViews = [CanvasDisplayView]()
    var touchHereLbls = [UILabel]()

    
    func addConstraints(template: Template!){
        
        switch topCanvasConstraints.isEmpty{
        case false:
            for constraint in topCanvasConstraints{
                constraint.isActive = false
            }
            topCanvasConstraints.removeAll()
        case true:
            break
        }
        
        for view in canvasDisplayViews{
            view.removeFromSuperview()
        }
        canvasDisplayViews.removeAll()
        
        if let sideString = product?.displaySide.capitalizingFirstLetter(), let side = template?.supportedSides.first(where: {$0.name == sideString}) ?? template?.supportedSides.first(where: {$0.name == "Front"}){

            guard let name = side.name, let canvas = canvasDisplayView(for: name) else{return}
            
            canvasDisplayViews.append(canvas)
            
            imageView.addSubview(canvas)

            setConstraints(side: side, canvasDisplayView: canvas)
        }
    }
    
    func setConstraints(side: TemplateSide, canvasDisplayView: UIButton){
        
        switch topCanvasConstraints.isEmpty{
        case false:
            fallthrough
        default:
            DispatchQueue.main.async {
                let ratio = self.imageView.frame.width / (UIApplication.shared.windows.first?.frame.width ?? 0)
                let newConst = CGFloat(side.centerYConst ?? 0) * ratio
                guard self.imageView.subviews.contains(canvasDisplayView) else{return}
                let centerX = NSLayoutConstraint(item: canvasDisplayView, attribute: .centerX, relatedBy: .equal, toItem: self.imageView, attribute: .centerX, multiplier: 1.0, constant: 0)
                let centerY = NSLayoutConstraint(item: canvasDisplayView, attribute: .centerY, relatedBy: .equal, toItem: self.imageView, attribute: .centerY, multiplier: 1.0, constant: newConst)
                
                let width = NSLayoutConstraint(item: canvasDisplayView, attribute: .width, relatedBy: .equal, toItem: self.imageView, attribute: .width, multiplier: CGFloat(side.widthMultiplier ?? 0), constant: 0)
                
                let height = NSLayoutConstraint(item: canvasDisplayView, attribute: .height, relatedBy: .equal, toItem: canvasDisplayView, attribute: .width, multiplier: side.regularAspectRatio, constant: 0)
                
                self.topCanvasConstraints.append(centerX)
                self.topCanvasConstraints.append(centerY)
                self.topCanvasConstraints.append(width)
                self.topCanvasConstraints.append(height)
                
                for constraint in self.topCanvasConstraints{
                    constraint.isActive = true
                }
            }
        }
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
