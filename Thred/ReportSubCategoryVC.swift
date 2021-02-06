//
//  ReportSubCategoryVC.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-04-03.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit

class ReportSubCategoryVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var reportTitle: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var thredImageView: UIImageView!
    @IBOutlet weak var thredImageViewBack: UIView!
    
    var reportType: ReportType!
    var reportCategory: ReportCategory!
    var reportLevel: ReportLevel!
    var reportUID: String!
    var reportPostID: String!
    
    var impersonationTypes: [ReportType] = [.me, .someone]
    var inappropriateTypes: [ReportType] = [.bullying, .suicide, .nudity, .hate, .violence, .drugs]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        guard let category = reportCategory else{return}
        reportTitle.text = "\(category)".capitalizingFirstLetter()
        tableView.reloadData()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidLayoutSubviews() {
        thredImageViewBack.layer.cornerRadius = thredImageViewBack.frame.height / 2
        thredImageViewBack.clipsToBounds = true
        thredImageViewBack.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
        thredImageViewBack.layer.borderWidth = thredImageViewBack.frame.height / 17.75
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        thredImageViewBack.layer.borderColor = UIColor(named: "ProfileMask")?.cgColor
    }
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if reportCategory == .impersonation{
            return 2
        }
        return 6
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if reportCategory == .impersonation{
            let type = impersonationTypes[indexPath.row]
            return tableView.dequeueReusableCell(withIdentifier: "\(type)", for: indexPath)
        }
        let type = inappropriateTypes[indexPath.row]
        return tableView.dequeueReusableCell(withIdentifier: "\(type)", for: indexPath)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let uid = pUserInfo.uid else{return}
        if reportCategory == .impersonation{
            if indexPath.row == 0{
                uploadReport(uid: uid, reportUID: reportUID, reportType: .me, reportLevel: .profile, postID: nil){
                    self.performSegue(withIdentifier: "ReportSuccessful", sender: nil)
                }
            }
            else{
                self.performSegue(withIdentifier: "ReportSuccessful", sender: nil)
            }
        }
        else{
            let type = inappropriateTypes[indexPath.row]
            if reportLevel == .profile{
                uploadReport(uid: uid, reportUID: reportUID, reportType: type, reportLevel: .profile, postID: nil){
                    self.performSegue(withIdentifier: "ReportSuccessful", sender: nil)
                }
            }
            else{
                uploadReport(uid: uid, reportUID: reportUID, reportType: type, reportLevel: .post, postID: reportPostID){
                    self.performSegue(withIdentifier: "ReportSuccessful", sender: nil)
                }
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

extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }

    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
}
