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
            DispatchQueue.main.async {
                timestampLbl?.text = "\(user.timestampDiff!) ago"
            }
        }
    }
    
    func checkNotifTimes(notif: UserNotification, timestampLbl: UILabel?){
        
        DispatchQueue(label: "Times").async {
            if notif.timestamp == nil{
                return
            }
            notif.timestampDiff = self.setNotifTimeDifference(notif: notif, timeToUse: notif.timestamp)
            DispatchQueue.main.async {
                timestampLbl?.text = "\(notif.timestampDiff!) ago"
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
            return calculateTimeDifference(time: time) ?? "0 seconds"
        }
    }
    
    func setNotifTimeDifference(notif: UserNotification, timeToUse: Date?) -> String{
        
        switch notif.timestampDiff{
        case .some:
            
            notif.timestampDiff = nil
            fallthrough
              //return user.timestampDiff
        default:
            guard let time = timeToUse else{return "0 seconds"}
            return calculateTimeDifference(time: time) ?? "0 seconds"
        }
    }
    
    func calculateTimeDifference(time: Date) -> String?{
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
        let displayUnit = dateUnits[index]
        
        if displayUnitCount > 1{
            pluralLetter = "s"
        }
        let timeDiff = "\(displayUnitCount) \(displayUnit)\(pluralLetter)"
        timeDiffList = nil
        return timeDiff
    }
}
