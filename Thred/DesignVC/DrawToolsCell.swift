//
//  DrawToolsCell.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-05-11.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit

class DrawToolsCell: UICollectionViewCell {

    @IBOutlet weak var toolBtn: UIButton!
    weak var vc: UIViewController!
    
    var tool: [String : Any]?{
        didSet{
            let image = tool?["Image"] as? UIImage
            let btnTint = tool?["Icon_Color"] as? UIColor
            toolBtn.imageView!.image = image
            toolBtn.setImage(image, for: .normal)
            toolBtn.tintColor = btnTint
        }
    }
    
    
    @IBAction func toolTapped(_ sender: UIButton) {
        guard let name = tool?["Name"] as? String else{return}
        if let vc = vc as? DesignViewController{
            switch name {
            case "Clear":
                vc.clearDrawing()
            case "Undo":
                vc.undoColors(sender)
            case "Redo":
                vc.redoColors()
            case "Pen":
                vc.switchBrush(sender)
            case "Pen_Color":
                vc.showOrHideSlider(sender)
            case "Ruler":
                vc.activateStraightLine(sender)
            default:
                return
            }
        }
    }
    
    override func layoutSubviews() {
        toolBtn.layer.cornerRadius = toolBtn.frame.height / 2
        toolBtn.clipsToBounds = true
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        toolBtn.imageView?.contentMode = .scaleAspectFit
    }
}
