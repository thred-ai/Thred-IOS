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
        
        switch UserDefaults.standard.object(forKey: "TemplateTeeIDs"){
        case let loadedTees as [[String : String]]:
            for id in loadedTees{
                guard let code = id["Code"] else{continue}
                guard let displayName = id["Display"] else{continue}
                let hasFemale = (id["hasFemale"] ?? "false").toBool()
                self.tees.append(Template(templateID: code, templateDisplayName: displayName, hasFemale: hasFemale))
            }
            completed()
            fallthrough
        default:
            checkAuthStatus {
                Firestore.firestore().document("Templates/Tees").getDocument(completion: { snap, error in
                    if error != nil{
                        print(error?.localizedDescription ?? "")
                    }
                    else{
                        //for doc in snaps?.documents ?? []{}
                        guard let doc = snap else{return}
                        let ids = doc["IDs"] as? [[String : String]]
                        self.tees.removeAll()
                        
                        for id in ids ?? []{
                            guard let code = id["Code"] else{continue}
                            guard let displayName = id["Display"] else{continue}
                            guard let hasFemale = (id["hasFemale"] ?? "false").toBool() else{continue}
                            self.tees?.append(Template(templateID: code, templateDisplayName: displayName, hasFemale: hasFemale))
                        }
                        UserDefaults.standard.set(ids, forKey: "TemplateTeeIDs")
                        completed()
                    }
                })
            }
        }
    }
}

extension String {
    func toBool() -> Bool?{
        if self == "false" {
            return false
        }else if self == "true"{
            return true
        }
        return nil
    }
}
