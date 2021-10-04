//
//  Math.swift
//  TPPlayer
//
//  Created by Truc Pham on 01/10/2021.
//

import Foundation
import UIKit
protocol NumericType: Comparable {
    static func + (lhs: Self, rhs: Self) -> Self
    static func - (lhs: Self, rhs: Self) -> Self
    static func * (lhs: Self, rhs: Self) -> Self
    static func / (lhs: Self, rhs: Self) -> Self
    init(_ value: Int)
}
extension Double : NumericType { }
extension Float  : NumericType { }
extension Int    : NumericType { }
extension Int8   : NumericType { }
extension Int16  : NumericType { }
extension Int32  : NumericType { }
extension Int64  : NumericType { }
extension UInt   : NumericType { }
extension UInt8  : NumericType { }
extension UInt16 : NumericType { }
extension UInt32 : NumericType { }
extension UInt64 : NumericType { }
extension CGFloat : NumericType { }
internal func rangeMap<T: NumericType>(_ value: T, min: T, max: T, newMin: T, newMax: T) -> T {
    return (((value - min) * (newMax - newMin)) / (max - min)) + newMin
}
internal func clamp<T: NumericType>(_ value: T, lower: T, upper: T) -> T {
    return min(max(value, lower), upper)
}
