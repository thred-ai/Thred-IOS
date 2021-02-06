//
//  TextMessageCell.swift
//  Artachat
//
//  Created by Arta Koroushnia on 2019-11-13.
//  Copyright © 2019 ArtaCorp. All rights reserved.
//

import UIKit
import PopupDialog

class TextMessageCell: UITableViewCell {
    
    @IBOutlet weak var userImgView: UIImageView!
    
    @IBOutlet weak var textViewBack: UIView!
    
    @IBOutlet weak var textMsgView: UITextView!
    @IBOutlet weak var nameLbl: UILabel!
    
    @IBOutlet weak var nameSkeletonView: SkeletonView!
    @IBOutlet weak var dpSkeletonView: SkeletonView!
    
    @IBOutlet weak var leftTextConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightTextConstraint: NSLayoutConstraint!
    @IBOutlet weak var topTextConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomTextConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var textExpansionConstraint: NSLayoutConstraint!
    var textMessage: TextMessage!
    
    @IBOutlet var nameMaskingViews: [UIView]!
    @IBOutlet var dpMaskingViews: [UIView]!

    var originalTextViewBackgroundColor: UIColor!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.selectionStyle = .none
        print(self.frame.width)
        self.originalTextViewBackgroundColor = self.textViewBack.backgroundColor
        contentView.transform = CGAffineTransform(scaleX: 1, y: -1)

        textMsgView.font = UIFont(name: "NexaW01-Regular", size: 14)

        if dpMaskingViews != nil{
            if let dpMask = self.dpMaskingViews.first{
                dpMask.layer.cornerRadius = dpMask.frame.height / 2
                dpMask.clipsToBounds = true
            }
            
        }
        textViewBack.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
        //textViewBack.layer.borderWidth = 1.5
        setUpGestureRecognizer()
    }
    
    func setUpGestureRecognizer(){
        let long = UILongPressGestureRecognizer(target: self, action: #selector(showMessageOptions(_:)))
        long.minimumPressDuration = 0.5
        self.contentView.addGestureRecognizer(long)
    }
    
    @objc func showMessageOptions(_ sender: UILongPressGestureRecognizer){
        if sender.state == .began{
            guard textMessage.uid == pUserInfo.uid else{return}
            showOptionsView(msg: textMessage, completed: {
                (self.getViewController() as? ChatVC)?.unsendMessage(message: self.textMessage)
            })
        }
    }
    
    
    func showOptionsView(msg: TextMessage, completed: @escaping () -> ()){
        let message = msg.message
        let image = msg.messageImg
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        let yesBtn = DefaultButton(title: "Delete", dismissOnTap: true) {
            completed()
        }
        
        getViewController()?.showPopUp(title: nil, message: message, image: image, buttons: [yesBtn], titleColor: .label, blurBack: true, transitionStyle: PopupDialogTransitionStyle.zoomIn, dismissOnlyBtns: false)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        
        if userImgView != nil{
            userImgView.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
        }
        textViewBack.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
    }
    
    override func layoutSubviews() {
        
        if userImgView != nil{

            userImgView.layer.cornerRadius = userImgView.frame.height / 2
            userImgView.clipsToBounds = true
            userImgView.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
            userImgView.layer.borderWidth = userImgView.frame.height / 17.75
        }
    }
    
    func adjustExpansionAndCNForEmoji(){
        
        textViewBack.layer.cornerRadius = 0.0
        textViewBack.clipsToBounds = true
        if self.reuseIdentifier == "textmsg"{
            self.textExpansionConstraint.constant = self.frame.width / 5
        }
        else{
            self.textExpansionConstraint.constant = self.frame.width / 3
           
        }
    }
    
    //diff 45

    func adjustExpansionAndCNForText(){
        textViewBack.layer.cornerRadius = 20.0
        textViewBack.clipsToBounds = true
        if self.reuseIdentifier == "textmsg"{
            self.textExpansionConstraint.constant = self.frame.width / (375 / 55)
        }
        else{
            self.textExpansionConstraint.constant = self.frame.width / 3.75
        }
    }
    
    func checkForEmoji(text: String){

        if text.containsOnlyEmoji{
            textMsgView.font = UIFont.systemFont(ofSize: 40.0)
           // textViewBack.layer.borderWidth = 0.0
            self.textViewBack.backgroundColor = UIColor.clear
            textMsgView.textContainer.lineFragmentPadding = 0.0
            textMsgView.textContainerInset = .zero
            leftTextConstraint.constant = 0.0
            rightTextConstraint.constant = 0.0
            topTextConstraint.constant = 0.0
            bottomTextConstraint.constant = 0.0
            self.adjustExpansionAndCNForEmoji()
        }
        else{
            textMsgView.font = UIFont.systemFont(ofSize: 14.0)
            self.textViewBack.backgroundColor = self.originalTextViewBackgroundColor
            //textViewBack.layer.borderWidth = 1.5
            textMsgView.textContainer.lineFragmentPadding = 5.0
            textMsgView.textContainerInset = UIEdgeInsets(top: 8.0, left: 0.0, bottom: 8.0, right: 0.0)
            leftTextConstraint.constant = 10.0
            rightTextConstraint.constant = 10.0
            topTextConstraint.constant = 5.0
            bottomTextConstraint.constant = 5.0
            self.adjustExpansionAndCNForText()
        }
    }
    
    func adjustTextAlignment(text: String){
        guard let font = textMsgView.font else{
            
            return}
        if text.numberOfLines(font: font, width: textMsgView.frame.width) == 1.0{
            textMsgView.textAlignment = .center
        }
        else{
            textMsgView.textAlignment = .left
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}

extension Character {
    
    var isSimpleEmoji: Bool {
        guard let firstProperties = unicodeScalars.first?.properties else {
            return false
        }
        return unicodeScalars.count == 1 &&
            (firstProperties.isEmojiPresentation ||
                firstProperties.generalCategory == .otherSymbol)
    }
    var isCombinedIntoEmoji: Bool {
        return unicodeScalars.count > 1 &&
            unicodeScalars.contains { $0.properties.isJoinControl || $0.properties.isVariationSelector }
    }
    var isEmoji: Bool {
        return isSimpleEmoji || isCombinedIntoEmoji
    }
}

extension String {
    var containsOnlyEmoji: Bool {
        return !isEmpty && !contains { !$0.isEmoji }
    }
}
