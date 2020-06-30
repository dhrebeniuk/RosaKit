//
//  ArrayDoubleExtensions.swift
//  RosaKit
//
//  Created by Hrebeniuk Dmytro on 17.12.2019.
//  Copyright © 2019 Dmytro Hrebeniuk. All rights reserved.
//

import Foundation

extension Array where Iterator.Element: FloatingPoint {
        
    func floatingPointStrided(shape: (width: Int, height: Int), stride: (xStride: Int, yStride: Int)? = nil) -> [[Element]] {
        var resultArray: [[Element]] = []
        
        var lineArray = [Element]()
                
        let byteStrideX = stride?.xStride ?? 1
        let byteStrideY = stride?.yStride ?? shape.height
        var byteOffsetX: Int = 0
        var byteOffsetY: Int = 0
        for _ in 0..<shape.width*shape.height {
            
            let value = self[byteOffsetX + byteOffsetY]
            lineArray.append(value)
            
            byteOffsetX += byteStrideX

            if lineArray.count == shape.height {
                resultArray.append(lineArray)
                lineArray = [Element]()
                
                byteOffsetY += byteStrideY
                byteOffsetX = 0
            }
        }
        
        return resultArray
    }
    
    func strided(shape: (width: Int, height: Int), stride: (xStride: Int, yStride: Int)? = nil) -> [[Element]] {
        let elementSize = MemoryLayout<Element>.size
        return floatingPointStrided(shape: shape, stride: (xStride: (stride?.xStride ?? elementSize)/elementSize, yStride:  (stride?.yStride ?? elementSize)/elementSize))
    }
    
    var diff: [Element] {
        var diff = [Element]()
        
        for index in 1..<self.count {
            let value = self[index]-self[index-1]
            diff.append(value)
        }
        
        return diff
    }
    
    func outerSubstract(array: [Element]) -> [[Element]] {
        var result = [[Element]]()
        
        let rows = self.count
        let cols = array.count
        
        for row in 0..<rows {
            var rowValues = [Element]()
            for col in 0..<cols {
                let value = self[row] - array[col]
                rowValues.append(value)
            }
            
            result.append(rowValues)
        }
        
        return result
    }
    
    func frame(frameLength: Int = 2048, hopLength: Int = 512) -> [[Element]] {
        
        let framesCount = 1 + (self.count - frameLength) / hopLength
        let strides = MemoryLayout.size(ofValue: Element(0))
        
        return strided(shape: (width: frameLength, height: framesCount), stride: (xStride: strides*hopLength, yStride: strides))
    }
    
}
