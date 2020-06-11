//
//  FinishedPurchaseVC.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-06-04.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit

class FinishedPurchaseVC: UIViewController {
    var orderNumber: String?
    @IBOutlet weak var orderNumberField: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        let orderNumber = self.orderNumber ?? ""
        unboldTitle(orderNumber: orderNumber)
        // Do any additional setup after loading the view.
    }

    func unboldTitle(orderNumber: String){
        let linkWords = "Order #:"
        orderNumberField.text = nil
        let guideLineText = "Order #: \(orderNumber)"
        
        orderNumberField.text = guideLineText
        let attrString = NSMutableAttributedString()
        if let text = orderNumberField.attributedText{
            attrString.setAttributedString(text)
        }
        
        let nsText = NSString(string: guideLineText)
        let matchRange:NSRange = nsText.range(of: linkWords)
        
        guard let font = UIFont(name: "NexaW01-Regular", size: orderNumberField.font?.pointSize ?? 16) else{return}
        
        let attributes = [
            NSAttributedString.Key.font : font,
        ] as [NSAttributedString.Key : Any]
        
        attrString.addAttributes(attributes, range: matchRange)

        orderNumberField.attributedText = attrString
    }
    
    @IBAction func backToHome(_ sender: UIButton) {
        
        if let vc = (self.tabBarController?.selectedViewController as? UINavigationController)?.viewControllers.first{
            navigationController?.popToViewController(vc, animated: true)
        }
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
