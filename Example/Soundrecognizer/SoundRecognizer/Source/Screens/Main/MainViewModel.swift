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
import ZIPFoundation

struct ProblemPredition {
    
    let fileName: String
    let predictedCategory: Int
    let targetCategory: Int
    let percentage: Double
    let waveWindow: [Double]

}

extension ProblemPredition: Equatable {
    
    static func == (lhs: ProblemPredition, rhs: ProblemPredition) -> Bool {
        return lhs.fileName == rhs.fileName
        && lhs.predictedCategory == rhs.predictedCategory
        && lhs.targetCategory == rhs.targetCategory
        && lhs.percentage == rhs.percentage
        && lhs.waveWindow == rhs.waveWindow
    }
    
}

extension ProblemPredition: Hashable {
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(fileName)
        hasher.combine(targetCategory)
        hasher.combine(predictedCategory)
        hasher.combine(percentage)
        hasher.combine(waveWindow)
    }

}


enum MainViewModelState {
    
    case initial

    case downloading
    
    case unzip
    
    case processing
    
}

class MainViewModel: ObservableObject {

    @Published var state: MainViewModelState = .initial

    @Published var percentageProceccesed: Double = 0.0
    @Published var percentageValid: Double = 0.0
    @Published var percentageInvalid: Double = 0.0

    @Published var problemPreditions: [ProblemPredition] = []

    private var samplesCollection: [Double] = []
    
    let soundRecognizerEngine = SoundRecognizerEngine(sampleRate: 44100, windowLength: 2048*20)
    
    @Published var showFileExportPicker = false
    @Published var fileExportURL: URL = URL(fileURLWithPath: "/")

    private func downloadDataset(to archiveURL: URL) async throws {
        let urbanSoundDataURL = URL(string: "https://github.com/karoldvl/ESC-50/archive/master.zip")
        return try await withUnsafeThrowingContinuation() { continuation in
            let downloadTask = urbanSoundDataURL.map { URLSession.shared.downloadTask(with: $0) { tempFileURL, _, error in
                if let networkError = error {
                    continuation.resume(throwing: networkError)
                }
                else if let url = tempFileURL {
                    try? FileManager.default.moveItem(at: url, to: archiveURL)
                    continuation.resume()
                }
            }}
            downloadTask?.resume()
        }
    }
    
    func copyWave(toClipboard problemPrediction: ProblemPredition) {
        let content = problemPrediction.waveWindow.description
        if let fileURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("Wave_ \(problemPrediction.targetCategory).json") {
            try? content.write(to: fileURL, atomically: true, encoding: .utf8)
            self.fileExportURL = fileURL
            self.showFileExportPicker = true
        }
    }
    
    func copySTFT(toClipboard problemPrediction: ProblemPredition) {
        let spectrogram = problemPrediction.waveWindow.stft(nFFT: 1024, hopLength: 512).map { $0.map { pow($0.real, 2.0) + pow($0.imagine, 2.0) } }
        let sampleRate = 44100
        let melBasis = [Double].createMelFilter(sampleRate: sampleRate, FTTCount: 1024, melsCount: 128)
        
        let melSpectrogram = melBasis.dot(matrix: spectrogram)
       
        let content = melSpectrogram.description
        if let fileURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("stft_\(problemPrediction.targetCategory).json") {
            try? content.write(to: fileURL, atomically: true, encoding: .utf8)
            self.fileExportURL = fileURL
            self.showFileExportPicker = true
        }
    }
    
    func setup() {
        guard let cachesURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.cachesDirectory, in: .userDomainMask).first else { return }
        let archiveCacheURL = cachesURL.appendingPathComponent("master.zip")
        let datasetURL = cachesURL.appendingPathComponent("ESC-50-master")
        
        self.state = .downloading
        Task {
            if FileManager.default.fileExists(atPath: archiveCacheURL.path) == false {
                try? await downloadDataset(to: archiveCacheURL)
            }
            
            DispatchQueue.main.sync {
                self.state = .unzip
            }
            
            if FileManager.default.fileExists(atPath: datasetURL.path) == false {
                try? FileManager.default.unzipItem(at: archiveCacheURL, to: cachesURL)
            }
            
            DispatchQueue.main.sync {
                self.state = .processing
            }
            
            let metaURL = datasetURL.appendingPathComponent("meta/esc50.csv")
            let content = try? String(contentsOf: metaURL)
            var lines = content?.split(separator: "\n")
            lines?.removeFirst()
            
            let metaData = lines.map { $0.map { $0.split(separator: ",") }.map { (fileName: $0[0], taget:Int($0[2]) ?? 0) } }
            
            let windowLength = 110250

            let soundRecognizerEngine = SoundRecognizerEngine(sampleRate: 44100, windowLength: windowLength)
            let items = metaData ?? []
            for item in items {
                autoreleasepool {
                    let url = datasetURL.appendingPathComponent("audio").appendingPathComponent(String(item.fileName))
                    let soundFile = try? WavFileManager().readWavFile(at: url)
                    let int16Array = soundFile?.data.int16Array.map { Double($0)/32768.0 }
                    
                    let samplesCount = int16Array?.count ?? 0
                    if samplesCount >= windowLength {
                        let window = 0.5
                        let overlap = 0.5
                        let chunk = (Double(samplesCount) * window)
                        let offset = Int(chunk * (1.0 - overlap))
                        
                        let windowsCount = (samplesCount - (windowLength - offset))/offset
                        
                        let targetCategory = item.taget

                        var preditedCategories = [Int]()
                        var preditedCategoriesPercentages = [Double]()
                        for index in 0..<windowsCount {
                            let samples = Array(int16Array?[offset*index..<offset*index + windowLength] ?? [])
                            let result = soundRecognizerEngine.predict(samples: samples)
                            
                            let predictedCategory = result?.category ?? 0
                            
                            preditedCategories.append(predictedCategory)
                            preditedCategoriesPercentages.append(result?.percentage ?? 0.0)
                            
                            if predictedCategory == targetCategory {
                                DispatchQueue.main.sync {
                                    self.percentageValid = self.percentageValid + 1.0/Double(items.count*windowsCount)
                                }
                                    
                            }
                            else {
                                let problemPredition = ProblemPredition(fileName: String(item.fileName), predictedCategory: predictedCategory, targetCategory: targetCategory, percentage: result?.percentage ?? 0.0, waveWindow: samples)
                                print("\(result?.category ?? 0)(\(result?.title ?? "")), target \(targetCategory)(\(CategoryRepository.indexToCategoryMap[targetCategory] ?? "")), \(result?.percentage ?? 0.0)")
                                DispatchQueue.main.sync {
                                    self.problemPreditions.append(problemPredition)
                                    self.percentageInvalid = self.percentageInvalid + 1.0/Double(items.count*windowsCount)
                                }
                            }
                        }
                    }
                    
                    DispatchQueue.main.sync {
                        self.percentageProceccesed = self.percentageProceccesed + 1.0/Double(items.count)
                    }
                }
            }
        }
    }
}
