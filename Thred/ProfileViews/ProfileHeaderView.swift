//
//  ProfileHeaderView.swift
//  Thred
//
//  Created by Arta Kouroshnia on 2019-11-02.
//  Copyright © 2019 Thred Apps Inc. All rights reserved.
//

import UIKit
import ColorCompatibility

class ProfileHeaderView: UIView{

    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
    }
    
    @IBOutlet weak var userContentView: UIView!
    @IBOutlet weak var fullnameLbl: UILabel!
    @IBOutlet weak var usernameLbl: UILabel!
    @IBOutlet weak var bioView: UITextView!
    @IBOutlet weak var actionBtn: UIButton!
    @IBOutlet weak var profileImgView: UIImageView!
    var headerActionBtnTitle: String = "Follow"

    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = UIColor.clear
    }
    
    func clearAll(actionBtnTitle: String){
        usernameLbl.text = nil
        fullnameLbl.text = nil
        bioView.text = nil
        actionBtn.setTitle(actionBtnTitle, for: .normal)
        profileImgView.image = nil
        setNeedsLayout()
        layoutIfNeeded()
    }

    func adjustBioHeight(){
        let width = self.bioView.frame.width
        let newBioHeight = self.bioView.sizeThatFits(CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)).height
        if newBioHeight < self.bioView.frame.height{
             let difference = self.bioView.frame.height - newBioHeight
             self.frame.size.height -= difference
        }
        else if newBioHeight > self.bioView.frame.height{
            let difference = newBioHeight - self.bioView.frame.height
            print(self.bioView.frame.height)
            print(newBioHeight)
            print(difference)
            
            self.frame.size.height += difference
        }
    }
    
    func updateFollowBtn(didFollow: Bool, animated: Bool){
        var animationDuration = 0.0
        
        if animated{
            animationDuration = 0.2
        }
        if didFollow{
            headerActionBtnTitle = "Following"
            actionBtn.setTitleColor(.white, for: .normal)
            UIView.animate(withDuration: animationDuration, animations: {
                self.actionBtn.backgroundColor = UIColor(named: "LoadingColor")
            })
        }
        else{
            headerActionBtnTitle = "Follow"
            actionBtn.setTitleColor(ColorCompatibility.label, for: .normal)
            UIView.animate(withDuration: animationDuration, animations: {
                self.actionBtn.backgroundColor = ColorCompatibility.quaternarySystemFill
            })
        }
        self.actionBtn.setTitle(headerActionBtnTitle, for: .normal)
    }
    
    func setUpInfo(username: String?, fullname: String?, bio: String?, notifID: String?, dpUID: String?, image: UIImage?, actionBtnTitle: String){
        usernameLbl.text = "@" + (username ?? "null")
        fullnameLbl.text = fullname ?? "null"
        bioView.text = bio
        actionBtn.setTitle(actionBtnTitle, for: .normal)
        setNeedsLayout()
        layoutIfNeeded()
        guard let img = image else{
            
            return}
        profileImgView.image = img
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        profileImgView.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        adjustBioHeight()
        userContentView.layer.cornerRadius =  userContentView.frame.width / 25
        userContentView.clipsToBounds = true
        profileImgView.layer.cornerRadius =  profileImgView.frame.height / 2
        profileImgView.clipsToBounds = true
        profileImgView.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
        userContentView.backgroundColor = UIColor(named: "ProfileMask")?.withAlphaComponent(0.25)
        profileImgView.layer.borderWidth = profileImgView.frame.width / 17.75
        actionBtn.layer.cornerRadius = actionBtn.frame.height / 4
        actionBtn.clipsToBounds = true
    }
}
