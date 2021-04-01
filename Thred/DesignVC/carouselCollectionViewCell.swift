//
//  CarouselCollectionViewCell.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-02-29.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import ColorCompatibility
import Firebase

class CarouselCollectionViewCell: UICollectionViewCell {
    
    weak var vc: DesignViewController!
    
    lazy var backgroundImageView: UIImageView! = {
        let iv = UIImageView(frame: frame)
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.isUserInteractionEnabled = false
        return iv
    }()
    
    
    lazy var unavailableLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 10, y: 0, width: self.contentView.frame.width - 40, height: 40))
        label.text = "This color is unavailable"
        label.textColor = .label
        label.font = UIFont(name: "NexaW01-Heavy", size: 16)
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.isUserInteractionEnabled = false
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /*
    lazy var colorDisplayLabel: PaddingLabel = {
        let label = PaddingLabel(frame: CGRect(x: 10, y: 0, width: backgroundImageView.frame.width - 20, height: 20))
        label.text = nil
        label.textColor = .secondaryLabel
        label.font = UIFont(name: "NexaW01-Heavy", size: 16)
        label.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.7)
        label.setPadding(2, 2, 7.5, 7.5)
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.roundAllBorders(cornerRadius: label.frame.height / 3)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    */
    override func awakeFromNib() {
        super.awakeFromNib()
        isUserInteractionEnabled = true
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
        
        contentView.addSubview(backgroundImageView)
        
        NSLayoutConstraint(item: backgroundImageView!, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: backgroundImageView!, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: backgroundImageView!, attribute: .left, relatedBy: .equal, toItem: contentView, attribute: .left, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: backgroundImageView!, attribute: .right, relatedBy: .equal, toItem: contentView, attribute: .right, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: backgroundImageView!, attribute: .width, relatedBy: .equal, toItem: contentView, attribute: .width, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: backgroundImageView!, attribute: .height, relatedBy: .equal, toItem: backgroundImageView!, attribute: .height, multiplier: 1, constant: 0).isActive = true
        
        contentView.addSubview(unavailableLabel)
        
        NSLayoutConstraint(item: unavailableLabel, attribute: .centerX, relatedBy: .equal, toItem: contentView, attribute: .centerX, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: unavailableLabel, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: unavailableLabel, attribute: .width, relatedBy: .equal, toItem: contentView, attribute: .width, multiplier: 1.0, constant: -20).isActive = true
        unavailableLabel.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
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
        
        for canvas in canvasDisplayViews{
            canvas.removeFromSuperview()
        }
        
        canvasDisplayViews.removeAll()
        touchHereLbls.removeAll()
        
        
        if let side = vc?.selectedSide ?? all.tees.first?.supportedSides.first(where: {$0.name == "Front"}){
            
            if vc == nil{
                
            }
            
            guard let name = side.name, let canvas = canvasDisplayView(for: name) else{return}
            
            canvas.addTarget(self, action: #selector(maximiseDrawingArea(_:)), for: .touchUpInside)

            let label = touchHereLabel(displayView: canvas)
            canvas.addSubview(label)
            contentView.addSubview(canvas)
            canvasDisplayViews.append(canvas)
            touchHereLbls.append(label)
            
            setConstraints(side: side, canvasDisplayView: canvas, touchHereLabel: label)
        }
    }
    
    func setConstraints(side: TemplateSide, canvasDisplayView: UIButton, touchHereLabel: UILabel){
        
        let imageView = backgroundImageView.superview
        switch topCanvasConstraints.isEmpty{
        case false:
            fallthrough
        default:
            guard ((imageView?.subviews ?? []).contains(canvasDisplayView)) else{return}
            let centerX = NSLayoutConstraint(item: canvasDisplayView, attribute: .centerX, relatedBy: .equal, toItem: imageView, attribute: .centerX, multiplier: 1.0, constant: 0)
            let centerY = NSLayoutConstraint(item: canvasDisplayView, attribute: .centerY, relatedBy: .equal, toItem: imageView, attribute: .centerY, multiplier: 1.0, constant: CGFloat(side.centerYConst ?? 0))
            
            let width = NSLayoutConstraint(item: canvasDisplayView, attribute: .width, relatedBy: .equal, toItem: imageView, attribute: .width, multiplier: CGFloat(side.widthMultiplier ?? 0), constant: 0)
            
            let height = NSLayoutConstraint(item: canvasDisplayView, attribute: .height, relatedBy: .equal, toItem: canvasDisplayView, attribute: .width, multiplier: side.regularAspectRatio, constant: 0)
            
            let touchCenterX = NSLayoutConstraint(item: touchHereLabel, attribute: .centerX, relatedBy: .equal, toItem: canvasDisplayView, attribute: .centerX, multiplier: 1.0, constant: 0)
            
            let touchCenterY = NSLayoutConstraint(item: touchHereLabel, attribute: .centerY, relatedBy: .equal, toItem: canvasDisplayView, attribute: .centerY, multiplier: 1.0, constant: 0)
            
            let touchWidth = NSLayoutConstraint(item: touchHereLabel, attribute: .width, relatedBy: .equal, toItem: canvasDisplayView, attribute: .width, multiplier: 1.0, constant: -15)
            
            topCanvasConstraints.append(centerX)
            topCanvasConstraints.append(centerY)
            topCanvasConstraints.append(width)
            topCanvasConstraints.append(height)
            topCanvasConstraints.append(touchCenterX)
            topCanvasConstraints.append(touchCenterY)
            topCanvasConstraints.append(touchWidth)
            
            for constraint in topCanvasConstraints{
                constraint.isActive = true
            }
        }
    }
    
    @objc func maximiseDrawingArea(_ sender: UIButton){
        
        if let designVC = self.getViewController() as? DesignViewController{
            
            designVC.maximiseDrawingArea(displayView: sender )
        }
    }
    
    func parseData(forSlide slide: TemplateCarouselSlide) {

        var img: UIImage!
        switch vc?.selectedSide.name {
        case "Front":
            if let data = slide.color?.img{
                img = UIImage(data: data) //
            }
        default:
            if let data = slide.color?.imgBack{
                img = UIImage(data: data) //
            }
        }
        /*
        //var dataString: Data!

        if img == nil{
            
            img = UIImage(named: "m_\(slide.color.code ?? "").png")?.withBackground(color: UIColor(named: "ProductColor")!)
            //dataString = img?.jpegData(compressionQuality: 0.385)
        }
        else{
            //dataString = img?.jpegData(compressionQuality: 0.385)
        }
        
        var imgBack: UIImage! //
        var backDataString: Data!

        var backID = "b_\(slide.color.code ?? "")"
        if slide.type == "Masks"{
            backID = "m_b_\(slide.color.code ?? "")"
        }
        imgBack = UIImage(named: backID)?.withBackground(color: UIColor(named: "ProductColor")!)
        backDataString = imgBack?.jpegData(compressionQuality: 0.385)

 */
        if let image = img {
            self.backgroundImageView.image = image
        }
        
        /*
        let colors = slide.color.rgb
        
        var r = colors?.first ?? 0
        var g = colors?[1] ?? 0
        var b = colors?.last ?? 0
        
        
        
        let dat = [
            
            [
                "IMG" : dataString ?? Data(),
                "IMG_BACK" : backDataString ?? Data(),
                "Code" : slide.color.code,
                "Display" : slide.color.display,
                "RGB" : [r, g, b]
            ]
        ]
        
        
            Firestore.firestore().collection("Templates").document(slide.type).updateData(["Colors" : FieldValue.arrayUnion(dat)])

        
        
        */
 
    }
    
    override func layoutSubviews() {

    }
    
    
}


