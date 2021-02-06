//
//  SetUpTimeDifferences.swift
//  Thred
//
//  Created by Arta Kouroshnia on 2019-11-01.
//  Copyright © 2019 Thred Apps Inc. All rights reserved.
//

import Foundation
import UIKit
import SDWebImage

extension UITableView{
    
    func checkTimes(user: Product, timestampLbl: UILabel?){
        
        DispatchQueue(label: "Times").async {
            if user.timestamp == nil{
                return
            }
            user.timestampDiff = self.setTimeDifference(user: user, timeToUse: user.timestamp)
            guard user.timestampDiff != nil else{return}
            DispatchQueue.main.async {
                timestampLbl?.text = "\(user.timestampDiff ?? "") ago"
            }
        }
    }
    
    func checkChatTimes(chat: GroupChat, timestampLbl: UILabel?){
        
        DispatchQueue(label: "Times").async {
            if chat.timestamp == nil{
                return
            }
            chat.timestampDiff = self.setChatTimeDifference(chat: chat, timeToUse: chat.timestamp)
            guard chat.timestampDiff != nil else{return}
            DispatchQueue.main.async {
                timestampLbl?.text = " • \(chat.timestampDiff ?? "")"
            }
        }
    }
    
    
    
    func checkNotifTimes(notif: UserNotification, timestampLbl: UILabel?){
        
        DispatchQueue(label: "Times").async {
            if notif.timestamp == nil{
                return
            }
            notif.timestampDiff = self.setNotifTimeDifference(notif: notif, timeToUse: notif.timestamp)
            guard notif.timestampDiff != nil else{return}
            DispatchQueue.main.async {
                timestampLbl?.text = "\(notif.timestampDiff ?? "some time")"
            }
        }
    }
    
    func checkSalesTimes(sale: ProductInCart, timestampLbl: UILabel?){
        
        DispatchQueue(label: "Times").async {
            if sale.timestamp == nil{
                return
            }
            sale.timestampDiff = self.setSaleTimeDifference(sale: sale, timeToUse: sale.timestamp)
            guard sale.timestampDiff != nil else{return}
            DispatchQueue.main.async {
                timestampLbl?.text = "\(sale.timestampDiff ?? "some time")"
            }
        }
    }
    
    func checkCommentTimes(comment: Comment, timestampLbl: UILabel?){
        
        DispatchQueue(label: "Times").async {
            if comment.timestamp == nil{
                return
            }
            comment.timestampDiff = self.setCommentTimeDifference(comment: comment, timeToUse: comment.timestamp)
            guard comment.timestampDiff != nil else{return}
            DispatchQueue.main.async {
                timestampLbl?.text = "\(comment.timestampDiff ?? "")"
            }
        }
    }

    func setTimeDifference(user: Product, timeToUse: Date?) -> String{
        
        switch user.timestampDiff{
        case .some:
            
            user.timestampDiff = nil
            fallthrough
              //return user.timestampDiff
        default:
            guard let time = timeToUse else{return "0 seconds"}
            return calculateTimeDifference(time: time, shortForm: false) ?? "0 seconds"
        }
    }
    
    func setChatTimeDifference(chat: GroupChat, timeToUse: Date?) -> String{
        
        switch chat.timestampDiff{
        case .some:
            
            chat.timestampDiff = nil
            fallthrough
              //return user.timestampDiff
        default:
            guard let time = timeToUse else{return "0s"}
            return calculateTimeDifference(time: time, shortForm: true) ?? "0s"
        }
    }
    
    func setNotifTimeDifference(notif: UserNotification, timeToUse: Date?) -> String{
        
        switch notif.timestampDiff{
        case .some:
            
            notif.timestampDiff = nil
            fallthrough
              //return user.timestampDiff
        default:
            guard let time = timeToUse else{return "0s"}
            return calculateTimeDifference(time: time, shortForm: true) ?? "0s"
        }
    }
    
    func setSaleTimeDifference(sale: ProductInCart, timeToUse: Date?) -> String{
    
        switch sale.timestampDiff{
        case .some:
            
            sale.timestampDiff = nil
            fallthrough
              //return user.timestampDiff
        default:
            guard let time = timeToUse else{return "0s"}
            return calculateTimeDifference(time: time, shortForm: true) ?? "0s"
        }
    }
    
    func setCommentTimeDifference(comment: Comment, timeToUse: Date?) -> String{
        
        switch comment.timestampDiff{
        case .some:
            
            comment.timestampDiff = nil
            fallthrough
              //return user.timestampDiff
        default:
            guard let time = timeToUse else{return "0s"}
            return calculateTimeDifference(time: time, shortForm: true) ?? "0s"
        }
    }
    
    func calculateTimeDifference(time: Date, shortForm: Bool) -> String?{
        let currentDate = Date()
        let requestedComponent: Set<Calendar.Component> = [.year, .month, .weekOfYear, .day, .hour, .minute, .second]
        let timeDifference = userCalendar.dateComponents(requestedComponent, from: time, to: currentDate)
        
        var timeDiffList: [[String : Int]]? = [[String : Int]]()
        timeDiffList?.append(["Num" : timeDifference.year ?? 0, "index" : 0])
        timeDiffList?.append(["Num" : timeDifference.month ?? 0, "index" : 1])
        timeDiffList?.append(["Num" : timeDifference.weekOfYear ?? 0, "index" : 2])
        timeDiffList?.append(["Num" : timeDifference.day ?? 0, "index" : 3])
        timeDiffList?.append(["Num" : timeDifference.hour ?? 0, "index" : 4])
        timeDiffList?.append(["Num" : timeDifference.minute ?? 0, "index" : 5])
        timeDiffList?.append(["Num" : timeDifference.second ?? 0, "index" : 6])
        guard let topDict = timeDiffList?.filter({$0["Num"] != 0}).first
        else{
            return nil
        }
        guard let index = topDict["index"]
        else{
            return nil
        }
        guard let displayUnitCount = topDict["Num"]
        else{
            return nil
        }
        var pluralLetter = ""
        var displayUnit = ""
        var timeDiff = ""
        
        if shortForm{
            displayUnit = shortDateUnits[index]
            timeDiff = "\(displayUnitCount)\(displayUnit)"
        }
        else{
            displayUnit = dateUnits[index]
            if displayUnitCount > 1{
                pluralLetter = "s"
            }
            timeDiff = "\(displayUnitCount) \(displayUnit)\(pluralLetter)"
        }
        
        timeDiffList = nil
        return timeDiff
    }
}
