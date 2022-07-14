//
//  ArrayLibRosaExtensions.swift
//  RosaKit
//
//  Created by Hrebeniuk Dmytro on 23.12.2019.
//  Copyright © 2019 Dmytro Hrebeniuk. All rights reserved.
//

import Foundation
import PocketFFT
import PlainPocketFFT


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
    
    func stft(nFFT: Int = 256, hopLength: Int = 1024) -> [[(real: Double, imagine: Double)]] {
        let FFTWindow = [Double].getHannWindow(frameLength: (nFFT)).map { [$0] }

        let centered = self.reflectPad(fftSize: nFFT)
        
        let yFrames = centered.frame(frameLength: nFFT, hopLength: hopLength)

        let matrix = FFTWindow.multiplyVector(matrix: yFrames)
                
        let rfftMatrix = matrix.rfft
                        
        let result = rfftMatrix
        
        return result
    }
        
    func melspectrogram(nFFT: Int = 2048, hopLength: Int = 512, sampleRate: Int = 22050, melsCount: Int = 128) -> [[Double]] {
        let spectrogram = self.stft(nFFT: nFFT, hopLength: hopLength)
            .map { $0.map { sqrt(pow($0.real, 2.0) + pow($0.imagine, 2.0)) } }
        let melBasis = [Double].createMelFilter(sampleRate: sampleRate, FTTCount: nFFT, melsCount: melsCount)
        return melBasis.dot(matrix: spectrogram)
    }
    
    func mfcc(nMFCC: Int = 20, nFFT: Int = 2048, hopLength: Int = 512, sampleRate: Int = 22050, melsCount: Int = 128) -> [[Double]] {
        let melSpectrogram = self.melspectrogram(nFFT: nFFT, hopLength: hopLength, sampleRate: sampleRate, melsCount: melsCount)
        var S = melSpectrogram.map { $0.powerToDB() }
        
        let cols = S.count
        let rows = S[0].count
        
        var resultArray = [Double](repeating: 0.0, count: cols*rows)

        S.withUnsafeMutableBytes { flatData -> Void in
            let sourceDoubleData = flatData.bindMemory(to: Double.self).baseAddress
            
            resultArray.withUnsafeMutableBytes {  destinationData -> Void in
                let destinationDoubleData = destinationData.bindMemory(to: Double.self).baseAddress

                PocketFFTRunner.execute_dct(sourceDoubleData, result: destinationDoubleData, dctType: 2, inorm: 1, cols: Int32(cols), rows: Int32(rows))
            }
        }
        
        let mfccResult = resultArray.chunked(into: rows)[0..<nMFCC]
        
        return [[Double]].init(mfccResult)
    }
    
}

public extension Array where Element == [(real: Double, imagine: Double)] {
    
    func istft(hopLength inputHopLength: Int?) -> [Double] {
        let nFFT = 2 * (self.count - 1)
        let winLength = nFFT
        let hopLength = inputHopLength ?? winLength / 4

        let iFFTWindow = [Double].getHannWindow(frameLength: nFFT).map { [$0] }
        
        let nFramesCount = self[0].count

        let expectedSignalLen = nFFT + hopLength * (nFramesCount - 1)
        
        let nCollumns = (4096 * MemoryLayout<Double>.size) / self.count
  
        var y = Array<Double>(repeating: 0.0, count: expectedSignalLen)
        
        var frame = 0
        
        for index in 0...(nFramesCount / nCollumns) {
            let blS = index * nCollumns
            let blT = Swift.min(blS + nCollumns, nFramesCount)
            
            let size = blT - blS
            var resultArray = Array<Double>(repeating: 0.0, count: size*self.count)
            
            let norm = nFFT
            let fct = 1.0 / Double(nFFT)
                 
            let trimmedMatrix = self.map { Array<(real: Double, imagine: Double)>($0[blS..<blT]) }
            
            var irfftMatrix = trimmedMatrix.irfft
            
            let ytmp = iFFTWindow.multiplyVector(matrix: irfftMatrix)
            
            let ytmpIndex = frame*hopLength;
            
            let ytmpCollumns = ytmp.first?.count ?? 0
            for frameIndex in 0..<ytmpCollumns {
                let sample = frameIndex * hopLength
                let yDiff = ytmp.flatMap { $0[frameIndex] }
                for index in 0..<yDiff.count {
                    y[ytmpIndex + sample + index] += yDiff[index]
                }
            }
            
            frame += blT - blS
        }
        
        let winSQ = [Double].windowHannSumsquare(nFrames: nFramesCount, winLength: winLength, nFFt: nFFT, hopLength: hopLength)
        
        for index in 0..<winSQ.count {
            if winSQ[index] > Double.leastNonzeroMagnitude {
                y[index] /= (winSQ[index]);
            }
        }
        
        return y
    }
  
