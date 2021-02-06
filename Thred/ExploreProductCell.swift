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
    
    var topCanvasConstraints = [NSLayoutConstraint]()
    var canvasDisplayViews = [CanvasDisplayView]()

    var product: Product!
    
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
        
        if let sideString = product?.displaySide.capitalizingFirstLetter(), let side = template?.supportedSides.first(where: {$0.name == sideString}) ?? template?.supportedSides.first(where: {$0.name == "Front"}){
            guard let name = side.name, let canvas = canvasDisplayView(for: name) else{return}
            imageView.addSubview(canvas)
            canvasDisplayViews.append(canvas)
            setConstraints(side: side, canvasDisplayView: canvas)
        }
    }
    
    func setConstraints(side: TemplateSide, canvasDisplayView: UIButton){
        
        switch topCanvasConstraints.isEmpty{
        case false:
            fallthrough
        default:
            DispatchQueue.main.async {
                let ratio = self.contentView.frame.width / (UIApplication.shared.windows.first?.frame.width ?? 0)
                let newConst = CGFloat(side.centerYConst ?? 0) * ratio
                print(ratio)
                print(newConst)
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
                self.setNeedsLayout()
                self.layoutIfNeeded()
            }
        }
    }
    
    override func layoutSubviews() {
        contentView.clipsToBounds = true
        
        DispatchQueue.main.async {
            self.contentView.layer.cornerRadius = 5
            self.contentView.clipsToBounds = true
        }
    }
    
    override func prepareForReuse() {
        self.imageView.image = nil
        self.backgroundColor = .clear
    }

    func setUpCircularProgress(){
        
        if !self.imageView.subviews.contains(circularProgress){
            circularProgress.isHidden = true
            circularProgress.progressColor = (UIColor(named: "LoadingColor") ?? UIColor(red: 0.4235, green: 0.7863, blue: 0.9882, alpha: 1)) /* #e0e0e0 */
            circularProgress.trackColor = .systemFill
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
