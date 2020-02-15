//
//  SaveProductToDisk.swift
//  Thred
//
//  Created by Artak on 2019-11-01.
//  Copyright © 2019 ArtaCorp. All rights reserved.
//

import Foundation
import Firebase
import FirebaseFirestore
import SDWebImage

extension Array{
    func saveClass(_ fileJSON: Data, name: String, type: String){
        
        if let folderName = type.determineFolder(){
            //print(folderName)
            
            do {
                try fileJSON.write(to: folderName.appendingPathComponent(name))
            } catch {
                
                print(error.localizedDescription)}
        }
    }
}

extension Array where Iterator.Element == Template{
    func saveTemplates(type: String, name: String) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(self){
            self.saveClass(encoded, name: "TemplateData", type: type)
        }
    }
}

extension Array where Iterator.Element == Product{
    
    func saveAllObjects(type: String) {
        let encoder = JSONEncoder()
        
        if let encoded = try? encoder.encode(self){
            self.saveClass(encoded, name: "Products", type: type)
        }
    }
    
    
    func removeOldFeedPosts(isSame: Bool, snaps: [QueryDocumentSnapshot], completed: @escaping () -> ()){
        
        
        if self.count == 0{
            completed()
            return
        }
        else{
            for (index, product) in self.enumerated(){
                cache.removeImage(forKey: product.productID, withCompletion: {
                    if product.userImageID != userInfo.uid{
                        cache.removeImage(forKey: product.userImageID, withCompletion: {
                            if index == self.count - 1{
                                completed()
                            }
                        })
                    }
                    else{
                        if index == self.count - 1{
                            completed()
                        }
                    }
                })
            }
        }
    }
}