    var irfft: [[Double]] {
        let invNorm = (self.count - 1) * 2
        let cols = self.count
        let rows = self.first?.count ?? 0
        
        var slicedMatrix = Array<Array<(real: Double, imagine: Double)>>(repeating: Array<(real: Double, imagine: Double)>(repeating: (real: 0.0, imagine: 0.0), count: rows), count: invNorm);
        
        for colIndex in 0..<cols {
            for rowIndex in 0..<rows {
                slicedMatrix[colIndex][rowIndex] = self[colIndex][rowIndex]
            }
        }
        
        slicedMatrix = slicedMatrix.transposed
        
        let fct = 1.0 / Double(invNorm)

        var stftChunk = slicedMatrix.map { $0.flatMap { [$0.real, $0.imagine] } } .flatMap { $0.flatMap { $0 } }

        var resultArray = [Double].init(repeating: 0.0, count: invNorm*rows)
        stftChunk.withUnsafeMutableBytes { stftChunkData -> Void in
            let stftChunkDataDoubleData = stftChunkData.bindMemory(to: Double.self).baseAddress
            resultArray.withUnsafeMutableBytes { (resultArrayFlatData) -> Void in
                let destinationDoubleData = resultArrayFlatData.bindMemory(to: Double.self).baseAddress
                execute_real_backward(stftChunkDataDoubleData, destinationDoubleData, npy_intp(slicedMatrix.count), npy_intp(slicedMatrix.first?.count ?? 0), fct)
            }
        }
        
        let backSTFT = resultArray.chunked(into: slicedMatrix.first?.count ?? 0)
        
        let backSTFTTransposed = backSTFT.transposed
        
        return backSTFTTransposed
    }
}

extension Array where Element == [Double] {
    
    var rfft: [[(real: Double, imagine: Double)]] {
        let transposed = self.transposed
        let cols = transposed.count
        let rows = transposed.first?.count ?? 1
        let rfftRows = rows/2 + 1
        
        var flatMatrix = transposed.flatMap { $0 }
        let rfftCount = rfftRows*cols
        var resultComplexMatrix = [Double](repeating: 0.0, count: (rfftCount + cols + 1)*2)
                        
        resultComplexMatrix.withUnsafeMutableBytes { destinationData -> Void in
            let destinationDoubleData = destinationData.bindMemory(to: Double.self).baseAddress
            flatMatrix.withUnsafeMutableBytes { (flatData) -> Void in
                let sourceDoubleData = flatData.bindMemory(to: Double.self).baseAddress
                execute_real_forward(sourceDoubleData, destinationDoubleData, npy_intp(Int32(cols)), npy_intp(Int32(rows)), 1)
            }
        }

        var realMatrix = [Double](repeating: 0.0, count: rfftCount)
        var imagineMatrix = [Double](repeating: 0.0, count: rfftCount)

        for index in 0..<rfftCount {
            let real = resultComplexMatrix[index*2]
            let imagine = resultComplexMatrix[index*2+1]
            realMatrix[index] = real
            imagineMatrix[index] = imagine
        }
        
        let resultRealMatrix = realMatrix.chunked(into: rfftRows).transposed
        let resultImagineMatrix = imagineMatrix.chunked(into: rfftRows).transposed

        var result = [[(real: Double, imagine: Double)]]()
        for row in 0..<resultRealMatrix.count {
            let realMatrixRow = resultRealMatrix[row]
            let imagineMatrixRow = resultImagineMatrix[row]
            
            var resultRow = [(real: Double, imagine: Double)]()
            for col in 0..<realMatrixRow.count {
                resultRow.append((real: realMatrixRow[col], imagine: imagineMatrixRow[col]))
            }
            result.append(resultRow)
        }
        
        return result
    }
    
    public func normalizeAudioPowerArray() -> [[Double]] {
        let chunkSize = self.first?.count ?? 0
        let dbValues = self.flatMap { $0 }.normalizeAudioPower().chunked(into: chunkSize)
        return dbValues
    }
}
