//
//  EditBioVC.swift
//  Thred
//
//  Created by Arta Koroushnia on 2019-11-29.
//  Copyright © 2019 ArtaCorp. All rights reserved.
//

import UIKit

class EditBioVC: UIViewController, UINavigationControllerDelegate {
    
    var bio: String?
    var doneBtnPressed = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationController?.delegate = self
        bioField.text = bio
        bioField.becomeFirstResponder()
    }
    @IBAction func done(_ sender: UIBarButtonItem) {
        doneBtnPressed = true
        self.navigationController?.popViewController(animated: true)
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if doneBtnPressed{
            if let editVC = viewController as? EditProfileVC{
                guard let fieldText = bioField.text else{return}
                editVC.editUserInfo.bio = fieldText
            }
        }
    }
    
    @IBOutlet weak var bioField: UITextView!
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
