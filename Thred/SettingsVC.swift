//
//  SettingsVC.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-04-03.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import ColorCompatibility

class SettingsVC: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        tableView.separatorStyle = .none
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 6
    }
    
    var itemsArray = [
        "Change phone number",
        "Change backup email",
        "Community guidelines",
        "Setup my merchant account",
        "Add a card",
        "Sign out"
    ]

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)

        cell.textLabel?.text = itemsArray[indexPath.row]
        cell.textLabel?.font = UIFont(name: "NexaW01-Heavy", size: 16)
        cell.selectionStyle = .none
        
        if indexPath.row == 3 || indexPath.row == 4{
            cell.textLabel?.textColor = ColorCompatibility.secondaryLabel
        }
        else{
            cell.textLabel?.textColor = ColorCompatibility.label
        }
        return cell
    }
    
    @IBAction func unwindToSettings(segue:  UIStoryboardSegue) {
        
        //if let button = getProfileBtn(){
         //   button.setImage(userInfo.dp, for: .normal)
        //}
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row{
        case 0:
            self.performSegue(withIdentifier: "toPhoneNumAuth", sender: nil)
        case 1:
            self.performSegue(withIdentifier: "toEmail", sender: nil)
        case 2:
            guard let url = URL(string: "https://thredapps.com/community-guidelines") else { return }
            UIApplication.shared.open(url)
        case 3:
            showErrorMessage{
            }
        case 4:
            showErrorMessage{
            }
        case 5:
            logout(withMessage: nil)
        default:
            return
        }
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
    fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
        return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
    }
}
