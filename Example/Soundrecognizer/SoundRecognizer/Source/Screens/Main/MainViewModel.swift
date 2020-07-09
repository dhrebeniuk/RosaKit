//
//  MainViewModel.swift
//  SoundRecognizer
//
//  Created by Hrebeniuk Dmytro on 27.12.2019.
//  Copyright © 2019 Hrebeniuk Dmytro. All rights reserved.
//

import Foundation
import Combine
import CoreML
import RosaKit

class MainViewModel: ObservableObject {
    

    @Published var categoryIndex: Int = 0
    @Published var categoryTitle: String = ""
    @Published var percentage: Int = 0

    var microphoneReader = MicrophoneReader()
    
    private var samplesCollection: [Double] = []
    
    var lstm_1_c_out: MLMultiArray? = nil
    var lstm_1_h_out: MLMultiArray? = nil
    var lstm_2_c_out: MLMultiArray? = nil
    var lstm_2_h_out: MLMultiArray? = nil
    
    let soundRecognizerEngine = SoundRecognizerEngine(sampleRate: 44100)
    
    func setup() {
        
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1

        microphoneReader.startReading { [weak self] samples in
            guard let `self` = self else { return }
            
            operationQueue.waitUntilAllOperationsAreFinished()
            
            operationQueue.addOperation {
                if let result = self.soundRecognizerEngine.predict(samples: samples) {
                    if result.0 > 0.4 {
                        DispatchQueue.main.sync {
                            self.categoryIndex = result.category
                            self.categoryTitle = result.title
                            self.percentage = Int(round(result.percentage*100))
                        }
                    }
                }
            }
        }
    }
}
