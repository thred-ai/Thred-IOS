//
//  UIViewControllerExtensions.swift
//  Thred
//
//  Created by Artak on 2019-10-23.
//  Copyright © 2019 ArtaCorp. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth
import FirebaseFirestore
import OneSignal


extension UIViewController{
    
    func loadDate(ambiguous: Bool) -> String{
        
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        
        if ambiguous{
            formatter.dateFormat = "YYYY-MM-dd, a hh:mm"
        }
        else{
            formatter.dateFormat = "YYYY-MM-dd, a hh:mm:ss"
        }
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        let date = today.adding(hours: -5) //How far back products are loaded in hours
        let uploadDate = formatter.string(from: date)
        return uploadDate.replacingOccurrences(of: " 12:", with: " 00:", options: .literal, range: nil)
    }
    
    func currentDate(asString: Bool, dateToUse: Any, toFirestoreFormat: Bool) -> (String?, Date?){
        
        //print(TimeZone.current.abbreviation())
      
    
        let formatter = DateFormatter()
        
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        var date: String!
        
        if dateToUse is Date{
            date = formatter.string(from: dateToUse as! Date)
        }
        else if dateToUse is String{
            date = dateToUse as? String
        }
        
        switch asString{
        case true:
            return (date, nil)
        case false:
            
            guard let returnDate = formatter.date(from: date) else{ return(nil,nil) }
            
            return (nil, returnDate)
        }
    }
    
    func time(time: String) -> String{
        
        let substring = time.substring(from: 0, to: time.count - 4)
        print(substring)
        return substring
    }
    
       
    func removeFile(withName name: String){
           
        let imageURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(name)

        do{
            try FileManager.default.removeItem(at: imageURL)
        }catch{print(error.localizedDescription)}
    }
       
    func clearDocumentsDirectory() {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
           
        let items = try? fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
        items?.forEach { item in
            try? fileManager.removeItem(at: item)
        }
    }
       
       
    func loggingOut(auto: Bool){

           /*
           if(!auto){
               let uid = UserDefaults.standard.string(forKey: "USER")
           Database.database().reference().child("Users").child(uid!).child("Credentials").child("Notification ID").removeValue(completionBlock: { error, snapshot in
                   if error != nil{
                       print(error?.localizedDescription ?? "")
                       return
                   }
                   else{
                       self.removingStoredFiles()
                   }
               })
           }
           else{
               self.removingStoredFiles()
           }
 */
    
       }
       
    func removingStoredFiles(){
           
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        self.clearDocumentsDirectory()
        OneSignal.setSubscription(false)
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier ?? "")
        do{
            try Auth.auth().signOut()
        }catch{}
        //let mainStoryBoard = UIStoryboard(name: "Main", bundle: nil)
        //let loginVC = mainStoryBoard.instantiateViewController(withIdentifier: "noAccVC")
    }
}

/*
extension QuerySnapshot{
    
    func convertproductDocToArray(followingUID: String) -> [Product]{
        
        var array = [Product]()

        for (index, snap) in self.documents.enumerated(){ // LOADED DOCUMENTS FROM \(snapDocuments)
            let timestamp = snap["Timestamp"] as? String
            let isPic = snap["Picture"] as? Bool
            let activeTime = snap["Active"] as? String
            let imageHeight = snap["Image Height"] as? CGFloat
            let imageWidth = snap["Image Width"] as? CGFloat
            
            if let description = snap["description"] as? String{
                
                if isPic ?? false{
                    array.append(Product(uid: followingUID, isPic: true, picID: snap.documentID, description: description, fullName: nil, username: nil, imageData: nil, userImage: nil, productID: snap.documentID, userImageID: nil, timestamp: timestamp, isActive: false, index: index, activeTime: activeTime, activeTimeDiff: nil,  timestampDiff: nil, fromCache: false, aspectRatio: aspectRatio))
                }
                else{
                    array.append(Product(uid: followingUID, isPic: false, picID: nil, description: description, fullName: nil, username: nil, imageData: nil, userImage: nil, productID: snap.documentID, userImageID: nil, timestamp: timestamp, isActive: false, index: index, activeTime: activeTime, activeTimeDiff: nil, timestampDiff: nil, fromCache: false, aspectRatio: aspectRatio))
                }
            }
            else{
                if let picID = snap["Picture"] as? String{
                    array.append(Product(uid: followingUID, isPic: true, picID: picID, description: nil, fullName: nil, username: nil, imageData: nil, userImage: nil, productID: snap.documentID, userImageID: nil, timestamp: timestamp, isActive: false, index: index, activeTime: activeTime, activeTimeDiff: nil, timestampDiff: nil, fromCache: false, aspectRatio: aspectRatio))
                }
            }
        }
        return array
    }
 
}
*/
