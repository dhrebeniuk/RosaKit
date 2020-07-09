//
//  RosaFloatingPointExtensions.swift
//  RosaKitMacOS
//
//  Created by Hrebeniuk Dmytro on 10.01.2020.
//

import Foundation
import CoreGraphics

extension FloatingPoint {
    
    func powerToDB<T: FloatingPoint>() -> T {
        switch self {
        case let self as Double:
            return Double(10.0) * log10(self) as? T ?? 0
        case let self as CGFloat:
            return Float(10.0) * log10f(Float(self)) as? T ?? 0
        case let self as Float:
            return Float(10.0) * log10f(self) as? T ?? 0
        default:
            return 0 as T
        }
    }
    
    func dbToPower<T: FloatingPoint>() -> T {
        switch self {
        case let self as Double:
            return pow(Double(10.0), self/Double(10.0)) as? T ?? 0
        case let self as CGFloat:
            return powf(Float(10.0), Float(self)/Float(10.0)) as? T ?? 0
        case let self as Float:
            return powf(Float(10.0), self/Float(10.0)) as? T ?? 0
        default:
            return 0 as T
        }
    }
    
}
