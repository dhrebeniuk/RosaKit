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
    
    public init(sampleRate: Int = 22050) {
        self.model = SoundRecognition()
        
        self.sampleRate = sampleRate
        self.melBasis = [Double].createMelFilter(sampleRate: sampleRate, FTTCount: 1024, melsCount: 128)
    }
    
    private var lstm_1_c_out: MLMultiArray? = nil
    private var lstm_1_h_out: MLMultiArray? = nil
    private var lstm_2_c_out: MLMultiArray? = nil
    private var lstm_2_h_out: MLMultiArray? = nil
    
    public func predict(samples: [Double]) -> (percentage: Double, category: Int, title: String)? {
        var predicatedResult: (Double, Int, String)? = nil
        
        let bunchSize = 2048*30
        
        let remaidToAddSamples = bunchSize - (self.samplesCollection.count)
        samplesCollection.append(contentsOf: samples[0..<min(remaidToAddSamples, samples.count)])

        if (samplesCollection.count) >= bunchSize {
            let collectionToPredict = samplesCollection
            samplesCollection = [Double]()
            
            let spectrogram = collectionToPredict.stft(nFFT: 1024, hopLength: 512).map { $0.map { pow($0, 2.0) } }
            let melSpectrogram = self.melBasis.dot(matrix: spectrogram)
            
            let powerSpectrogram = melSpectrogram.normalizeAudioPowerArray()
            let filteredSpectrogram = powerSpectrogram//.map { $0[0..<161] }

            let mlArray = try? MLMultiArray(shape: [NSNumber(value: 1), NSNumber(value: 128), NSNumber(value: 121)], dataType: MLMultiArrayDataType.double)

            let flatSpectrogram = filteredSpectrogram.flatMap { $0 }
            for index in 0..<flatSpectrogram.count {
                mlArray?[index] = NSNumber(value: flatSpectrogram[index])
            }
            
            do {
                let input  = SoundRecognitionInput(input1: mlArray!, lstm_1_h_in: self.lstm_1_h_out, lstm_1_c_in: self.lstm_1_c_out, lstm_2_h_in: self.lstm_2_h_out, lstm_2_c_in: self.lstm_2_c_out)
                let options = MLPredictionOptions()
                options.usesCPUOnly = true
                let result = try model.prediction(input: input, options: options)
                
//                self.lstm_1_c_out = result.lstm_1_c_out
//                self.lstm_1_h_out = result.lstm_1_h_out
//                self.lstm_2_c_out = result.lstm_2_c_out
//                self.lstm_2_h_out = result.lstm_2_h_out

                var array = [Double]()
                for index in 0..<result.output1.count {
                    array.append(result.output1[index].doubleValue)
                }

                let maxPercentage = array.reduce(0) { max($0, $1) }

                let category = (array.firstIndex(of: maxPercentage) ?? -1)

                var infoString = ""

                let categoryName = CategoryRepository.indexToCategoryMap[category] ?? "\(category)"
                if category > 0 {
                    let categoryName = categoryName
                    infoString = "Engine Category: \(categoryName)(\(category)) Percentage: \(Int(maxPercentage*100))%"
                  
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
