//
//  BankVC.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-05-20.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import WebKit
import Firebase
import Stripe
import ColorCompatibility

class BankVC: UIViewController, WKNavigationDelegate {
    @IBOutlet weak var errorView: UITextView!
    
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var spinner: MapSpinnerView!
    
    @IBOutlet weak var actionBtn: UIButton!
    var hasBankAccount = false
    
    @IBAction func bankInfoAction(_ sender: UIButton) {
        sender.isEnabled = false
        if hasBankAccount{
            deleteBankAccount{
                sender.isEnabled = true
            }
        }
        else{
            showStripeView{
                sender.isEnabled = true
            }
        }
    }
    
    func deleteBankAccount(completed: @escaping () -> ()){
        showLoadingView()
        let data = ["uid" : userInfo.uid ?? ""]
        Functions.functions().httpsCallable("removeBankAccount").call(data, completion: { result, error  in
            if error != nil{
                print(error?.localizedDescription ?? "")
            }
            else{
                UserDefaults.standard.removeObject(forKey: "BANK_INSTITUTION")
                UserDefaults.standard.removeObject(forKey: "BANK_LAST_4")
                completed()
                self.setup()
            }
        })
    }

    
    func showStripeView(completed: @escaping () -> ()){
        requestIDString = NSUUID().uuidString
        
        DispatchQueue(label: "Info").async {
            guard let stripeID = Bundle.main.object(forInfoDictionaryKey: "StripeIdentifierLive") else{return}
            //let stripeID = "ca_GNV7BNqwGxdwvAojN6YJYzO4CdDuLFB6"
            let url = URL(string: "https://connect.stripe.com/express/oauth/authorize?redirect_uri=https://connect.stripe.com/connect/default/oauth/test&client_id=\(stripeID)&state=\(self.requestIDString)&stripe_user[business_type]=\(self.accountType)&stripe_user[email]=\(self.email)")!
            let request = URLRequest(url: url)
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.25, animations: {
                    self.navigationController?.setNavigationBarHidden(true, animated: true)
                    self.webViewBack.frame.origin.y = self.view.safeAreaInsets.top
                })
                self.webView.load(request)
                completed()
            }
        }
    }
    
    @IBOutlet weak var instField: UILabel!
    @IBOutlet weak var lastFourField: UILabel!

    override func viewWillAppear(_ animated: Bool) {
        setup()
    }
    
    func setup(){
        if let bankInst = UserDefaults.standard.string(forKey: "BANK_INSTITUTION"), let lastFour = UserDefaults.standard.string(forKey: "BANK_LAST_4"){
            instField.text = bankInst
            lastFourField.text = lastFour
            setActionBtnTitle("Remove Bank Account")
            hasBankAccount = true
            loadingView.isHidden = true
        }
        else{
            instField.text = "None"
            lastFourField.text = "None"
            setActionBtnTitle("Add Bank Account")
            hasBankAccount = false
        }
    }
    
    func setActionBtnTitle(_ text: String){
        
        actionBtn.titleLabel?.text = text
        actionBtn.setTitle(text, for: .normal)
    }
    
    override func viewDidLayoutSubviews() {
        actionBtn.layer.cornerRadius = actionBtn.frame.height / 8
        actionBtn.clipsToBounds = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        hidesBottomBarWhenPushed = true
        errorView.text = nil
        hideCenterBtn()
        view.addSubview(webViewBack)
        getBankInfo()
        // Do any additional setup after loading the view.
    }
    
    var webView: WKWebView!

    lazy var webViewBack: UIView = {
        let back = UIView(frame: CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: view.frame.height))
        back.backgroundColor = ColorCompatibility.systemBackground

        let stackView = UIStackView(frame: back.bounds)
        stackView.axis = .vertical
        stackView.spacing = 10
        
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: back.frame.width, height: 30))
        button.backgroundColor = ColorCompatibility.systemBackground

        button.setImage(UIImage.init(nameOrSystemName: "chevron.down", systemPointSize: 22, iconSize: 9), for: .normal)
        button.tintColor = UIColor(named: "LoadingColor")
        button.addTarget(self, action: #selector(hideStripeView(_:)), for: .touchUpInside)
        webView = WKWebView.init(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        webView.navigationDelegate = self
        back.addSubview(stackView)
        stackView.addArrangedSubview(button)
        stackView.addArrangedSubview(webView)
        return back
    }()
    
    @objc func hideStripeView(_ sender: UIButton?){
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.25, animations: {
                self.navigationController?.setNavigationBarHidden(false, animated: true)
                self.webViewBack.frame.origin.y = self.view.frame.height
            })
        }
    }
            
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
        if let url = navigationAction.request.url?.absoluteString{
            if url.contains("code="){
                let cmpts = url.components(separatedBy: "&").reversed()
                
                for str in cmpts{
                    print(str)
                    if str.contains("state="){
                        let state = str.replacingOccurrences(of: "=", with: "").replacingOccurrences(of: "state", with: "")
                        print("New ID: \(state)")
                        print("Old ID: \(requestIDString)")
                        if requestIDString == state{
                            //state code is the same
                            continue
                        }
                        else{
                            //Hack attempt
                            break
                        }

                    }
                    else if str.contains("code="){
                        let underScore = (str.firstIndex(of: "="))!
                        let code = str[underScore...].replacingOccurrences(of: "=", with: "")
                        self.stripeAccountAuth(code: String(code))
                    }
                }
            }
        }
    }
    
    func stripeAccountAuth(code: String){
        self.hideStripeView(nil)
        self.showLoadingView()
        self.errorView.text = nil
        let data = ["code" : code,
                    "uid" : userInfo.uid ?? ""]
        Functions.functions().httpsCallable("verifyStripeAccount").call(data, completion: { result, error  in
            if let err = error{
                print(err)
                self.errorView.text = err.localizedDescription
            }
            else{
                self.getBankInfo()
            }
        })
    }
    
    func getBankInfo(){
        let data = ["uid" : userInfo.uid ?? ""]
        Functions.functions().httpsCallable("getBankInfo").call(data, completion: { result, error  in
            if error != nil{
                print(error?.localizedDescription ?? "")
                self.hideLoadingView()
            }
            else{
                if let res = result?.data as? [String:Any]{
                    if let accounts = res["external_accounts"] as? [String : Any]{
                        if let data = accounts["data"] as? [[String:Any]]{
                            guard let firstAccount = data.first, let bankAccount = firstAccount["bank_name"] as? String, let lastFour = firstAccount["last4"] as? String else{return}
                            UserDefaults.standard.set(bankAccount, forKey: "BANK_INSTITUTION")
                            UserDefaults.standard.set(lastFour, forKey: "BANK_LAST_4")
                            self.setup()
                        }
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
    
    
    var requestIDString = ""
    let email = Auth.auth().currentUser?.email ?? ""
    let accountType = "individual"

    override func viewDidDisappear(_ animated: Bool) {
        
        
    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        
        
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
