//
//  SearchTableCellTableViewCell.swift
//  Thred
//
//  Created by Arta Kouroshnia on 2019-11-03.
//  Copyright © 2019 Thred Apps Inc. All rights reserved.
//

//
//  SearchUsersTableViewCell.swift
//  Thred
//
//  Created by Arta Kouroshnia on 2019-07-23.
//  Copyright © 2019 Thred Apps Inc. All rights reserved.
//

import UIKit

class SearchUserTableViewCell: UITableViewCell {
    
    @IBOutlet weak var followBtn: UIButton!
    
    var friendInfo: UserInfo!
    
    @IBAction func followUser(_ sender: UIButton?) {
        guard let listVC = getViewController() as? UserListVC else{return}
        let following = pUserInfo.userFollowing
        guard let uid = friendInfo.uid else{
            return}
        let didFollow = !following.contains(uid)
        updateFollowBtn(didFollow: didFollow, animated: true)
        listVC.updateFollowInDatabase(friendInfo: friendInfo, didFollow: didFollow)
    }
    
    func checkFollow(){
        guard let uid = friendInfo.uid else{
            return}
        if pUserInfo.uid == uid{
            followBtn.isHidden = true
            return
        }
        let following = pUserInfo.userFollowing
        let didFollow = following.contains(uid)
        updateFollowBtn(didFollow: didFollow, animated: false)
    }
    
    var headerActionBtnTitle: String = "Loading"

    
    func updateFollowBtn(didFollow: Bool, animated: Bool){
        var animationDuration = 0.0
        
        if animated{
            animationDuration = 0.2
        }
        if didFollow{
            headerActionBtnTitle = "Following"
            followBtn?.setTitleColor(.white, for: .normal)
            UIView.animate(withDuration: animationDuration, animations: {
                self.followBtn?.backgroundColor = UIColor(named: "LoadingColor")
            })
        }
        else{
            headerActionBtnTitle = "Follow"
            followBtn?.setTitleColor(.label, for: .normal)
            UIView.animate(withDuration: animationDuration, animations: {
                self.followBtn?.backgroundColor = .quaternarySystemFill
            })
        }
        followBtn?.titleLabel?.text = headerActionBtnTitle
        followBtn?.setTitle(headerActionBtnTitle, for: .normal)
    }
    
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var fullnameLbl: UILabel!
    @IBOutlet weak var usernameLbl: UILabel!
    var spinner = MapSpinnerView.init(frame: CGRect(x: 5, y: 5, width: 20, height: 20))
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        userImageView.addSubview(spinner)

    }

    override func layoutSubviews() {
        spinner.center = userImageView.center
        spinner.alpha = 0.75
        userImageView.layer.cornerRadius = userImageView.frame.height / 2
        userImageView.clipsToBounds = true
        userImageView.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
        userImageView.layer.borderWidth = userImageView.frame.height / 17.75
        followBtn.layer.cornerRadius = followBtn.frame.height / 8
        followBtn.clipsToBounds = true
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        userImageView.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)


        // Configure the view for the selected state
    }

}
