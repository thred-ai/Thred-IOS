//
//  SalesVC.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-03-16.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import Firebase


class SalesVC: UIViewController {

    @IBOutlet weak var payoutBtn: UIButton!
    
    
    @IBAction func payoutBalance(_ sender: UIButton) {
    }
    
    @IBOutlet weak var salesLbl: UILabel!
    @IBOutlet weak var pendingLbl: UILabel!
    @IBOutlet weak var availableLbl: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        payoutBtn.layer.cornerRadius = payoutBtn.frame.height / 8
        payoutBtn.clipsToBounds = true
        
        salesLbl.text = " "
        // Do any additional setup after loading the view.
        loadSalesCount()
    }
    
    func loadSalesCount(){
        
        guard let uid = userInfo.uid else{return}
        
        Firestore.firestore().collection("Users/\(uid)/Stripe_Info").document("Seller_Stats").getDocument(completion: { snap, error in
            if error != nil{
                print(error?.localizedDescription ?? "")
            }
            else{
                guard let salesNum = snap?["Sales"] as? Int else{return}
                self.salesLbl.text = "\(salesNum)"
            }
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        
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
