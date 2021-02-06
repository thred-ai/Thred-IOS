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

extension Array where Iterator.Element == ProductInProgress{
    func saveAll(type: String) {
        
        if self.isEmpty{
            deleteAll(type: type)
        }
        else{
            let encoder = JSONEncoder()
            if let encoded = try? encoder.encode(self){
                saveClass(encoded, name: "Products", type: type)
            }
        }
    }
    
    func deleteAll(type: String){
        removeClass("Products", type: type)
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
    
    
    func removeOldFeedPosts(newPosts: [Product]?){
        
        if self.count == 0{
            return
        }
        else{
            for product in self{
                if (!(newPosts?.contains(where: {$0.picID == product.picID}) ?? true)) || newPosts?.contains(where: {$0.picID == product.picID && $0.blurred != product.blurred}) ?? false{
                    
                    cache.removeImage(forKey: product.productID, withCompletion: {
                        if product.userInfo.uid != pUserInfo.uid{
                            cache.removeImage(forKey: product.userInfo.dpID, withCompletion: {
                                
                            })
                        }
                    })
                }
            }
        }
    }
}
