//
//  ArrayLibRosaExtensions.swift
//  RosaKit
//
//  Created by Hrebeniuk Dmytro on 23.12.2019.
//  Copyright © 2019 Dmytro Hrebeniuk. All rights reserved.
//

import Foundation

public extension Array where Iterator.Element: FloatingPoint {
    
    static func createFFTFrequencies(sampleRate: Int, FTTCount: Int) -> [Element] {
        return [Element].linespace(start: 0, stop: Element(sampleRate)/Element(2), num: Element(1 + FTTCount/2))
    }
    
    static func createMELFrequencies(MELCount: Int, fmin: Element, fmax: Element) -> [Element] {
        let minMEL = Element.MEL(fromHZ: fmin)
        let maxMEL = Element.MEL(fromHZ: fmax)
        
        let mels = [Element].linespace(start: minMEL, stop: maxMEL, num: Element(MELCount))

        return mels.map { Element.HZ(fromMEL: $0) }
    }
    
    static func createMelFilter(sampleRate: Int, FTTCount: Int, melsCount: Int = 128) -> [[Element]] {
        let fmin = Element(0)
        let fmax = Element(sampleRate) / 2

        var weights = [Element].empty(width: melsCount, height: 1 + FTTCount/2, defaultValue: Element(0))

        let FFTFreqs = [Element].createFFTFrequencies(sampleRate: sampleRate, FTTCount: FTTCount)

        let MELFreqs = [Element].createMELFrequencies(MELCount: melsCount + 2, fmin: fmin, fmax: fmax)

        let diff = MELFreqs.diff
        
        let ramps = MELFreqs.outerSubstract(array: FFTFreqs)
        
        for index in 0..<melsCount {
            let lower = ramps[index].map { -$0 / diff[index] }
            let upper = ramps[index+2].map { $0 / diff[index+1] }
          
            weights[index] = [Element].minimumFlatVector(matrix1: lower, matrix2: upper).map { Swift.max(Element(0), $0) }
        }

        for index in 0..<melsCount {
            let enorm = Element(2) / (MELFreqs[index+2] - MELFreqs[index])
            weights[index] = weights[index].map { $0*enorm }
        }

        return weights
    }

    func powerToDB(ref: Element = Element(1), amin: Element = Element(1)/Element(Int64(10000000000)), topDB: Element = Element(80)) -> [Element] {
        let ten = Element(10)
        
        let logSpec = map { ten * (Swift.max(amin, $0)).logarithm10() - ten * (Swift.max(amin, abs(ref))).logarithm10() }
        
        let maximum = (logSpec.max() ?? Element(0))
        
        return logSpec.map { Swift.max($0, maximum - topDB) }
    }
    
    func normalizeAudioPower() -> [Element] {
        var dbValues = powerToDB()
            
        let minimum = (dbValues.min() ?? Element(0))
        dbValues = dbValues.map { $0 -  minimum}
        let maximun = (dbValues.map { abs($0) }.max() ?? Element(0))
        dbValues = dbValues.map { $0/(maximun + Element(1)) }
        return dbValues
    }
}

public extension Array where Element == Double {
    
    func stft(nFFT: Int = 256, hopLength: Int = 1024) -> [[Double]] {
        let FFTWindow = [Double].getHannWindow(frameLength: Double(nFFT)).map { [$0] }

        let centered = self.reflectPad(fftSize: nFFT/2)
        
        let yFrames = centered.frame(frameLength: nFFT, hopLength: hopLength)

        let matrix = FFTWindow.multiplyVector(matrix: yFrames)
                
        let rfftMatrix = matrix.rfft
                        
        let result = rfftMatrix
        
        return result
    }
    
    func melspectrogram(nFFT: Int = 2048, hopLength: Int = 512, sampleRate: Int = 22050, melsCount: Int = 128) -> [[Double]] {
        let spectrogram = self.stft(nFFT: nFFT, hopLength: hopLength).map { $0.map { pow($0, 2.0) } }
        let melBasis = [Double].createMelFilter(sampleRate: sampleRate, FTTCount: nFFT, melsCount: melsCount)
        return melBasis.dot(matrix: spectrogram)
    }
    
}

extension Array where Element == [Double] {
    
    var rfft: [[Double]] {
        let transposed = self.transposed
        let cols = transposed.count
        let rows = transposed.first?.count ?? 1
        let rfftRows = rows/2 + 1
        let flatMatrix = transposed.flatMap { $0 }
        
        let rfftCount = rfftRows*cols
        var resultComplexMatrix = [Double](repeating: 0.0, count: (rfftCount + cols + 1)*2)
                        
        resultComplexMatrix.withUnsafeMutableBytes { destinationData -> Void in
            let destinationDoubleData = destinationData.bindMemory(to: Double.self).baseAddress
            flatMatrix.withUnsafeBytes { (flatData) -> Void in
                let sourceDoubleData = flatData.bindMemory(to: Double.self).baseAddress
                execute_real_forward(sourceDoubleData, destinationDoubleData, Int32(cols), Int32(rows), 1)
            }
        }

        var realMatrix = [Double](repeating: 0.0, count: rfftCount)

        for index in 0..<rfftCount {
            let real = resultComplexMatrix[index*2]
            let imagine = resultComplexMatrix[index*2+1]
            realMatrix[index] = sqrt(pow(real, 2) + pow(imagine, 2))
        }
        
        let result = realMatrix.chunked(into: rfftRows).transposed
            
        return result
    }
    
    public func normalizeAudioPowerArray() -> [[Double]] {
        let chunkSize = self.first?.count ?? 0
        let dbValues = self.flatMap { $0 }.normalizeAudioPower().chunked(into: chunkSize)
        return dbValues
    }
}
