//
//  GetProductFromDisk.swift
//  Thred
//
//  Created by Arta Kouroshnia on 2019-11-01.
//  Copyright © 2019 Thred Apps Inc. All rights reserved.
//

import Foundation
import UIKit
import SwiftyDraw


extension Array where Iterator.Element == ProductInProgress{
    func getAll(type: String, name: String) -> [ProductInProgress]? {
        if let objects = self.loadClass(withName: name, type: type) {
            let decoder = JSONDecoder()
            if let objectsDecoded = try? decoder.decode(Array.self, from: objects) as [ProductInProgress] {
                return objectsDecoded
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    mutating func checkAndLoadProducts(type: String){
            
        let diskLoadedProducts = self.getAll(type: type, name: "Products")
        switch diskLoadedProducts{
            
        case .some:
            for product in diskLoadedProducts!{
                
                let post = ProductInProgress(templateColor: product.templateColor, designs: product.designs, uid: product.uid, caption: product.caption, name: product.name, price: product.price, productID: product.productID, display: product.display, isPublic: product.isPublic, productType: product.productType, displaySide: product.displaySide)
                
                self.append(post)
            }
        case .none:
            return
        }
    }
}

extension Array where Iterator.Element == Product{
    
    mutating func checkAndLoadProducts(vc: UIViewController, type: String, with completed: @escaping (Int) -> ()){
            
        let diskLoadedProducts = self.getAllObjects(type: type, name: "Products")
        switch diskLoadedProducts{
            
        case .some:
            
            guard let count = diskLoadedProducts?.count
                else{return}
            
            for product in diskLoadedProducts!{
                
                let post = Product(userInfo: product.userInfo, picID: product.picID, description: product.description, productID: product.productID, timestamp: product.timestamp, index: product.index, timestampDiff: product.timestampDiff, blurred: product.blurred, price: product.price, name: product.name, templateColor: product.templateColor, likes: product.likes, liked: product.liked, designImage: product.designImage, comments: product.comments, link: product.link, isAvailable: product.isAvailable, isPublic: product.isPublic, productType: product.productType ?? "ATC1000", displaySide: product.displaySide ?? "front", supportedSides: product.supportedSides)

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
    
    func saveAllObjects(type: String) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(self){
            saveClass(encoded, name: "Templates", type: type)
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

extension Array where Iterator.Element == CanvasDesign{
    
    func saveAllObjects(type: String) {
        if let savedData = try? NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false) {
                let defaults = UserDefaults.standard
                defaults.set(savedData, forKey: "CanvasDesigns")
        }
        else{
            
        }
    }
    
    func getAllObjects(type: String, name: String) -> [CanvasDesign]? {
        let defaults = UserDefaults.standard

        if let savedPeople = defaults.object(forKey: "CanvasDesigns") as? Data {
            if let decodedDesigns = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(savedPeople) as? [CanvasDesign] {
                return decodedDesigns
            }
        }
        else{
            
        }
        return []
    }
}

extension Array where Iterator.Element == SwiftyDraw.SwiftyDrawView.DrawItem{
    
    func saveAllObjects(type: String) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(self){
            saveClass(encoded, name: "Designs", type: type)
        }
    }
    
    func getAllObjects(type: String, name: String) -> [SwiftyDraw.SwiftyDrawView.DrawItem]? {
        if let objects = self.loadClass(withName: name, type: type) {
            let decoder = JSONDecoder()
            if let objectsDecoded = try? decoder.decode(Array.self, from: objects) as [SwiftyDraw.SwiftyDrawView.DrawItem] {
                return objectsDecoded
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
}
