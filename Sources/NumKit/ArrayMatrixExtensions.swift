//
//  ArrayMatrixExtensions.swift
//  RosaKit
//
//  Created by Hrebeniuk Dmytro on 20.12.2019.
//  Copyright © 2019 Dmytro Hrebeniuk. All rights reserved.
//

import Foundation
import Accelerate

public extension Array {
    
    static func multplyVector(matrix1: [[Double]], matrix2: [[Double]]) -> [[Double]] {
        let newMatrixCols = matrix1.count
        let newMatrixRows = matrix2.first?.count ?? 1
        
        var result = [Double](repeating: 0.0, count: newMatrixCols*newMatrixRows)

        let flatMatrix1 = matrix1.flatMap { $0 }
        let flatMatrix2 = matrix2.flatMap { $0 }
        
        for index in 0..<result.count {
            result[index] = flatMatrix2[index]*flatMatrix1[index/newMatrixRows]
        }
        
        let matrixResult = result.chunked(into: newMatrixRows)
        
        return matrixResult
    }
    
    static func divideVector(matrix1: [[Double]], matrix2: [[Double]]) -> [[Double]] {
        let newMatrixCols = matrix1.count
        let newMatrixRows = matrix2.first?.count ?? 1
        
        var result = [Double](repeating: 0.0, count: newMatrixCols*newMatrixRows)

        let flatMatrix1 = matrix1.flatMap { $0 }
        let flatMatrix2 = matrix2.flatMap { $0 }
        
        for index in 0..<result.count {
            result[index] = flatMatrix2[index]/flatMatrix1[index/newMatrixRows]
        }
        
        let matrixResult = result.chunked(into: newMatrixRows)
        
        return matrixResult
    }
    
    static func divideFlatVector<T: FloatingPoint>(matrix1: [T], matrix2: [T]) -> [T] {
        let minCount = Swift.min(matrix1.count, matrix2.count)
        
        var result = [T](repeating: 0, count: minCount)
        
        for index in 0..<minCount {
            result[index] = matrix1[index]/matrix2[index]
        }
        
        return result
    }
    
    static func minimumFlatVector<T: FloatingPoint>(matrix1: [T], matrix2: [T]) -> [T] {
        let minCount = Swift.min(matrix1.count, matrix2.count)
        
        var result = [T](repeating: 0, count: minCount)
        
        for index in 0..<minCount {
            result[index] = Swift.min(matrix1[index], matrix2[index])
        }
        
        return result
    }

    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
    
}

extension Array where Element == [Double] {
 
    public var transposed: [[Double]] {
        let matrix = self
        let newMatrixCols = matrix.count
        let newMatrixRows = matrix.first?.count ?? 1
        
        var results = [Double](repeating: 0.0, count: newMatrixCols*newMatrixRows)

        vDSP_mtransD(matrix.flatMap { $0 }, 1, &results, 1, vDSP_Length(newMatrixRows), vDSP_Length(newMatrixCols))
        
        return results.chunked(into: newMatrixCols)
    }
    
    func multiplyVector(matrix: [Element]) -> [Element] {
        let newMatrixCols = self.count
        let newMatrixRows = matrix.first?.count ?? 1
        
        var result = [Double](repeating: 0.0, count: newMatrixCols*newMatrixRows)

        let flatMatrix1 = self.flatMap { $0 }
        let flatMatrix2 = matrix.flatMap { $0 }
        
        for index in 0..<result.count {
            result[index] = flatMatrix2[index]*flatMatrix1[index/newMatrixRows]
        }
        
        let matrixResult = result.chunked(into: newMatrixRows)
        
        return matrixResult
    }
    
    public func dot(matrix: [Element]) -> [Element] {
        let matrixRows = matrix.count
        let matrixCols = matrix.first?.count ?? 1
        
        let selfMatrixRows = self.count

        var result = [Double](repeating: 0.0, count: Int(selfMatrixRows * matrixCols))

        let flatMatrix1 = self.flatMap { $0 }
        let flatMatrix2 = matrix.flatMap { $0 }
        
        vDSP_mmulD(flatMatrix1, 1, flatMatrix2, 1, &result, 1, vDSP_Length(selfMatrixRows), vDSP_Length(matrixCols), vDSP_Length(matrixRows))

        return result.chunked(into: Int(matrixCols))
    }
}


extension Array where Element == [(real: Double, imagine: Double)] {
    
    public var transposed: [Element] {
        let matrix = self
        let newMatrixCols = matrix.count
        let newMatrixRows = matrix.first?.count ?? 1
        
        var resultsCols = [[(real: Double, imagine: Double)]].init(repeating: [(real: Double, imagine: Double)](), count: newMatrixRows)
        
        for col in 0..<newMatrixRows {
            var resultsRows = [(real: Double, imagine: Double)].init(repeating: (real: 0.0, imagine: 0.0), count: newMatrixCols)
            for row in 0..<newMatrixCols {
                resultsRows[row] = matrix[row][col]
            }
            resultsCols[col] = resultsRows
        }
        
        return resultsCols
    }
    
}
