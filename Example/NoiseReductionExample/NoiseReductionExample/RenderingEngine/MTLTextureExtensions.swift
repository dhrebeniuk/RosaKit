//
//  MTLTextureExtensions.swift
//  RosaKitExample
//
//  Created by Dmytro Hrebeniuk on 1/25/18.
//  Copyright © 2018 Dmytro Hrebeniuk. All rights reserved.
//

import Foundation
import Metal
import CoreGraphics

private let kColorComponetnsCount = 4

extension MTLTexture {
	
	func toCGImage() -> CGImage? {
		let width = self.width
		let height   = self.height
		let rowBytesCount = self.width * kColorComponetnsCount
		let rawPointer = malloc(width * height * kColorComponetnsCount)

		guard let pointer = rawPointer else {
			return nil
		}
		
		self.getBytes(pointer, bytesPerRow: rowBytesCount, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)

		let selftureSize = self.width * self.height * kColorComponetnsCount
		
		guard let provider = CGDataProvider(dataInfo: nil, data: pointer, size: selftureSize, releaseData: { (_, data, size) in
			data.deallocate()
		}) else {
            return nil
        }
		
		let rawBitmapInfo = CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
		let bitmapInfo = CGBitmapInfo(rawValue: rawBitmapInfo)
		let pColorSpace = CGColorSpaceCreateDeviceRGB()

		let cgImage = CGImage(width: self.width, height: self.height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: rowBytesCount, space: pColorSpace, bitmapInfo: bitmapInfo, provider: provider, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
		
		return cgImage
	}
}
