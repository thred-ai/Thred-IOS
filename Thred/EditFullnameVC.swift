//
//  EditFullnameVC.swift
//  Thred
//
//  Created by Arta Koroushnia on 2019-11-29.
//  Copyright © 2019 ArtaCorp. All rights reserved.
//

import UIKit

class EditFullnameVC: UIViewController, UINavigationControllerDelegate {

    @IBOutlet weak var fullnameField: UITextField!
    
    var fullname: String?
    var doneBtnPressed = false

    override func viewDidLoad() {
        super.viewDidLoad()

        
        navigationController?.delegate = self
        fullnameField.text = fullname
        fullnameField.becomeFirstResponder()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
    }
    
    @IBAction func done(_ sender: UIBarButtonItem) {
        doneBtnPressed = true
        self.navigationController?.popViewController(animated: true)
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if doneBtnPressed{
            if let editVC = viewController as? EditProfileVC{
                guard let fieldText = fullnameField.text else{return}
                editVC.editUserInfo.fullName = fieldText
            }
        }
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
