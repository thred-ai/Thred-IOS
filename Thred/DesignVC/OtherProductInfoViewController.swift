//
//  OtherProductInfoVCViewController.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-02-08.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit

class OtherProductInfoViewController: UIViewController {

    var product: ProductInProgress?
    @IBOutlet weak var titleView: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let title = product?.name{
            titleView.text = title
        }
        if let displayImage = product?.designOnShirt{
            imageView.image = displayImage
        }
        
        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
