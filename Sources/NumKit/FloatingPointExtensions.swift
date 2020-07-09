//
//  FloatingPointExtensions.swift
//  RosaKit
//
//  Created by Hrebeniuk Dmytro on 17.12.2019.
//  Copyright © 2019 Dmytro Hrebeniuk. All rights reserved.
//

import Foundation
import CoreGraphics

extension FloatingPoint {
    
    var byteArray: [UInt8] {
        var value = self
        return withUnsafeBytes(of: &value) { Array($0) }
    }
        
    static func MEL<T: FloatingPoint>(fromHZ frequency: T) -> T {
        let fmin = T(0)
        let fsp = T(200) / T(3)

        var mels = (frequency - fmin) / fsp

        let minLogHZ = T(1000)
        let minLogMEL = (minLogHZ - fmin) / fsp
        let logStep = ((T(64)/T(10)).logarithm() as T)/T(27)
        
        if frequency >= minLogHZ {
            mels = minLogMEL + (frequency / minLogHZ).logarithm() / logStep
        }
        
        return mels
    }
    
    static func HZ<T: FloatingPoint>(fromMEL mels: T) -> T {
        let fmin = T(0)
        let fsp = T(200) / T(3)

        var freqs = fmin + fsp*mels
        
        let minLogHZ = T(1000)
        let minLogMEL = (minLogHZ - fmin) / fsp
        
        let logStep = ((T(64)/T(10)).logarithm() as T)/T(27)

        if mels >= minLogMEL {
            let exponent = (logStep as T * (mels - minLogMEL)).exponent() as T
            freqs = minLogHZ*exponent
        }        
        
        return freqs
    }
    
    func logarithm10<T: FloatingPoint>() -> T {
        switch self {
        case let self as Double:
            return log10(self) as? T ?? 0
        case let self as CGFloat:
            return log10f(Float(self)) as? T ?? 0
        case let self as Float:
            return log10f(Float(self)) as? T ?? 0
        default:
            return 0 as T
        }
    }
    
    func logarithm<T: FloatingPoint>() -> T {
        switch self {
        case let self as Double:
            return log(self) as? T ?? 0
        case let self as CGFloat:
            return logf(Float(self)) as? T ?? 0
        case let self as Float:
            return logf(Float(self)) as? T ?? 0
        default:
            return 0 as T
        }
    }
    
    func exponent<T: FloatingPoint>() -> T {
        switch self {
        case let self as Double:
            return exp(self) as? T ?? 0
        case let self as CGFloat:
            return expf(Float(self)) as? T ?? 0
        case let self as Float:
            return expf(Float(self)) as? T ?? 0
        default:
            return 0 as T
        }
    }
    
    func cosine<T: FloatingPoint>() -> T {
        switch self {
        case let self as Double:
            return cos(-self) as? T ?? 0
        case let self as CGFloat:
            return cosf(-Float(self)) as? T ?? 0
        case let self as Float:
            return cosf(-Float(self)) as? T ?? 0
        default:
            return 0 as T
        }
    }
    
}
