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
    
    func reflectPad(fftSize: Int) -> [Element] {
        var array = self
      
        for index in 0..<fftSize {
            let leftElement = self[index + 1]
            let oldArray = array
            array = [leftElement]
            array.append(contentsOf: oldArray)
            
            let rightElement = self[self.count - 1 - index - 1]
            array.append(rightElement)
        }
        
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
    
    static func getHannWindow(frameLength: Element) -> [Element] {
        let linespacePI = linespace(start: -Element.pi, stop: Element.pi, num: frameLength + 1)
        let one = frameLength/frameLength

        return linespacePI.map { ((one + ($0.cosine() as Element))/Element(2)) }.reversed().dropLast()
    }
}
