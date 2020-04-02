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
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        userImageView.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)


        // Configure the view for the selected state
    }

}