extension UIView{
    
    enum Side {
        case top
        case bottom
        case left
        case right
    }
    
    func addBorders(to borders: [Side], color: UIColor, width: CGFloat) {
        
        for borderType in borders{
            let border = CALayer()

            print(bounds.size)
            
            switch borderType{
            case .top:
                border.frame = CGRect(x: 0.0, y: 0.0, width: bounds.size.width, height: width)
            case .bottom:
                border.frame = CGRect(x:0, y: bounds.size.height - width, width: bounds.size.width, height:width)
            case .left:
                border.frame = CGRect(x:0, y: 0, width: width, height:bounds.size.height)
            case .right:
                border.frame = CGRect(x:bounds.size.width - width, y: 0, width: width, height:bounds.size.height)
            }
            border.backgroundColor = color.cgColor
            layer.addSublayer(border)
        }
    }
}


final public class TemplateCarouselSlide : NSObject {
    
    var color: Colors!
    var type: String!
    
    init(color: Colors!) {
        self.color = color
    }
    
    override init() {
        super.init()
    }
    
}

class PaddingLabel: UILabel {
    
    var insets = UIEdgeInsets.zero
    
    func setPadding(_ top: CGFloat, _ bottom: CGFloat, _ left: CGFloat, _ right: CGFloat) {
        self.frame = CGRect(x: 0, y: 0, width: self.frame.width + left + right, height: self.frame.height + top + bottom)
        insets = UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
    }
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }
    
    override var intrinsicContentSize: CGSize {
        get {
            var contentSize = super.intrinsicContentSize
            contentSize.height += insets.top + insets.bottom
            contentSize.width += insets.left + insets.right
            return contentSize
        }
    }
}

extension UILabel{
    func roundTopBorders(cornerRadius: CGFloat){
        self.clipsToBounds = true
        self.layer.cornerRadius = cornerRadius
        self.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }
    
    func roundAllBorders(cornerRadius: CGFloat){
        self.clipsToBounds = true
        self.layer.cornerRadius = cornerRadius
        self.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    }
}

class CanvasDisplayView: UIButton{
    
    var side: TemplateSide!
    
    init(frame: CGRect, side: TemplateSide) {
        self.side = side
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UIView{
    func canvasDisplayView(for templateName: String) -> CanvasDisplayView?{
        guard let side = all.tees.first(where: {$0.supportedSides.contains(where: {$0.name == templateName})})?.supportedSides.first(where: {$0.name == templateName}) else{ return nil }
        let view = CanvasDisplayView(frame: CGRect(x: 0, y: 0, width: 40, height: 40), side: side)
        view.layer.borderColor = UIColor.white.cgColor
        view.isUserInteractionEnabled = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }
    
    func touchHereLabel(displayView: UIButton) -> UILabel {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: displayView.frame.width, height: 20))
        label.text = "ADD DESIGN"
        label.textColor = .label
        label.font = UIFont(name: "NexaW01-Heavy", size: 18)
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.2
        label.isUserInteractionEnabled = false
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
}
