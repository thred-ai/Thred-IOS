//
//  SettingsVC.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-04-03.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import ColorCompatibility
import FirebaseAuth

class SettingsVC: UITableViewController {

    var checkingAuthStatus = true
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        tableView.separatorStyle = .none
        
        self.checkingAuthStatus = false
        if let user = Auth.auth().currentUser{
            if user.phoneNumber != nil{
                self.itemsArray.insert([
                    "Title": "Update Missing Info",
                    "Function" : self.updateMissing,
                    "Background Color" : UIColor.red,
                    "Text Color" : UIColor.white
                ], at: 0)
            }
            else{
                self.itemsArray.insert([
                    "Title": "Change email address",
                    "Function" : self.toEmailChange,
                    "Background Color" : UIColor.clear,
                    "Text Color" : ColorCompatibility.label
                ], at: 0)
                self.itemsArray.insert([
                    "Title": "Change password",
                    "Function" : self.toPasswordChange,
                    "Background Color" : UIColor.clear,
                    "Text Color" : ColorCompatibility.label
                ], at: 1)
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if checkingAuthStatus{
            return 0
        }
        return itemsArray.count
    }
    
    
    lazy var itemsArray = [
        
        [
            "Title": "Community Guidelines",
            "Function" : toCommunityGuidelines,
            "Background Color" : UIColor.clear,
            "Text Color" : ColorCompatibility.label
        ],
        
        [
            "Title": "Privacy Policy",
            "Function" : toPrivacyPolicy,
            "Background Color" : UIColor.clear,
            "Text Color" : ColorCompatibility.label
        ],
        
        [
            "Title": "Setup my merchant account",
            "Function" : configureMerchantAcct,
            "Background Color" : UIColor.clear,
            "Text Color" : ColorCompatibility.secondaryLabel
        ],
        
        [
            "Title": "Add a card",
            "Function": addCard,
            "Background Color" : UIColor.clear,
            "Text Color" : ColorCompatibility.secondaryLabel
        ],
        
        [
            "Title": "Sign out",
            "Function" : logOut,
            "Background Color" : UIColor.clear,
            "Text Color" : ColorCompatibility.label
        ]
        
    ] as [[String : Any]]

    func toEmailChange(){
        performSegue(withIdentifier: "toEmailChange", sender: nil)
    }
    
    func toPasswordChange(){
        performSegue(withIdentifier: "toPasswordChange", sender: nil)
    }
    
    func toCommunityGuidelines(){
        guard let url = URL(string: "https://thredapps.com/community-guidelines") else { return }
        UIApplication.shared.open(url)
    }
    
    func toPrivacyPolicy(){
        guard let url = URL(string: "https://thredapps.com/privacy-policy/") else { return }
        UIApplication.shared.open(url)
    }
    
    func addCard(){
        showErrorMessage{
        }
    }
    
    func configureMerchantAcct(){
        showErrorMessage{
        }
    }
    
    func logOut(){
        logout(withMessage: nil)
    }
    
    func updateMissing(){
        showAuthMessage {
            
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
        cell.backgroundColor = nil
        cell.textLabel?.textColor = nil
        cell.textLabel?.text = nil
        
        cell.textLabel?.text = itemsArray[indexPath.row]["Title"] as? String
        cell.textLabel?.font = UIFont(name: "NexaW01-Heavy", size: 16)
        cell.selectionStyle = .none
        
        cell.textLabel?.textColor = itemsArray[indexPath.row]["Text Color"] as? UIColor
        cell.backgroundColor = itemsArray[indexPath.row]["Background Color"] as? UIColor

        return cell
    }
    
    @IBAction func unwindToSettings(segue:  UIStoryboardSegue) {
        
        //if let button = getProfileBtn(){
         //   button.setImage(userInfo.dp, for: .normal)
        //}
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        (itemsArray[indexPath.row]["Function"] as! (() -> Void))()
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension UIViewController{
    func showErrorMessage(completed: @escaping () -> ()){
        let alertController = UIAlertController(
            title:
            "Update: COVID-19",
            message:
            "Due to COVID-19 our purchasing and printing services will temporarily be unavailable.",
            preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Ok", style: .default) { _ in
            completed()
        })
        DispatchQueue.main.async {
            self.present(alertController, animated: true)
        }
    }
    
    func showAuthMessage(completed: @escaping () -> ()){
        let alertController = UIAlertController(
            title:
            "Update: Authentication",
            message:
            "Thred has updated it's authentication system so that it ONLY requires a username/email & password. Please update your account information or you will not be able to sign in later",
            preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Later", style: .default) { _ in
            completed()
        })
        alertController.addAction(UIAlertAction(title: "Update", style: .default) { _ in
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            if let vc: SignUpVC = mainStoryboard.instantiateViewController(withIdentifier: "SignUpVC") as? SignUpVC{
                self.navigationController?.pushViewController(vc, animated: true)
            }
            completed()
        })
        
        DispatchQueue.main.async {
            self.present(alertController, animated: true)
        }
    }
    
    
    fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
        return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
    }
}
