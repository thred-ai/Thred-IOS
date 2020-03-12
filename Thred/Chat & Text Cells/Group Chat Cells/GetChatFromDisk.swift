//
//  GetProductFromDisk.swift
//  Thred
//
//  Created by Arta Kouroshnia on 2019-11-01.
//  Copyright © 2019 Thred Apps Inc. All rights reserved.
//

import Foundation
import UIKit

extension Array where Iterator.Element == Product{
    
    mutating func checkAndLoadProducts(vc: UIViewController, type: String, with completed: @escaping (Int) -> ()){
            
        let diskLoadedProducts = self.getAllObjects(type: type, name: "Products")
        switch diskLoadedProducts{
            
        case .some:
            
            guard let count = diskLoadedProducts?.count else{
                
                
                return}
            
            for product in diskLoadedProducts!{
                
                let post = Product(uid: product.uid, picID: product.picID, description: product.description, fullName: product.fullName, username: product.username, productID: product.productID, userImageID: product.userImageID, timestamp: product.timestamp, index: product.index, timestampDiff: product.timestampDiff, fromCache: true, blurred: product.blurred, price: product.price, name: product.name, templateColor: product.templateColor, likes: product.likes, liked: product.liked, designImage: nil)
                

                self.append(post)
            }
            completed(count)
        case .none:
            completed(0)
        }
    }
    
    func getAllObjects(type: String, name: String) -> [Product]? {
        if let objects = self.loadClass(withName: name, type: type) {
            let decoder = JSONDecoder()
            if let objectsDecoded = try? decoder.decode(Array.self, from: objects) as [Product] {
                return objectsDecoded
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
}

extension Array{
    
    func loadClass(withName name: String, type: String) -> Data? {
        
        if let url = type.determineFolder()?.appendingPathComponent(name){
            do{
                let data = try Data(contentsOf: url)
                return data
            }catch{print(error.localizedDescription)}
            return nil
        }
        else{
            return nil
        }
    }
}


extension Array where Iterator.Element == Template{
    
    mutating func checkAndLoadTemplates(type: String, with completed: @escaping () -> ()){
            
        let diskLoadedProducts = self.getAllObjects(type: type, name: "TemplateData")
        switch diskLoadedProducts{
            
        case .some:
            self = diskLoadedProducts!
            completed()
        case .none:
            completed()
        }
    }
    
    func getAllObjects(type: String, name: String) -> [Template]? {
        if let objects = self.loadClass(withName: name, type: type) {
            let decoder = JSONDecoder()
            if let objectsDecoded = try? decoder.decode(Array.self, from: objects) as [Template] {
                return objectsDecoded
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
}
