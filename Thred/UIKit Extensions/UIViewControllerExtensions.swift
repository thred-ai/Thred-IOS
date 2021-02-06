//
//  UIViewControllerExtensions.swift
//  Thred
//
//  Created by Arta Kouroshnia on 2019-10-23.
//  Copyright © 2019 Thred Apps Inc. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth
import FirebaseFirestore


extension UIViewController{
    
    func loadDate(ambiguous: Bool) -> String{
        
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        
        if ambiguous{
            formatter.dateFormat = "yyyy-MM-dd, a hh:mm"
        }
        else{
            formatter.dateFormat = "yyyy-MM-dd, a hh:mm:ss"
        }
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        let date = today.adding(hours: -5) //How far back products are loaded in hours
        let uploadDate = formatter.string(from: date)
        return uploadDate.replacingOccurrences(of: " 12:", with: " 00:", options: .literal, range: nil)
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
}

extension Date{
    func currentDate(asString: Bool, dateToUse: Any, toFirestoreFormat: Bool) -> (String?, Date?){
        
        //print(TimeZone.current.abbreviation())
      
    
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        formatter.dateFormat = "yyyy-MM-dd, a hh:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        var date: String!
                
        if dateToUse is Date{
            date = formatter.string(from: dateToUse as! Date)
        }
        else if dateToUse is String{
            date = dateToUse as? String
        }
                
        switch toFirestoreFormat{
            
        case true:
            date = date.replacingOccurrences(of: " 12:", with: " 00:", options: .literal, range: nil)

        case false:
            date = date.replacingOccurrences(of: " 00:", with: " 12:", options: .literal, range: nil)
        }
                
        switch asString{
        case true:
            return (date, nil)
        case false:
            
            guard let returnDate = formatter.date(from: date) else{ return(nil,nil) }
            
            return (nil, returnDate)
        }
    }
}
