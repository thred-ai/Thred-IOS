//
//  SalesCell.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-03-15.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit

class SalesCell: UITableViewCell {

    @IBOutlet weak var shoppingCartBtn: UIImageView!
    
    @IBOutlet weak var salesBtnView: UIView!
    @IBOutlet weak var shoppingCartBtnView: UIView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        let cartTapper = UITapGestureRecognizer.init(target: self, action: #selector(toCart(_:)))
        let salesTapper = UITapGestureRecognizer.init(target: self, action: #selector(toSalesDashboard(_:)))
        
        shoppingCartBtnView.addGestureRecognizer(cartTapper)
        salesBtnView.addGestureRecognizer(salesTapper)

    }
    
    @objc func toCart(_ sender: UITapGestureRecognizer){
        if let vc = self.getViewController() as? NotificationVC{
            vc.performSegue(withIdentifier: "toCart", sender: nil)
        }
    }
    
    @objc func toSalesDashboard(_ sender: UITapGestureRecognizer){
        if let vc = self.getViewController() as? NotificationVC{
            vc.performSegue(withIdentifier: "toSalesDash", sender: nil)
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
