//
//  SavePIcturesToDisk.swift
//  Thred
//
//  Created by Arta Kouroshnia on 2019-11-01.
//  Copyright © 2019 Thred Apps Inc. All rights reserved.
//

import Foundation
import UIKit

extension Data{
    
    func checkDirectory(_ name: String, type: String, completed: @escaping () -> ()){
        
        if let dataPath = type.determineFolder(){
            if self.saveImage(name, dataPath: dataPath){
                completed()
            }
        }
    }
    
    func saveImage(_ name: String, dataPath: URL) -> Bool{
        
        do {
            let imageURL = dataPath.appendingPathComponent(name)
            try self.write(to: imageURL)
            return true
        } catch {
            print(error)
            
            return false
        }
    }
}


extension String{
    
    
    func determineFolder() -> URL?{
        
        var folder = String()
        if self == "UserDP"{
            folder = self
        }
        else if self == "Products"{
            folder = self
        }
        else if self == "ProductsPictures"{
            folder = "Products/Pictures"
        }
        else if self == "FeedProducts"{
            folder = "CachedFeedProducts"
        }
        else if self == "OtherProductsPictures"{
            folder = "CachedFeedProducts/Pictures"
        }
        else if self == "TeeTemplates"{
            folder = "CachedTemplates/Tees"
        }
        else if self == "HoodieTemplates"{
            folder = "CachedTemplates/Hoodies"
        }
        else{
            return nil
        }
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        guard let documentsDirectory = paths.first
            else {
                
                return nil}
        let docURL = URL(fileURLWithPath: documentsDirectory)
        let dataPath = docURL.appendingPathComponent(folder)
        if !FileManager.default.fileExists(atPath: dataPath.relativePath) {
            do{
                try FileManager.default.createDirectory(atPath: dataPath.relativePath, withIntermediateDirectories: true, attributes: nil)
                return dataPath
            } catch {
                
                print(error.localizedDescription);
                
                return nil
            }
        }
        else{
            return dataPath
        }
    }
}
