//
//  ExploreViewController.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-01-16.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import Firebase
import Stripe

class ExploreViewController: UIViewController, STPPaymentCardTextFieldDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    func addDebitCard(){
        let form = STPPaymentCardTextField.init(frame: CGRect(x: 10, y: 0, width: self.view.frame.width - 20, height: 45))
    }
    

    @IBAction func testCharge(_ sender: UIButton) {
     
        let data = [
            "product_id":"akskdjsj",
            "amount": 99999900,
            "source":"tok_visa",
            "customer_id": "cus_GXHvUh9RzbfEU0",
            "merchant_id": "acct_1FyBVRAIhu8eWpr1",
            "customer_uid" : "aR6FMc9OR2VmBUrHCk8l3KQIDPj1",
            "merchant_uid" : "fB6BIMoZ38gulk7Km0ReSIVceNe2"
            ] as [String : Any]
        Functions.functions().httpsCallable("createCharge").call(data, completion: { result, error in
            
            if error != nil{
                print(error?.localizedDescription ?? "")
                
                
            }
            else{
                
                
                
            }
        })
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
