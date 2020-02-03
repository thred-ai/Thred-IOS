//
//  EditUsernameVC.swift
//  Thred
//
//  Created by Arta Koroushnia on 2019-11-29.
//  Copyright © 2019 ArtaCorp. All rights reserved.
//

import UIKit
import FirebaseFirestore

class EditUsernameVC: UIViewController, UITextFieldDelegate, UINavigationControllerDelegate {

    var username: String?
    var doneBtnPressed = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        usernameField.delegate = self
        navigationController?.delegate = self
        usernameField.text = username
        usernameField.becomeFirstResponder()
        
    }
    
    
    @IBAction func done(_ sender: UIBarButtonItem) {
        
        sender.isEnabled = false
        guard let fieldText = usernameField.text else{return}
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
                Firestore.firestore().collection("Users").document(userInfo.uid).updateData(data, completion: {[weak self] error in
                        if error != nil{
                            print(error?.localizedDescription ?? "")
                            sender.isEnabled = true
                        }
                        else{
                            self?.doneBtnPressed = true
                            self?.navigationController?.popViewController(animated: true)
                        }
                    })
                }
                else{
                    //Not available
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
