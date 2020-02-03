//
//  SearchTableCellTableViewCell.swift
//  Thred
//
//  Created by Artak on 2019-11-03.
//  Copyright © 2019 ArtaCorp. All rights reserved.
//

//
//  SearchUsersTableViewCell.swift
//  Pictomap
//
//  Created by Artak on 2019-07-23.
//  Copyright © 2019 artacorp. All rights reserved.
//

import UIKit

class SearchUserTableViewCell: UITableViewCell {
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var fullnameLbl: UILabel!
    @IBOutlet weak var usernameLbl: UILabel!
    var spinner = MapSpinnerView.init(frame: CGRect(x: 5, y: 5, width: 40, height: 40))
    
    
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
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)


        // Configure the view for the selected state
    }

}
