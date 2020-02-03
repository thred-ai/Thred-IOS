//
//  ViewController2.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-01-06.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import WebKit
import Stripe
import Firebase

var uid = UserDefaults.standard.string(forKey: "UID") //Set


class ViewController2: UIViewController, WKNavigationDelegate {

    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        webView.navigationDelegate = self
        // Do any additional setup after loading the view.
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
        
        let data = ["code" : code,
                    "uid" : uid]
        Functions.functions().httpsCallable("verifyStripeAccount").call(data, completion: { result, error  in
            if error != nil{
                print(error?.localizedDescription ?? "")
            }
            else{
                //Done
            }
        })
    }
    
    
    var requestIDString = ""
    
    override func viewDidAppear(_ animated: Bool) {
        
        let email = "artakorp@gmail.com"
        requestIDString = NSUUID().uuidString
        let accountType = "company"
        
        guard let url = URL(string: "https://connect.stripe.com/express/oauth/authorize?redirect_uri=https://connect.stripe.com/connect/default/oauth/test&client_id=ca_GNV7BNqwGxdwvAojN6YJYzO4CdDuLFB6&state=\(requestIDString)&stripe_user[business_type]=\(accountType)&stripe_user[email]=\(email)")

        else{return}
        
            let request = URLRequest(url: url)
            self.webView?.load(request)
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
