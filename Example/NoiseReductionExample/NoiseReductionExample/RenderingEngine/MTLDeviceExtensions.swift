//
//  MTLDeviceExtensions.swift
//  RosaKitExample
//
//  Created by Hrebeniuk Dmytro on 07.01.2020.
//  Copyright © 2020 Dmytro Hrebeniuk. All rights reserved.
//

import Metal
import CoreMedia

extension MTLDevice {
    
    public func createRedTexture(from data: [UInt8], width: Int, height: Int) -> MTLTexture? {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r8Unorm, width: width, height: height, mipmapped: false)

        let texture = self.makeTexture(descriptor: textureDescriptor)

        data.withUnsafeBytes {
            $0.baseAddress.map {
                texture?.replace(region: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0, withBytes: $0, bytesPerRow: width)
            }
        }

        return texture
    }
    
    func createRedTexture(from pixelBuffer: CVPixelBuffer, textureCache: CVMetalTextureCache? = nil) -> MTLTexture? {
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        let format: MTLPixelFormat = .r8Unorm
        
        var cvMetalTexture: CVMetalTexture?
        
        var currentTextureCache: CVMetalTextureCache? = textureCache
        
        if currentTextureCache == nil {
            guard CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, self, nil, &currentTextureCache) == kCVReturnSuccess
                else {
                    return nil
            }
        }
        
        guard let metalTextureCache = currentTextureCache else {
            return nil
        }
        
        let status = CVMetalTextureCacheCreateTextureFromImage(nil,
                                                               metalTextureCache, pixelBuffer, nil, format, width, height, 0, &cvMetalTexture)
        
        var texture: MTLTexture?
        if(status == kCVReturnSuccess) {
            texture = CVMetalTextureGetTexture(cvMetalTexture!)
        }
        
        return texture
    }
    
    func createTexture(from pixelBuffer: CVPixelBuffer, textureCache: CVMetalTextureCache? = nil) -> MTLTexture? {
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        let format: MTLPixelFormat = .bgra8Unorm
        
        var cvMetalTexture: CVMetalTexture?
        
        var currentTextureCache: CVMetalTextureCache? = textureCache
        
        if currentTextureCache == nil {
            guard CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, self, nil, &currentTextureCache) == kCVReturnSuccess
                else {
                    return nil
            }
        }
        
        guard let metalTextureCache = currentTextureCache else {
            return nil
        }
        
        let status = CVMetalTextureCacheCreateTextureFromImage(nil,
                                                               metalTextureCache, pixelBuffer, nil, format, width, height, 0, &cvMetalTexture)
        
        var texture: MTLTexture?
        if(status == kCVReturnSuccess) {
            texture = CVMetalTextureGetTexture(cvMetalTexture!)
        }
        
        return texture
    }
    
}
