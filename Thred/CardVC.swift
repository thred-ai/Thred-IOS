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

class CardVC: UIViewController, STPAddCardViewControllerDelegate, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var doneBtn: UIBarButtonItem!
    @IBOutlet weak var actionBtn: UIButton!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var errorView: UITextView!
    @IBOutlet weak var spinner: MapSpinnerView!
    var hasCard = false
    
    @IBOutlet weak var tableView: UITableView!
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == 0{
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cardCell")
            
            let lastFour = UserDefaults.standard.string(forKey: "CARD_LAST_4")
            cell.textLabel?.text = "Card Number"
            cell.textLabel?.textColor = .secondaryLabel
            cell.detailTextLabel?.textColor = .label
            cell.textLabel?.font = UIFont(name: "NexaW01-Regular", size: 13)
            cell.detailTextLabel?.font = UIFont(name: "NexaW01-Regular", size: 16)
            if let four = lastFour{
                cell.detailTextLabel?.text = "•••• •••• •••• \(four)"
            }
            else{
                cell.detailTextLabel?.text = "None"
            }
            return cell
        }
        else{
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "expiryCell")
            cell.textLabel?.textColor = .secondaryLabel
            cell.detailTextLabel?.textColor = .label
            cell.textLabel?.font = UIFont(name: "NexaW01-Regular", size: 13)
            cell.detailTextLabel?.font = UIFont(name: "NexaW01-Regular", size: 16)
            
            let expMonth = UserDefaults.standard.integer(forKey: "CARD_EXP_MONTH")
            let expYear = UserDefaults.standard.integer(forKey: "CARD_EXP_YEAR")
            if expMonth != 0, expYear != 0{
                cell.detailTextLabel?.text = "\(expMonth)/\(expYear)"
            }
            else{
                cell.detailTextLabel?.text = "None"
            }
            cell.textLabel?.text = "Expiry Date"

            
            
            return cell
        }
    }
    
    
    
    @IBAction func doneBtnPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        
        if let vc = viewController as? ShoppingCartVC{
            if UserDefaults.standard.string(forKey: "CARD_BRAND") != nil, UserDefaults.standard.string(forKey: "CARD_LAST_4") != nil, UserDefaults.standard.string(forKey: "CARD_POSTAL_CODE") != nil, UserDefaults.standard.string(forKey: "CARD_EXP_MONTH") != nil, UserDefaults.standard.string(forKey: "CARD_EXP_YEAR") != nil{
                navigationController.delegate = nil
                vc.performSegue(withIdentifier: "toCheckout", sender: nil)
            }
            else{
                vc.checkoutBtn.isEnabled = true
            }
        }
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
        let data = ["uid" : pUserInfo.uid ?? ""]
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
                UserDefaults.standard.removeObject(forKey: "CARD_EXP_MONTH")
                UserDefaults.standard.removeObject(forKey: "CARD_EXP_YEAR")
                
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
        
        if UserDefaults.standard.string(forKey: "CARD_BRAND") != nil, UserDefaults.standard.string(forKey: "CARD_LAST_4") != nil, UserDefaults.standard.string(forKey: "CARD_EXP_MONTH") != nil, UserDefaults.standard.string(forKey: "CARD_EXP_YEAR") != nil{
            //cardType.text = bankInst.capitalizingFirstLetter()
            
            setActionBtnTitle("Remove Card")
            hasCard = true
            doneBtn.isEnabled = true
            hideLoadingView()
        }
        else{
            setActionBtnTitle("Add Card")
            doneBtn.isEnabled = false
            hasCard = false
        }
        tableView.reloadData()
    }
    
    func stripeCardAuth(token: String){
        self.showLoadingView()
        self.errorView.text = nil
        let data = ["token" : token,
                    "uid" : pUserInfo.uid ?? ""]
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
        let data = ["uid" : pUserInfo.uid ?? ""]
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
                        let expMonth = card["exp_month"] as? Int
                        let expYear = card["exp_year"] as? Int

                        UserDefaults.standard.set(cardBrand, forKey: "CARD_BRAND")
                        UserDefaults.standard.set(cardLast4, forKey: "CARD_LAST_4")
                        UserDefaults.standard.set(postalCode, forKey: "CARD_POSTAL_CODE")
                        UserDefaults.standard.set(expMonth, forKey: "CARD_EXP_MONTH")
                        UserDefaults.standard.set(expYear, forKey: "CARD_EXP_YEAR")
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
        theme.accentColor = UIColor(named: "LoadingColor")!
        let config = STPPaymentConfiguration()
        config.requiredBillingAddressFields = .full
        let addCardViewController = STPAddCardViewController(configuration: config, theme: theme)
        addCardViewController.delegate = self
        return addCardViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController!.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        errorView.text = nil
        doneBtn.isEnabled = false
        hideCenterBtn()
        getCardInfo()
        // Do any additional setup after loading the view.
        
        tableViewHeight.constant = 50 * 2
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !hasCard else{
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        
        show(addCardViewController(), sender: nil)
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    
    
    
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
