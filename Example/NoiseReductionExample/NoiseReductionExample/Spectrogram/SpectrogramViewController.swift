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
    
    var fileData: (fileDescriptor: WavFileManager.WAVFileDesriptor, data: Data)? {
        didSet {
            loadData()
        }
    }
    
    private func loadData() {
        spectrograms = [[Double]]()
        
        guard let fileData = self.fileData else {
            return
        }
                
        let soundFile: WavFileManager.WAVFileDesriptor? = fileData.fileDescriptor
        
        let dataCount = fileData.data.count
        let sampleRate = soundFile?.sampleRate ?? 44100
        let bytesPerSample = soundFile?.bytesPerSample ?? 0

        let chunkSize = 2048*20
        let chunksCount = dataCount/(chunkSize*bytesPerSample)

        let rawData = fileData.data.int16Array
        
        for index in 0..<chunksCount {
            let samples = Array(rawData[chunkSize*index..<chunkSize*(index+1)] ).map { Double($0)/Double(Int16.max) }
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
