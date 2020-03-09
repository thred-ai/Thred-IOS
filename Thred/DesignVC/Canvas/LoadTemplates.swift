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
        if let loadedTees = UserDefaults.standard.stringArray(forKey: "TemplateTeeIDs"){
            for id in loadedTees{
                self.tees.append(Template(templateID: id))
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
                    let ids = doc["IDs"] as? [String]
                    for id in ids ?? []{
                        self.tees.append(Template(templateID: id))
                    }
                    UserDefaults.standard.set(ids, forKey: "TemplateTeeIDs")
                    completed()
                }
            })
        }
    }
}
