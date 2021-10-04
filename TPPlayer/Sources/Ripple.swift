//
//  Ripple.swift
//  TPPlayer
//
//  Created by Truc Pham on 04/10/2021.
//

import Foundation
import UIKit

public extension UIView {
    func rippleFill(location:CGPoint, color:UIColor) {
        rippleFill(location: location, color: color){}
    }
    
    func rippleFill(location:CGPoint, color:UIColor, then:@escaping ()->() ) {
        Ripple().fill(view: self, locationInView: location, color: color, then: then)
    }
    
    func rippleStop() {
        Ripple().stop(view: self)
    }
    
}

class RippleLayer : CALayer {
    
}

public class Ripple {
    
    public struct Option {
        public var borderWidth = CGFloat(5.0)
        public var radius = CGFloat(30.0)
        public var duration = CFTimeInterval(0.4)
        public var borderColor = UIColor.white
        public var fillColor = UIColor.clear
        public var scale = CGFloat(20.0)
        public var isRunSuperView = false
    }
    
    public func fill(view:UIView, locationInView:CGPoint, color:UIColor,then:@escaping ()->() ) {
        var opt = Ripple.Option()
        opt.borderColor = color
        opt.fillColor = color
        prePreform(view: view, point: locationInView, option: opt, isLocationInView: opt.isRunSuperView , then: then)
    }
    
    private func prePreform(view:UIView, point:CGPoint, option: Ripple.Option, isLocationInView:Bool, then:@escaping ()->() ) {
        
        let p = isLocationInView ? CGPoint(x: point.x + view.frame.origin.x, y: point.y + view.frame.origin.y) : point
        if isLocationInView, let superview = view.superview {
            prePreform(
                view: superview,
                point: p,
                option: option,
                isLocationInView: isLocationInView,
                then: then
            )
        } else {
            perform(
                view: view,
                point:p,
                option:option,
                then: then
            )
        }
    }
    
    private func perform(view:UIView, point:CGPoint, option: Ripple.Option, then: @escaping ()->() ) {
        UIGraphicsBeginImageContextWithOptions (
            CGSize(width: (option.radius + option.borderWidth) * 2,height: (option.radius + option.borderWidth) * 2), false, 3.0)
        let path = UIBezierPath(
            roundedRect: CGRect(x: option.borderWidth, y: option.borderWidth, width: option.radius * 2, height: option.radius * 2),
            cornerRadius: option.radius)
        option.fillColor.setFill()
        path.fill()
        option.borderColor.setStroke()
        path.lineWidth = option.borderWidth
        path.stroke()
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let opacity = CABasicAnimation(keyPath: "opacity")
        opacity.autoreverses = false
        opacity.fillMode = CAMediaTimingFillMode.forwards
        opacity.isRemovedOnCompletion = false
        opacity.duration = option.duration
        opacity.fromValue = 1.0
        opacity.toValue = 0.0
        
        let transform = CABasicAnimation(keyPath: "transform")
        transform.autoreverses = false
        transform.fillMode = CAMediaTimingFillMode.forwards
        transform.isRemovedOnCompletion = false
        transform.duration = option.duration
        transform.fromValue = NSValue(caTransform3D: CATransform3DMakeScale(1.0 / option.scale, 1.0 / option.scale, 1.0))
        transform.toValue = NSValue(caTransform3D: CATransform3DMakeScale(option.scale, option.scale, 1.0))
        
        var rippleLayer = view.layer.sublayers?.first(where: { $0 is RippleLayer })
        
        if rippleLayer == nil {
            rippleLayer = RippleLayer()
            view.layer.addSublayer(rippleLayer!)
        }
        DispatchQueue.main.async {
            if let target = rippleLayer {
                let layer = CALayer()
                layer.contents = img?.cgImage
                layer.frame = CGRect(x: point.x - option.radius, y: point.y - option.radius, width: option.radius * 2, height: option.radius * 2)
                target.addSublayer(layer)
                CATransaction.begin()
                CATransaction.setAnimationDuration(option.duration)
                CATransaction.setCompletionBlock({
                    layer.contents = nil
                    layer.removeAllAnimations()
                    layer.removeFromSuperlayer()
                    then()
                })
                layer.add(opacity, forKey:nil)
                layer.add(transform, forKey:nil)
                CATransaction.commit()
            }
        }
    }
    
    public func stop(view:UIView) {
        
        guard let sublayer = view.layer.sublayers?.first(where: { $0 is RippleLayer }) else {
            return
        }
        sublayer.removeAllAnimations()
    }
    
}
