//
//  CardVC.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-05-29.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import Firebase
import Stripe

class CardVC: UIViewController, STPAddCardViewControllerDelegate {

    @IBOutlet weak var doneBtn: UIBarButtonItem!
    @IBOutlet weak var postalCodeField: UILabel!
    @IBOutlet weak var actionBtn: UIButton!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var errorView: UITextView!
    @IBOutlet weak var spinner: MapSpinnerView!
    var hasCard = false
    @IBOutlet weak var lastFourField: UILabel!
    @IBOutlet weak var cardType: UILabel!
    
    @IBAction func doneBtnPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func cardInfoAction(_ sender: UIButton) {
        sender.isEnabled = false
        if hasCard{
            deleteCard{
                sender.isEnabled = true
            }
        }
        else{
            sender.isEnabled = true
            show(addCardViewController(), sender: nil)
        }
    }
    
    func deleteCard(completed: @escaping () -> ()){
        let data = ["uid" : userInfo.uid ?? ""]
        doneBtn.isEnabled = false
        showLoadingView()
        Functions.functions().httpsCallable("removeCard").call(data, completion: { result, error  in
            if error != nil{
                self.hideLoadingView()
                print(error?.localizedDescription ?? "")
            }
            else{
                UserDefaults.standard.removeObject(forKey: "CARD_BRAND")
                UserDefaults.standard.removeObject(forKey: "CARD_LAST_4")
                UserDefaults.standard.removeObject(forKey: "CARD_POSTAL_CODE")
                self.hideLoadingView()
                completed()
                self.setup()
            }
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setup()
    }
    
    @IBAction func unwindToCard(segue:  UIStoryboardSegue) {
        

        
    }
    
    func setActionBtnTitle(_ text: String){
        
        actionBtn.titleLabel?.text = text
        actionBtn.setTitle(text, for: .normal)
    }
    
    override func viewDidLayoutSubviews() {
        actionBtn.layer.cornerRadius = actionBtn.frame.height / 8
        actionBtn.clipsToBounds = true
    }
    
    
    
    func setup(){
        
        if let bankInst = UserDefaults.standard.string(forKey: "CARD_BRAND"), let lastFour = UserDefaults.standard.string(forKey: "CARD_LAST_4"), let postalCode = UserDefaults.standard.string(forKey: "CARD_POSTAL_CODE"){
            cardType.text = bankInst.capitalizingFirstLetter()
            lastFourField.text = "**** **** **** \(lastFour)"
            postalCodeField.text = postalCode
            setActionBtnTitle("Remove Card")
            hasCard = true
            doneBtn.isEnabled = true
            hideLoadingView()
        }
        else{
            cardType.text = "None"
            lastFourField.text = "None"
            postalCodeField.text = "None"
            setActionBtnTitle("Add Card")
            doneBtn.isEnabled = false
            hasCard = false
        }
    }
    
    func stripeCardAuth(token: String){
        self.showLoadingView()
        self.errorView.text = nil
        let data = ["token" : token,
                    "uid" : userInfo.uid ?? ""]
        Functions.functions().httpsCallable("verifyCard").call(data, completion: { result, error  in
            if let err = error{
                print(err)
                self.errorView.text = err.localizedDescription
            }
            else{
                self.getCardInfo()
            }
        })
    }
    
    func getCardInfo(){
        let data = ["uid" : userInfo.uid ?? ""]
        Functions.functions().httpsCallable("getCardInfo").call(data, completion: { result, error  in
            if error != nil{
                print(error?.localizedDescription ?? "")
                self.hideLoadingView()
            }
            else{
                if let res = result?.data as? [String:Any]{
                    if let card = res["card"] as? [String : Any], let billingDetails = res["billing_details"] as? [String : Any], let address = billingDetails["address"] as? [String : Any]{
                        let cardBrand = card["brand"] as? String
                        let cardLast4 = card["last4"] as? String
                        let postalCode = address["postal_code"] as? String

                        UserDefaults.standard.set(cardBrand, forKey: "CARD_BRAND")
                        UserDefaults.standard.set(cardLast4, forKey: "CARD_LAST_4")
                        UserDefaults.standard.set(postalCode, forKey: "CARD_POSTAL_CODE")
                        self.setup()
                    }
                    else{
                        self.hideLoadingView()
                    }
                }
                else{
                    self.hideLoadingView()
                }
            }
        })
    }
    
    func showLoadingView(){
        self.loadingView.isHidden = false
        self.spinner.animate()
    }
    
    func hideLoadingView(){
        self.loadingView.isHidden = true
    }
    
    
    func addCardViewController() -> STPAddCardViewController{
        let theme = STPTheme()
        theme.accentColor = UIColor(named: "LoadingColor")
        let config = STPPaymentConfiguration()
        let addCardViewController = STPAddCardViewController(configuration: config, theme: theme)
        addCardViewController.delegate = self
        return addCardViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        errorView.text = nil
        doneBtn.isEnabled = false
        hideCenterBtn()
        getCardInfo()
        // Do any additional setup after loading the view.
    }
    
    
    func addCardViewController(_ addCardViewController: STPAddCardViewController, didCreatePaymentMethod paymentMethod: STPPaymentMethod, completion: @escaping STPErrorBlock) {
        
        let token = paymentMethod.stripeId
        print(token)
        
        stripeCardAuth(token: token)

        if let vc = navigationController?.topViewController as? STPAddCardViewController{
            vc.delegate = nil
        }
        navigationController?.popViewController(animated: true)
        
    }
    
    func addCardViewControllerDidCancel(_ addCardViewController: STPAddCardViewController) {
        if let vc = navigationController?.topViewController as? STPAddCardViewController{
            vc.delegate = nil
        }
        navigationController?.popViewController(animated: true)
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
