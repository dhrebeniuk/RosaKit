//
//  SpectrogramViewController.swift
//  RosaKitExample
//
//  Created by Dmytro Hrebeniuk on 6/09/2020.
//  Copyright © 2020 Dmytro Hrebeniuk. All rights reserved.
//

import Cocoa
import RosaKit
import CoreMedia

class SpectrogramViewController: NSViewController {
     
    @IBOutlet weak var spectrogramView: SpectrogramView!
    @IBOutlet weak var zoomSlider: NSSlider?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        spectrogramView?.elementWidth = CGFloat(zoomSlider?.floatValue ?? 20.0)
        spectrogramView.delegate = self
        
        loadData()
        
        spectrogramView.reloadData()
    }

    private var spectrograms = [[Double]]()
    
    private func loadData() {
        spectrograms = [[Double]]()
        
        let url = Bundle.main.url(forResource: "test", withExtension: "wav")
        
        let soundFile = url.flatMap { try? WavFileManager().readWavFile(at: $0) }
        
        let dataCount = soundFile?.data.count ?? 0
        let sampleRate = soundFile?.sampleRate ?? 44100
        let bytesPerSample = soundFile?.bytesPerSample ?? 0

        let chunkSize = 66000
        let chunksCount = dataCount/(chunkSize*bytesPerSample) - 1

        let rawData = soundFile?.data.int16Array
        
        for index in 0..<chunksCount-1 {
            let samples = Array(rawData?[chunkSize*index..<chunkSize*(index+1)] ?? []).map { Double($0)/32768.0 }            
            let powerSpectrogram = samples.melspectrogram(nFFT: 1024, hopLength: 512, sampleRate: Int(sampleRate), melsCount: 128).map { $0.normalizeAudioPower() }
            spectrograms.append(contentsOf: powerSpectrogram.transposed)
        }

    }
    
    @IBAction func zoomSliderChanged(_ sender: Any) {
        spectrogramView?.elementWidth = CGFloat(zoomSlider?.floatValue ?? 20.0)
        spectrogramView?.reloadData()
    }
}

extension SpectrogramViewController: SpectrogramViewDataSource {

    func elementsCountInSpectrogram(view: SpectrogramView) -> Int {
        return spectrograms.count
    }
    
    func elementsValueInSpectrogram(view: SpectrogramView, at index: Int) -> [Double] {
        if index < spectrograms.count {
            return spectrograms[index]
        }
        else {
            return [Double]()
        }
    }
}
