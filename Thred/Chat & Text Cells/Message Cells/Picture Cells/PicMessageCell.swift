//
//  PicMessageCell.swift
//  Artachat
//
//  Created by Arta Koroushnia on 2019-11-15.
//  Copyright © 2019 ArtaCorp. All rights reserved.
//

import UIKit
import PopupDialog

class PicMessageCell: UITableViewCell {

    @IBOutlet weak var userImgView: UIImageView!
    @IBOutlet weak var nameLbl: UILabel!
    
    @IBOutlet weak var aspectConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var textImgView: UIImageView!
    
    @IBOutlet weak var dpSkeletonView: SkeletonView!
    @IBOutlet weak var nameSkeletonView: SkeletonView!

    @IBOutlet var dpMaskingViews: [UIView]!
    @IBOutlet var nameMaskingViews: [UIView]!
    
    var textMessage: TextMessage!
    
    let circularProgress = CircularProgress(frame: CGRect(x: 0, y: 0, width: 60, height: 60))

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectionStyle = .none
        contentView.transform = CGAffineTransform(scaleX: 1, y: -1)
        
        if self.dpMaskingViews != nil{
            if let dpMask = self.dpMaskingViews.first{
                dpMask.layer.cornerRadius = dpMask.frame.height / 2
                dpMask.clipsToBounds = true
            }
        }

        setUpCircularProgress()
        setUpGestureRecognizer()
    }
    
    @objc func openImgMenu(_ sender: UITapGestureRecognizer) {
        (getViewController() as? ChatVC)?.showZoomableView(sender: sender)
    }
    
    func setUpGestureRecognizer(){
        let long = UILongPressGestureRecognizer(target: self, action: #selector(showMessageOptions(_:)))
        long.minimumPressDuration = 0.5
        self.contentView.addGestureRecognizer(long)
        
        let tapper = UITapGestureRecognizer(target: self, action: #selector(openImgMenu(_:)))
        tapper.numberOfTapsRequired = 1
        self.textImgView.addGestureRecognizer(tapper)
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
        let image = msg.messageImg?.crop()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        let button = DefaultButton(title: "SAVE IMAGE", dismissOnTap: true) {
            self.textImgView?.image?.saveToPhotos(completion: { success in
                
            })
        }
        
        let yesBtn = DefaultButton(title: "Delete", dismissOnTap: true) {
            completed()
        }
        
        getViewController()?.showPopUp(title: nil, message: message, image: image, buttons: [button, yesBtn], titleColor: .label, blurBack: true, transitionStyle: PopupDialogTransitionStyle.zoomIn, dismissOnlyBtns: false)
    }

    func setUpCircularProgress(){
        
        if !self.textImgView.subviews.contains(circularProgress){
            circularProgress.progressColor = (UIColor(named: "LoadingColor") ?? UIColor(red: 0.4235, green: 0.7863, blue: 0.9882, alpha: 1)) /* #e0e0e0 */
            circularProgress.trackColor = UIColor.systemFill
            circularProgress.translatesAutoresizingMaskIntoConstraints = false
            self.textImgView.addSubview(circularProgress)
            self.bringSubviewToFront(circularProgress)
            NSLayoutConstraint.activate([
                circularProgress.heightAnchor.constraint(equalToConstant: 60),
                circularProgress.widthAnchor.constraint(equalToConstant: 60),
                circularProgress.centerXAnchor.constraint(equalTo: self.textImgView.centerXAnchor),
                circularProgress.centerYAnchor.constraint(equalTo: self.textImgView.centerYAnchor)
            ])
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        
        if userImgView != nil{
            userImgView.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
        }
        textImgView.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if userImgView != nil{
            userImgView.layer.cornerRadius = userImgView.frame.height / 2
            userImgView.clipsToBounds = true
            userImgView.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
            userImgView.layer.borderWidth = userImgView.frame.height / 17.75
        }
        
        textImgView.layer.cornerRadius = 20
        textImgView.clipsToBounds = true
        textImgView.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
        textImgView.layer.borderWidth = 1.5
    }
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        if self.textImgView.subviews.contains(circularProgress){
            circularProgress.setProgressWithAnimation(duration: 0, value: 0, from: 0, finished: true){
                
            }
        }
    }
}
