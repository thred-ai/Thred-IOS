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
        tees.checkAndLoadTemplates(type: "TeeTemplates"){
            DispatchQueue.main.async {
                if self.tees.isEmpty{
                    Firestore.firestore().document("Templates/Tees").getDocument(completion: { snap, error in
                        if error != nil{
                            print(error?.localizedDescription ?? "")
                        }
                        else{
                            //for doc in snaps?.documents ?? []{}
                            guard let doc = snap else{return}
                            let ids = doc["IDs"] as? [String]
                            for id in ids ?? []{
                                Storage.storage().reference(withPath: "Templates/\(doc.documentID)/\(id).png").downloadURL(completion: { url, error in
                                    if error != nil{
                                        print(error?.localizedDescription ?? "")
                                    }
                                    else{
                                        var dub: CGFloat = 0
                                        var oldDub: CGFloat = 0
                                        SDWebImageDownloader.shared.requestImage(with: url, options: [.highPriority, .continueInBackground, .scaleDownLargeImages], context: nil, progress: { (receivedSize: Int, expectedSize: Int, link) -> Void in
                                            dub = CGFloat(receivedSize) / CGFloat(expectedSize)
                                            print("Progress \(dub)")
                                            print("Old Progress \(oldDub)")
                                            DispatchQueue.main.sync {
                                                //cp?.setProgressWithAnimation(duration: 0.0, value: dub, from: oldDub, finished: true){
                                                    oldDub = dub
                                               // }
                                            }
                                        }, completed: {[weak self] (image, data, error, finished) in
                                            if error != nil{
                                                print(error?.localizedDescription ?? "")
                                            }
                                            else{
                                                if let imgData = data{
                                                    let tee = Template(templateID: id, templateData: imgData)
                                                    self?.tees.append(tee)
                                                    
                                                    if self?.tees.count == ids?.count{
                                                        self?.tees.sort(by: {$0.templateID < $1.templateID})
                                                    
                                                        self?.tees.saveTemplates(type: "TeeTemplates", name: "TemplateData")
                                                        completed()
                                                    }
                                                }
                                            }
                                        })
                                    }
                                })
                            }
                        }
                    })
                }
                else{
                    completed()
                }
            }
        }
    }
}
