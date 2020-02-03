//
//  LoadingHeaderView.swift
//  
//
//  Created by Arta Koroushnia on 2019-11-18.
//

import UIKit

class LoadingHeaderView: UIView {

    var cp: MapSpinnerView! = MapSpinnerView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
    
    override func awakeFromNib() {
        super.awakeFromNib()

    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(cp)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        cp.center = self.center
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
