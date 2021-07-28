//
//  SoundRecognizerEngine.swift
//  SoundRecognizer
//
//  Created by Hrebeniuk Dmytro on 25.06.2020.
//  Copyright © 2020 Hrebeniuk Dmytro. All rights reserved.
//

import Foundation
import CoreML
import RosaKit

public class SoundRecognizerEngine {
    
    private var model: SoundRecognition
    private var samplesCollection: [Double] = []

    let melBasis: [[Double]]
    let sampleRate: Int
    let windowLength: Int

    public init(sampleRate: Int = 22050, windowLength length: Int) {
        self.model = SoundRecognition()
        
        self.sampleRate = sampleRate
        self.melBasis = [Double].createMelFilter(sampleRate: sampleRate, FTTCount: 1024, melsCount: 128)
        self.windowLength = length
    }
    
    private var lstm_1_c_out: MLMultiArray? = nil
    private var lstm_1_h_out: MLMultiArray? = nil
    private var lstm_2_c_out: MLMultiArray? = nil
    private var lstm_2_h_out: MLMultiArray? = nil
    
    public func predict(samples: [Double]) -> (percentage: Double, category: Int, title: String)? {
        var predicatedResult: (Double, Int, String)? = nil
        
        let bunchSize = self.windowLength
        
        let remaidToAddSamples = bunchSize - (self.samplesCollection.count)
        samplesCollection.append(contentsOf: samples[0..<min(remaidToAddSamples, samples.count)])

        if (samplesCollection.count) >= bunchSize {
            let collectionToPredict = samplesCollection
            samplesCollection = [Double]()
            
            let spectrogram = collectionToPredict.stft(nFFT: 1024, hopLength: 512).map { $0.map { pow($0.real, 2.0) + pow($0.imagine, 2.0) } }
            let melSpectrogram = self.melBasis.dot(matrix: spectrogram)
            
            let powerSpectrogram = melSpectrogram.normalizeAudioPowerArray()
            let filteredSpectrogram = powerSpectrogram//.map { $0[0..<161] }

            let mlArray = try? MLMultiArray(shape: [NSNumber(value: 1), NSNumber(value: 128), NSNumber(value: 81)], dataType: MLMultiArrayDataType.double)

            let flatSpectrogram = filteredSpectrogram.flatMap { $0 }
            for index in 0..<flatSpectrogram.count {
                mlArray?[index] = NSNumber(value: flatSpectrogram[index])
            }
            
            do {
                let input  = SoundRecognitionInput(input1: mlArray!)
                let options = MLPredictionOptions()
                options.usesCPUOnly = true
                let result = try model.prediction(input: input, options: options)
                
//                self.lstm_1_c_out = result.lstm_9_c_out
//                self.lstm_1_h_out = result.lstm_9_h_out
//                self.lstm_2_c_out = result.lstm_10_c_out
//                self.lstm_2_h_out = result.lstm_10_h_out
                
                var array = [Double]()
                for index in 0..<result.output1.count {
                    array.append(result.output1[index].doubleValue)
                }

                let maxPercentage = array.reduce(0) { max($0, $1) }

                let category = (array.firstIndex(of: maxPercentage) ?? -1)

                
                let secondPercentage = array.reduce(0) { $1 == maxPercentage ? $0 : max($0, $1) }
                let secondCategory = (array.firstIndex(of: secondPercentage) ?? -1)

                var infoString = ""

                let categoryName = CategoryRepository.indexToCategoryMap[category] ?? "\(category)"
                if category > 0 {
                    let categoryName = categoryName
                    infoString = "Engine Category: \(categoryName)(\(category)) Percentage: \(Int(maxPercentage*100))%, 2nd: \(secondCategory) - \(secondPercentage)"
                  
                    print(infoString)
                }
                
                
                
                predicatedResult = (maxPercentage, category, categoryName)
            }
            catch {
                print("\(error)")
            }
        }
        
        return predicatedResult
        
    }
}
