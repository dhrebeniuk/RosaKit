//
//  NoiseReductionExample.swift
//  RosaKitExample
//
//  Created by Hrebeniuk Dmytro on 09.06.2020.
//  Copyright © 2020 Hrebeniuk Dmytro. All rights reserved.
//

import Cocoa
import RosaKit
import CoreML

class MainViewController: NSSplitViewController {

    var sourceSpectrogramViewController: SpectrogramViewController?
    var resultSpectrogramViewController: SpectrogramViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

        let configuration = MLModelConfiguration()
        let soundNoiseReduction = try? SoundNoiseReduction(configuration: configuration)
        
        self.sourceSpectrogramViewController = children.first as? SpectrogramViewController
        self.resultSpectrogramViewController = children.last as? SpectrogramViewController
        
        let url = Bundle.main.url(forResource: "test", withExtension: "wav")
        let soundFile: WavFileManager.WAVFileDesriptor? = url.flatMap { try? WavFileManager().readWavFile(at: $0) }
        sourceSpectrogramViewController?.fileData =  (fileDescriptor: soundFile!, data: soundFile!.data)

        let dataCount = soundFile?.data.count ?? 0
        let bytesPerSample = soundFile?.bytesPerSample ?? 0

        let chunkSize = 2048*20
        let chunksCount = dataCount/(chunkSize*bytesPerSample)

        let rawData = soundFile?.data.int16Array
        
        var newDoubleRawData = [Double]()
        
        for index in 0..<chunksCount {
            let samples = Array(rawData?[chunkSize*index..<chunkSize*(index+1)] ?? [])
            let floatSamples = samples.map { Double($0)/Double(Int16.max) }
            
            let stftData = floatSamples.stft(nFFT: 1024, hopLength: 512)
                        
            var stftDataReal = stftData.flatMap { $0.compactMap { Float32($0.real) }  }
            let mlRealArray = stftDataReal.withUnsafeMutableBytes {
                $0.baseAddress.flatMap {
                    try? MLMultiArray(dataPointer: $0, shape: [1, 1, 513, 81], dataType: MLMultiArrayDataType.float32, strides: [(513 - 1)*81, (513 - 1)*81, 81, 1] as [NSNumber], deallocator: nil)
                }
            }
            
            var stftDataImagine = stftData.flatMap { $0.compactMap { Float32($0.imagine) }  }
            let mlImagineArray = stftDataReal.withUnsafeMutableBytes {
                $0.baseAddress.flatMap {
                    try? MLMultiArray(dataPointer: $0, shape: [1, 1, 513, 81], dataType: MLMultiArrayDataType.float32, strides: [(513 - 1)*81, (513 - 1)*81, 81, 1] as [NSNumber], deallocator: nil)
                }
            }
                        
            let soundNoiseReductionInput = SoundNoiseReductionInput.init(input_real: mlRealArray!, input_imagine: mlImagineArray!)
            let output = try? soundNoiseReduction?.prediction(input: soundNoiseReductionInput)
            
            var result = [[(real: Double, imagine: Double)]]()
            for row in 0..<stftData.count {
                var resultRow = [(real: Double, imagine: Double)]()
                for col in 0..<stftData[row].count {
                    let real = output?.var_697[row*stftData[row].count + col].doubleValue ?? 0.0
                    let imagine =  output?.var_798[row*stftData[row].count + col].doubleValue ?? 0.0
                    resultRow.append((real: real, imagine: imagine))
                }
                result.append(resultRow)
            }
            var istftData = result.istft(hopLength: 512).map { $0 }[0..<chunkSize]

            let skipDataLength = 128
            istftData[0...skipDataLength] = floatSamples[0...skipDataLength]
            istftData[istftData.count-skipDataLength...istftData.count-1] = floatSamples[istftData.count-skipDataLength...istftData.count-1]

            newDoubleRawData.append(contentsOf: istftData)
        }
        
        let newRawData = newDoubleRawData
            .map { Int16(max(min(($0*32768.0), Double(Int16.max)), Double(Int16.min))) }
        
        let newData = newRawData.withUnsafeBufferPointer {Data(buffer: $0)}
        resultSpectrogramViewController?.fileData = (fileDescriptor: soundFile!, data: newData)

        
        let newURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("result_wav").appendingPathExtension("wav")
        
        try? WavFileManager().createWavFile(using: newData, atURL: newURL!, sampleRate: 44100)
        print("resultURL: \(String(describing: newURL))")
    }
    
}

