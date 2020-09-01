//
//  WavFileManager.swift
//  RosaKit
//
//  Created by Hrebeniuk Dmytro on 10.12.2019.
//  Copyright © 2019 Dmytro Hrebeniuk. All rights reserved.
//

import Foundation

public class WavFileManager {

    public struct WAVFileDesriptor {
        public let sampleRate: Int
        public let bytesPerSample: Int
        public let sampleSize: Int
        public let channels: Int

        public let data: Data
    }
    
    public enum ReadError: Error {
        case fail
        case nonPCM
        case supportOneChannel
        case supportOnly16bitChannel
        case nonSupportedSampleRate
    }
    
    public init() {
        
    }
    
    public func readWavFile(at url: URL) throws -> WAVFileDesriptor {
        let data = try Data(contentsOf: url)
        
        let dataSize = Int(data.count)
                
        return try data.withUnsafeBytes { rawPointer -> WAVFileDesriptor in
            let bytes = rawPointer.bindMemory(to: UInt8.self)

            let RIFFData = rawPointer.baseAddress.map { Data(bytes: $0, count: 4) }
            
            let RIFFLabel = RIFFData.map { String(data: $0, encoding: .utf8) }
            
            guard RIFFLabel == "RIFF" else {
                throw ReadError.fail
            }
            
            let chunkSize = rawPointer.load(fromByteOffset: 4, as: UInt32.self) - 36
                        
            let WAVELabel = String(bytes: bytes[8..<12], encoding: .utf8)
            guard WAVELabel == "WAVE" else {
                throw ReadError.fail
            }
            
            let fmtLabel = String(bytes: bytes[12..<16], encoding: .utf8)
            guard fmtLabel == "fmt " else {
                throw ReadError.fail
            }
            
            _ = rawPointer.load(fromByteOffset: 16, as: Int32.self)
            
            let format = rawPointer.load(fromByteOffset: 20, as: Int16.self)
            guard format == 1 else {
                throw ReadError.nonPCM
            }
            
            let channels = rawPointer.load(fromByteOffset: 22, as: Int16.self)
            
            let sampleRate = rawPointer.load(fromByteOffset: 24, as: Int32.self)
            let byteRate = rawPointer.load(fromByteOffset: 28, as: Int32.self)

            guard byteRate/sampleRate == 2 || byteRate/sampleRate == 4 else {
                throw ReadError.supportOnly16bitChannel
            }
            
            var sampleSize: Int = 0
            
            if sampleRate == 22050 {
                sampleSize = 256
            }
            else if sampleRate == 44100 {
                sampleSize = 512
            }
            else if sampleRate == 48000 {
                sampleSize = 960
            }
            else {
                throw ReadError.nonSupportedSampleRate
            }
            
            _ = rawPointer.load(fromByteOffset: 30, as: Int16.self)
            let bytesPerSample = rawPointer.load(fromByteOffset: 32, as: Int16.self)

            let dataLabel = String(bytes: bytes[36..<40], encoding: .utf8)
            guard dataLabel == "data" else {
                throw ReadError.fail
            }
                        
            let data = Data(bytes[44..<(44 + Int(min(chunkSize, UInt32(dataSize-44))))])
            
            return WAVFileDesriptor(sampleRate: Int(sampleRate), bytesPerSample: Int(bytesPerSample), sampleSize: Int(sampleSize), channels: Int(channels), data: data)
        }
        
    }
    
    public func createWavFile(using rawData: Data, atURL url: URL, sampleRate: Int, channels: Int = 1) throws {
        //Prepare Wav file header
        let waveHeaderFormate = createWaveHeader(data: rawData, sampleRate: sampleRate, channels: channels) as Data

        //Prepare Final Wav File Data
        let waveFileData = waveHeaderFormate + rawData

        //Store Wav file in document directory.
        try storeMusicFile(data: waveFileData, atURL: url)
    }

    private func createWaveHeader(data: Data, sampleRate: Int, channels channelsCount: Int = 1) -> NSData {
        let sampleRate: Int32 = Int32(sampleRate)
        let chunkSize: Int32 = 36 + Int32(data.count)
        let subChunkSize: Int32 = 16
        let format: Int16 = 1
        let channels: Int16 = Int16(channelsCount)
        let bytesPerSample: Int16 = 16
        let byteRate: Int32 = sampleRate * Int32(channels * bytesPerSample / 8)
        let blockAlign: Int16 = channels * bytesPerSample / 8
        let dataSize: Int32 = Int32(data.count)

        let header = NSMutableData()
        
        header.append([UInt8]("RIFF".utf8), length: 4)
        header.append(intToByteArray(chunkSize), length: 4)

        //WAVE
        header.append([UInt8]("WAVE".utf8), length: 4)

        //FMT
        header.append([UInt8]("fmt ".utf8), length: 4)

        header.append(intToByteArray(subChunkSize), length: 4)
        header.append(shortToByteArray(format), length: 2)
        header.append(shortToByteArray(channels), length: 2)
        header.append(intToByteArray(sampleRate), length: 4)
        header.append(intToByteArray(byteRate), length: 4)
        header.append(shortToByteArray(blockAlign), length: 2)
        header.append(shortToByteArray(bytesPerSample), length: 2)

        header.append([UInt8]("data".utf8), length: 4)
        header.append(intToByteArray(dataSize), length: 4)

        return header
    }

    private func intToByteArray(_ integer: Int32) -> [UInt8] {
        return [
             //little endian
            UInt8(truncatingIfNeeded: (integer) & 0xff),
            UInt8(truncatingIfNeeded: (integer >>  8) & 0xff),
            UInt8(truncatingIfNeeded: (integer >> 16) & 0xff),
            UInt8(truncatingIfNeeded: (integer >> 24) & 0xff)
        ]
      }

      private func shortToByteArray(_ integer: Int16) -> [UInt8] {
         return [
             //little endian
             UInt8(truncatingIfNeeded: (integer) & 0xff),
             UInt8(truncatingIfNeeded: (integer >>  8) & 0xff)
         ]
       }

        func storeMusicFile(data: Data, atURL url: URL) throws {
            try data.write(to: url)
       }
}
