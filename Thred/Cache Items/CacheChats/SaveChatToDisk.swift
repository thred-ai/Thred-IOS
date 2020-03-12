//
//  SaveProductToDisk.swift
//  Thred
//
//  Created by Arta Kouroshnia on 2019-11-01.
//  Copyright © 2019 Thred Apps Inc. All rights reserved.
//

import Foundation
import Firebase
import FirebaseFirestore
import SDWebImage

extension Array{
    func saveClass(_ fileJSON: Data, name: String, type: String){
        
        if let folderName = type.determineFolder(){
            do {
                try fileJSON.write(to: folderName.appendingPathComponent(name))
            } catch {
                
                print(error.localizedDescription)}
        }
    }
    
    func removeClass(_ name: String, type: String){
        
        if let folderName = type.determineFolder(){
            try? FileManager.default.removeItem(at: folderName.appendingPathComponent(name))
        }
    }
}

extension Array where Iterator.Element == Template{
    func saveTemplates(type: String, name: String) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(self){
            saveClass(encoded, name: "TemplateData", type: type)
        }
    }
}

extension Array where Iterator.Element == Product{
    
    func saveAllObjects(type: String) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(self){
            saveClass(encoded, name: "Products", type: type)
        }
    }
    
    func removeAllObjects(type: String){
        removeClass("Products", type: type)
    }
    
    
    func removeOldFeedPosts(newPosts: [Product]?, completed: @escaping () -> ()){
        
        if self.count == 0{
            completed()
            return
        }
        else{
            for (index, product) in self.enumerated(){
                if (!(newPosts?.contains(where: {$0.picID == product.picID}) ?? false)) || newPosts?.contains(where: {$0.picID == product.picID && $0.blurred != product.blurred}) ?? false{
                    cache.removeImage(forKey: product.productID, withCompletion: {
                        if product.uid != userInfo.uid{
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
                else{
                    if index == self.count - 1{
                        completed()
                    }
                }
            }
        }
    }
}
