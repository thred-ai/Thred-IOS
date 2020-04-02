//
//  ReportVC.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-03-30.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit

enum ReportLevel{
    case profile
    case post
    case comment
}


class ReportVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var reportTitle: UILabel!
    @IBOutlet weak var thredImageView: UIImageView!
    @IBOutlet weak var thredImageViewBack: UIView!
    
    
    
    var reportLevel: ReportLevel!
    
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
