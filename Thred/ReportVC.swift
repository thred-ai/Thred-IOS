//
//  ReportVC.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-03-30.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore

enum ReportLevel{
    case profile
    case post
    case comment
}

enum ReportType{
    case ipv
    case bullying
    case me
    case someone
    case nudity
    case hate
    case violence
    case suicide
    case drugs
    case age
}

enum ReportCategory{
    case inappropriate
    case impersonation
}


class ReportVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var reportTitle: UILabel!
    @IBOutlet weak var thredImageView: UIImageView!
    @IBOutlet weak var thredImageViewBack: UIView!
    var reportCategory: ReportCategory!
    var reportType: ReportType!
    
    var reportLevel: ReportLevel!
    var reportUID: String!
    var reportPostID: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        
        var reportTitleIdentifier = ""
        
        switch reportLevel{
        case .profile:
            reportTitleIdentifier = reportProfileTitle
        case .comment:
            reportTitleIdentifier = reportCommentTitle
        case .post:
            reportTitleIdentifier = reportPostTitle
        default:
            return
        }
        
        reportTitle.text = "Why are you reporting this \(reportTitleIdentifier)?"
        
        tableView.reloadData()
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
    
    var reportProfileTitle: String{
        return "profile"
    }
    
    var reportPostTitle: String{
        return "post"
    }
    
    var reportCommentTitle: String{
        return "comment"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch reportLevel{
        case .profile:
            return 3
        case .post:
            return 2
        case .comment:
            return 1
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == 0{
            let cell = tableView.dequeueReusableCell(withIdentifier: "Inappropriate", for: indexPath)
            return cell
        }
        switch reportLevel{
        case .profile:
            if indexPath.row == 1{
                let cell = tableView.dequeueReusableCell(withIdentifier: "Impersonation", for: indexPath)
                return cell
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: "Age", for: indexPath)
            return cell
        case .post:
            if indexPath.row == 1{
                let cell = tableView.dequeueReusableCell(withIdentifier: "IPV", for: indexPath)
                return cell
            }
            fallthrough
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let uid = pUserInfo.uid else{return}
        if indexPath.row == 0{
            reportCategory = .inappropriate
            self.performSegue(withIdentifier: "ToSecondReport", sender: nil)
        }
        else{
            switch reportLevel{
            case .profile:
                if indexPath.row == 1{
                    reportCategory = .impersonation
                    self.performSegue(withIdentifier: "ToSecondReport", sender: nil)
                }
                else{
                    uploadReport(uid: uid, reportUID: reportUID, reportType: .age, reportLevel: .profile, postID: nil){
                        self.performSegue(withIdentifier: "ReportSuccessful", sender: nil)
                    }
                }
            case .post:
                if indexPath.row == 1{
                    reportType = .ipv
                    uploadReport(uid: uid, reportUID: reportUID, reportType: .ipv, reportLevel: .post, postID: reportPostID){
                        self.performSegue(withIdentifier: "ReportSuccessful", sender: nil)
                    }
                }
                else{
                    fallthrough
                }
            default:
                return
            }
        }
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        if let sub = segue.destination as? ReportSubCategoryVC{
            sub.reportCategory = reportCategory
            sub.reportPostID = reportPostID
            sub.reportUID = reportUID
        }
    }
}

extension UIViewController{
    
    func uploadReport(uid: String, reportUID: String, reportType: ReportType, reportLevel: ReportLevel, postID: String?, completed: @escaping () -> ()){
        var reportData = [
            "Type" : "\(reportType)",
            "Reporter_UID" : uid,
            "Reportee_UID" : reportUID,
            "Evaluated" : false,
            "Timestamp" : Date()
            ] as [String : Any]
        if reportLevel == .post{
            reportData["Post_ID"] = postID
        }
        
        Firestore.firestore().collection("Reports").addDocument(data: reportData, completion: { error in
            if let err = error{
                print(err.localizedDescription)
            }
            else{
                completed()
            }
        })
    }
}
