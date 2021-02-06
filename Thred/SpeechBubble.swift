//
//  SpeechBubble.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-09-12.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit

class SpeechBubble: UIView {
    let strokeColor: UIColor = UIColor.white
    let fillColor: UIColor = UIColor(named: "LoadingColor")!
    var triangleHeight: CGFloat!
    var radius: CGFloat!
    var borderWidth: CGFloat!
    var edgeCurve: CGFloat!

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required convenience init(baseView: UIView, text: String, subtitle: String? = nil, fontSize: CGFloat = 17) {
        // Calculate relative sizes
        let padding = fontSize * 0.7
        let triangleHeight = fontSize * 0.5
        let radius = fontSize * 1.2
        let borderWidth = fontSize * 0.25
        let margin = fontSize * 0.14 // margin between the baseview and balloon
        let edgeCurve = fontSize * 0.14 // smaller the curvier
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: fontSize)
        label.text = text
        
        
        
        let labelSize = label.intrinsicContentSize

        var width = labelSize.width + padding * 3 // 50% more padding on width
        var height = labelSize.height + triangleHeight + padding * 2
        
        var label2: UILabel!
        
        
        if subtitle != nil, !(subtitle?.isEmpty ?? false){
            label2 = UILabel()
            label2.font = UIFont.systemFont(ofSize: fontSize - 3)
            label2.text = subtitle
            
            let label2Size = label2.intrinsicContentSize

            if label2Size.width > labelSize.width{
                width = label2Size.width + padding * 3
            }
            
            height += label2Size.height
            
            label2.frame = CGRect(x: padding, y: padding + labelSize.height, width: label2Size.width + padding, height: label2Size.height)
            label2.textAlignment = .center
            label2.textColor = .white
        }
        
        let bubbleRect = CGRect(x: baseView.center.x - width / 2, y: baseView.center.y - (baseView.bounds.height / 2) - (height + margin), width: width, height: height)

        self.init(frame: bubbleRect)

        self.triangleHeight = triangleHeight
        self.radius = radius
        self.borderWidth = borderWidth
        self.edgeCurve = edgeCurve

        label.frame = CGRect(x: padding, y: padding, width: labelSize.width + padding, height: labelSize.height)
        label.textAlignment = .center
        label.textColor = strokeColor
        label.center.x = bubbleRect.width / 2
        self.addSubview(label)
        if let lbl = label2{
            lbl.center.x = bubbleRect.width / 2
            self.addSubview(lbl)
        }

    }

    override func draw(_ rect: CGRect) {
        let bubble = CGRect(x: 0, y: 0, width: rect.width - radius * 2, height: rect.height - (radius * 2 + triangleHeight)).offsetBy(dx: radius, dy: radius)
        let path = UIBezierPath()
        let radius2 = radius - borderWidth // Radius adjasted for the border width
        
        
        path.addArc(withCenter:CGPoint(x: bubble.maxX, y: bubble.minY), radius: radius2, startAngle: -(.pi / 2), endAngle: 0, clockwise: true)
        path.addArc(withCenter: CGPoint(x: bubble.maxX, y: bubble.maxY), radius: radius2, startAngle: 0, endAngle: .pi / 2, clockwise: true)
        path.addLine(to: CGPoint(x: bubble.minX + bubble.width / 2 + triangleHeight * 1.2, y: bubble.maxY + radius2))

        // The speech bubble edge
        path.addQuadCurve(to: CGPoint(x: bubble.minX + bubble.width / 2, y: bubble.maxY + radius2 + triangleHeight), controlPoint: CGPoint(x: bubble.minX + bubble.width / 2 + edgeCurve, y: bubble.maxY + radius2 + edgeCurve))
        path.addQuadCurve(to: CGPoint(x: bubble.minX + bubble.width / 2 - triangleHeight * 1.2, y: bubble.maxY + radius2), controlPoint: CGPoint(x: bubble.minX + bubble.width / 2 - edgeCurve, y: bubble.maxY + radius2 + edgeCurve))
        // For non-curvy edges
        //path.addLine(to: CGPoint(x: bubble.minX + bubble.width / 2, y: bubble.maxY + radius2 + triangleHeight))
        //path.addLine(to: CGPoint(x: bubble.minX + bubble.width / 2 - triangleHeight, y: bubble.maxY + radius2))
        path.addArc(withCenter: CGPoint(x: bubble.minX, y:  bubble.maxY), radius: radius2, startAngle: .pi / 2, endAngle: .pi, clockwise: true)
        path.addArc(withCenter: CGPoint(x: bubble.minX, y: bubble.minY), radius: radius2, startAngle: .pi, endAngle: -(.pi / 2), clockwise: true)
        path.close()

        fillColor.setFill()
        strokeColor.setStroke()
        path.lineWidth = borderWidth
        path.stroke()
        path.fill()
    }
}
