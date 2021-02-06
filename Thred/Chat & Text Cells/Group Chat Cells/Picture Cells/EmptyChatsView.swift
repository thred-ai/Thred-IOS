//
//  EmptyChatsView.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-09-02.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit

class EmptyChatsView: UIView {

    @IBOutlet weak var infoView: UITextView!
    
    
    override func awakeFromNib() {
        setAdd()
    }
    
    func setAdd(){
        
        
        infoView.textColor = .red
        let text1 = "Message somebody by pressing the "
        let text2 = " button above"
        
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = UIImage(systemName: "square.and.pencil")?.withTintColor(.secondaryLabel)
        let sizeSide: CGFloat = 20
        let iconsSize = CGRect(x: CGFloat(0),
                               y: ((infoView.font?.capHeight ?? 0) - sizeSide) / 2,
                               width: sizeSide,
                               height: sizeSide)
        imageAttachment.bounds = iconsSize

        let fullString = NSMutableAttributedString(string: text1)
        fullString.append(NSAttributedString(attachment: imageAttachment))
        let fullString2 = NSMutableAttributedString(string: text2)
        fullString.append(fullString2)
        
        fullString.addAttributes([
            .foregroundColor : UIColor.label,
            .font : UIFont(name: "NexaW01-Regular", size: infoView.font?.pointSize ?? 16)!
        ], range: NSRange(location: 0, length: fullString.length))
        
        infoView.attributedText = fullString
        infoView.textAlignment = .center
        
        
        
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
