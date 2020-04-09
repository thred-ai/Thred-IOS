//
//  EditUsernameVC.swift
//  Thred
//
//  Created by Arta Koroushnia on 2019-11-29.
//  Copyright © 2019 Thred Apps Inc. All rights reserved.
//

import UIKit
import FirebaseFirestore

class EditUsernameVC: UIViewController, UITextFieldDelegate, UINavigationControllerDelegate {

    var username: String?
    var doneBtnPressed = false
    @IBOutlet weak var errorView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        usernameField.delegate = self
        navigationController?.delegate = self
        usernameField.text = username
        usernameField.becomeFirstResponder()
        
        usernameField.addTarget(self, action: #selector(textFieldDidChange(_:)),
        for: .editingChanged)
    }
    
    var oldText: String!
    
    func updateErrorView(text: String){
        errorView.textColor = .systemRed
        errorView.text = text
    }
    
    @objc func textFieldDidChange(_ textField: UITextField){
        
        guard var text = textField.text else {return}
        
        text = text.replacingOccurrences(of: " ", with: "_").lowercased()
        textField.text = text
        
        if text.count < 2{
            doneBtn.isEnabled = false
        }
        else{
            if text.hasSpecialCharacters(){
                textField.text = oldText
            }
            else{
                oldText = text
            }
            if !(textField.text?.first == "." || textField.text?.last == "."){
                doneBtn.isEnabled = true
            }
            else{
                doneBtn.isEnabled = false
            }
        }
    }
    
    

    
    @IBAction func done(_ sender: UIBarButtonItem) {
        
        sender.isEnabled = false
        guard let fieldText = usernameField.text else{return}
        guard let uid = userInfo.uid else{return}
        errorView.text = nil
        Firestore.firestore().collection("Users").whereField("Username", isEqualTo: fieldText).getDocuments(completion: { snaps, error in
            
            if error != nil{
                print(error?.localizedDescription ?? "")
                //Do something
            }
            else{
                if snaps?.isEmpty ?? false{
                    guard let fieldText = self.usernameField.text else{return}

                    let data = [
                        "Username": fieldText,
                    ]
                    self.checkAuthStatus {
                        Firestore.firestore().collection("Users").document(uid).updateData(data, completion: { error in
                            if let err = error{
                                self.updateErrorView(text: err.localizedDescription)
                                sender.isEnabled = true
                            }
                            else{
                                self.doneBtnPressed = true
                                sender.isEnabled = true
                                self.navigationController?.popViewController(animated: true)
                            }
                        })
                    }
                }
                else{
                    sender.isEnabled = true
                    self.updateErrorView(text: "This username is not available")
                }
            }
        })
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if doneBtnPressed{
            if let editVC = viewController as? EditProfileVC{
                guard let fieldText = usernameField.text else{return}
                editVC.editUserInfo.username = fieldText
            }
        }
    }
    
    @IBOutlet weak var doneBtn: UIBarButtonItem!
    
    
    @IBOutlet weak var usernameField: UITextField!
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension String{
    func hasSpecialCharacters() -> Bool {
        if self.range(of: "^[0-9a-zA-Z-_\\.]{0,40}$", options: [.regularExpression, .caseInsensitive]) != nil {
            return false
        }
        return true
    }
}
