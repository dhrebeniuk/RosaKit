//
//  ArrayExtensions.swift
//  RosaKit
//
//  Created by Hrebeniuk Dmytro on 15.12.2019.
//  Copyright © 2019 Dmytro Hrebeniuk. All rights reserved.
//

import Foundation

extension Array where Iterator.Element: FloatingPoint {
    
    static func empty(width: Int, height: Int, defaultValue: Element) -> [[Element]] {
        var result: [[Element]] = [[Element]]()
        
        for _ in 0..<width {
            var vertialArray: [Element] = [Element]()
            for _ in 0..<height {
                vertialArray.append(defaultValue)
            }
            result.append(vertialArray)
        }
        
        return result
    }
    
    static func zeros(length: Int) -> [Element] {
        var result: [Element] = [Element]()
        
        for _ in 0..<length {
            result.append(Element.zero)
        }
        
        return result
    }
    
    func reflectPad(fftSize: Int) -> [Element] {
        var array = [Element]()
        
        array.append(contentsOf: [Element].init(repeating: Element(0), count: fftSize/2))
        array.append(contentsOf: self)
        array.append(contentsOf: [Element].init(repeating: Element(0), count: fftSize/2))

        return array
    }
 
    static func linespace(start: Element, stop: Element, num: Element) -> [Element] {
        var linespace = [Element]()
    
        let one = num/num
        var index = num*0
        while index < num-one {
            let startPart = (start*(one - index/floor(num - one)))
            let stopPart = (index*stop/floor(num - one))

            let value = startPart + stopPart

            linespace.append(value)
            index += num/num
        }
        
        linespace.append(stop)
                
        return linespace
    }
    


}

extension Array where Iterator.Element == Double {
    
    static func getHannWindow(frameLength: Int) -> [Double] {
        let fac = [Double].linespace(start: -Double.pi, stop: Double.pi, num: Double(frameLength + 1))

        var w = [Double](repeating: 0.0, count: frameLength+1)
        
        for (k, a) in [0.5, 0.5].enumerated(){
            for index in 0..<w.count {
                w[index] += a*cos(Double(k)*fac[index])
            }
        }

        return Array(w[0..<w.count-1])
    }

    static func windowHannSumsquare(nFrames: Int, winLength: Int, nFFt: Int, hopLength: Int) -> [Double] {
        let nCount = nFFt + hopLength * (nFrames - 1)

        var x = Self.zeros(length: nCount)

        var winSQ = getHannWindow(frameLength: (winLength)).map { Double($0)*Double(($0)) }

        for index in 0..<nFrames {
            let sample = index * hopLength

            let xDiff = winSQ[0..<Swift.max(0, Swift.min(winSQ.count, x.count - sample))]

            for index in 0..<Swift.min(nCount, xDiff.count) {
                x[sample + index] += xDiff[index]
            }
        }

        return x
    }
    
}
