# Ban Russia from SWIFT! Protect Ukrainian Sky! Send NATO to Ukraine! #BanRussiafromSwift #CloseTheSky #SendNatoToUkraine 

# RosaKit

RosaKit - LibRosa port to Swift for iOS and macOS platforms.

Library can generate Mel-spectrogram using Short-time Fourier transform (STFT) algorithm.

It's provide methods for calcualte Short-time Fourier transform window and Spectrogram.

## Installation
Via [CocoaPods](http://cocoapods.org):
```ruby
pod 'RosaKit'

```

# Goals

* Generate Spectrogram for visualisations

* Preprocessing steps for most Machine Learning models in Sound Recognition Sphere


# Original Project:

https://librosa.github.io

## melspectrogram:
https://librosa.github.io/librosa/generated/librosa.feature.melspectrogram.html

## Usage in swift

You can use such code:

```swift

let rawAudioData = Data(...)

let chunkSize = 66000
let chunkOfSamples = Array(rawAudioData[0..<chunkSize])    

let powerSpectrogram = samples.melspectrogram(nFFT: 1024, hopLength: 512, sampleRate: Int(sampleRate), melsCount: 128)

```

## Results of processing:
Please look in Examples

![Default Gauge](https://github.com/dhrebeniuk/RosaKit/blob/master/SoundExample.png?raw=true)

## Used in Applications:

## Decibel Meter: 
https://apps.apple.com/app/decibel-meter/id1361845683?mt=12
