//
//  DataExtensions.swift
//  RosaKit
//
//  Created by Hrebeniuk Dmytro on 17.12.2019.
//  Copyright © 2019 Dmytro Hrebeniuk. All rights reserved.
//

import Foundation

public extension Data {
    
    func generateArray<T: BinaryInteger>() -> [T] {
        return self.withUnsafeBytes { rawPointer -> [T] in
            let words = rawPointer.bindMemory(to: T.self)
            var array: [T] = [T]()
            for index in 0..<words.count {
                array.append(words[index])
            }
            
            return array
        }
    }
    
    var int16Array: [Int16] {
        return self.withUnsafeBytes { rawPointer -> [Int16] in
            let words = rawPointer.bindMemory(to: Int16.self)
            var array: [Int16] = []
            for index in 0..<words.count {
                array.append(words[index])
            }
            
            return array
        }
    }
    
    var int8Array: [Int8] {
        return self.withUnsafeBytes { rawPointer -> [Int8] in
            let words = rawPointer.bindMemory(to: Int8.self)
            var array: [Int8] = []
            for index in 0..<words.count {
                array.append(words[index])
            }
            
            return array
        }
    }
    
    var float32Array: [Float] {
        return self.withUnsafeBytes { rawPointer -> [Float] in
            let words = rawPointer.bindMemory(to: Float32.self)
            var array: [Float] = []
            for index in 0..<words.count {
                array.append(Float(words[index]))
            }
            
            return array
        }
    }
    
}
