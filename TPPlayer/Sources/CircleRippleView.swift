//
//  RippleView.swift
//  TPPlayer
//
//  Created by Truc Pham on 04/10/2021.
//

import Foundation
import UIKit
class CircleRippleView : UIView {
    var imageViewConstants : AppConstants = .init()
    enum Position {
        case left, right
    }
    private lazy var imageView : UIImageView = {
        let v = UIImageView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var lblView : UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 15)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.numberOfLines = 1
        v.textColor = .white
        return v
    }()
    var position : Position = .left
    private var extendRadius : CGFloat = 50
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // cricle
        let raidus = self.bounds.height + extendRadius
        var center : CGPoint = .zero
        switch position {
        case .left:
            center = .init(x: -(raidus - self.bounds.width), y: self.bounds.height / 2)
        case .right:
            center = .init(x: raidus, y: self.bounds.height / 2)
           
        }
        let myBez = UIBezierPath()
        myBez.addArc(withCenter: center, radius: raidus, startAngle: 0, endAngle: 360, clockwise: true)
        myBez.close()
        let l = CAShapeLayer()
        l.path = myBez.cgPath
        layer.mask = l
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        prepareUI()
    }

    func setImage(_ image : UIImage?){
        self.imageView.image = image
    }
    func setText(_ number: Int){
        self.lblView.text = "\(number) giây"
    }
    func beginRippleTouchUp(animated: Bool){
        self.rippleStop()
    }
    
    func beginRippleTouchDown(at: CGPoint, animated: Bool){
        self.rippleFill(location: at, color: .lightGray, scale: 2*(self.bounds.height + extendRadius))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func prepareUI(){
        self.clipsToBounds = true
        self.addSubview(self.imageView)
        self.addSubview(self.lblView)
        imageViewConstants = .init(width: self.imageView.widthAnchor.constraint(equalTo: self.imageView.heightAnchor), height: self.imageView.heightAnchor.constraint(equalToConstant: 32),centerX: self.imageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),centerY: self.imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -10))
        NSLayoutConstraint.activate([
            self.lblView.topAnchor.constraint(equalTo: self.imageView.bottomAnchor, constant: 10),
            self.lblView.centerXAnchor.constraint(equalTo: self.imageView.centerXAnchor),
        ])
        
        imageViewConstants.active()
    }
}
