//
//  UITextField+Extension.swift
//  textViewSample
//
//  Created by Robert Chen on 5/22/15.
//  Copyright (c) 2015 Thorn Technologies. All rights reserved.
//

import UIKit

extension UITextView {

    func addLinks(isNotification: Bool) {

        // turn string in to NSString
        let nsText = NSString(string: text)

        // this needs to be an array of NSString.  String does not work.
        let words = nsText.components(separatedBy: CharacterSet(charactersIn: "#@ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_.").inverted)

        // you can staple URLs onto attributed strings
        let attrString = NSMutableAttributedString()
        attrString.setAttributedString(attributedText)

        // tag each word if it has a hashtag
        
        for word in words {
            if word.count < 2 {
                continue
            }
            switch isNotification{
                
            case false:
                if word.hasPrefix("@"){
                    fallthrough
                }
            default:
                
                if isNotification && word != words.first{break}
                let matchRange:NSRange = nsText.range(of: word as String)
                let stringifiedWord = word.replacingOccurrences(of: "@", with: "")
                guard let font = UIFont(name: "NexaW01-Heavy", size: self.font?.pointSize ?? 16) else{return}
                let attributes = [
                    NSAttributedString.Key.link : "mention:\(stringifiedWord)",
                    NSAttributedString.Key.font : font
                ] as [NSAttributedString.Key : Any]
                attrString.addAttributes(attributes, range: matchRange)
            }
        }

        // we're used to textView.text
        // but here we use textView.attributedText
        // again, this will also wipe out any fonts and colors from the storyboard,
        // so remember to re-add them in the attrs dictionary above
        self.attributedText = attrString
        self.linkTextAttributes = [
            NSAttributedString.Key.foregroundColor : UIColor(named: "LoadingColor")!
        ]
    }
}
