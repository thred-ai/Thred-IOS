//
//  LoadTemplates.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-02-12.
//  Copyright © 2020 Thred. All rights reserved.
//

import Foundation
import Firebase
import FirebaseFirestore
import SDWebImage

extension DesignViewController{
    func loadDesigns(completed: @escaping ()->()){
        if let loadedTees = UserDefaults.standard.object(forKey: "TemplateTeeIDs") as? [[String : String]]{
            for id in loadedTees{
                guard let code = id["Code"] else{continue}
                guard let displayName = id["Display"] else{continue}
                self.tees.append(Template(templateID: code, templateDisplayName: displayName))
            }
            completed()
        }
        else{
            Firestore.firestore().document("Templates/Tees").getDocument(completion: { snap, error in
                if error != nil{
                    print(error?.localizedDescription ?? "")
                }
                else{
                    //for doc in snaps?.documents ?? []{}
                    guard let doc = snap else{return}
                    let ids = doc["IDs"] as? [[String : String]]
                    for id in ids ?? []{
                        guard let code = id["Code"] else{continue}
                        guard let displayName = id["Display"] else{continue}
                        
                        self.tees.append(Template(templateID: code, templateDisplayName: displayName))
                    }
                    UserDefaults.standard.set(ids, forKey: "TemplateTeeIDs")
                    completed()
                }
            })
        }
    }
}
