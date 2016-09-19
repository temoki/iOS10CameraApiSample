//
//  PixelFormat.swift
//  iOS10CameraApiSample
//
//  Created by temoki on 2016/09/19.
//  Copyright © 2016年 temoki. All rights reserved.
//

import CoreVideo

struct PixelFormat: CustomStringConvertible {
    
    let type: OSType
    let name: String
    var isRaw: Bool?
    
    init(_ type: OSType, _ name: String, _ isRaw: Bool? = nil) {
        self.type = type
        self.name = name
        self.isRaw = isRaw
    }
    
    var description: String {
        return ((isRaw ?? false) ? "[RAW] " : "") + name
    }

    static func pixelFormat(ofType type: OSType) -> PixelFormat {
        if let foundFormat = all.filter({$0.type == type}).first {
            return foundFormat
        }
        return PixelFormat(type, "\(type)")
    }
    
    static let all: [PixelFormat] = [
        PixelFormat(kCVPixelFormatType_1Monochrome, "1Monochrome"),
        PixelFormat(kCVPixelFormatType_2Indexed, "2Indexed"),
        PixelFormat(kCVPixelFormatType_4Indexed, "4Indexed"),
        PixelFormat(kCVPixelFormatType_8Indexed, "8Indexed"),
        PixelFormat(kCVPixelFormatType_1IndexedGray_WhiteIsZero, "1IndexedGray_WhiteIsZero"),
        PixelFormat(kCVPixelFormatType_2IndexedGray_WhiteIsZero, "2IndexedGray_WhiteIsZero"),
        PixelFormat(kCVPixelFormatType_4IndexedGray_WhiteIsZero, "4IndexedGray_WhiteIsZero"),
        PixelFormat(kCVPixelFormatType_8IndexedGray_WhiteIsZero, "8IndexedGray_WhiteIsZero"),
        PixelFormat(kCVPixelFormatType_16BE555, "16BE555"),
        PixelFormat(kCVPixelFormatType_16LE555, "16LE555"),
        PixelFormat(kCVPixelFormatType_16LE5551, "16LE5551"),
        PixelFormat(kCVPixelFormatType_16BE565, "16BE565"),
        PixelFormat(kCVPixelFormatType_16LE565, "16LE565"),
        PixelFormat(kCVPixelFormatType_24RGB, "24RGB"),
        PixelFormat(kCVPixelFormatType_24BGR, "24BGR"),
        PixelFormat(kCVPixelFormatType_32ARGB, "32ARGB"),
        PixelFormat(kCVPixelFormatType_32BGRA, "32BGRA"),
        PixelFormat(kCVPixelFormatType_32ABGR, "32ABGR"),
        PixelFormat(kCVPixelFormatType_32RGBA, "32RGBA"),
        PixelFormat(kCVPixelFormatType_64ARGB, "64ARGB"),
        PixelFormat(kCVPixelFormatType_48RGB, "48RGB"),
        PixelFormat(kCVPixelFormatType_32AlphaGray, "32AlphaGray"),
        PixelFormat(kCVPixelFormatType_16Gray, "16Gray"),
        PixelFormat(kCVPixelFormatType_30RGB, "30RGB"),
        PixelFormat(kCVPixelFormatType_422YpCbCr8, "422YpCbCr8"),
        PixelFormat(kCVPixelFormatType_4444YpCbCrA8, "4444YpCbCrA8"),
        PixelFormat(kCVPixelFormatType_4444YpCbCrA8R, "4444YpCbCrA8R"),
        PixelFormat(kCVPixelFormatType_4444AYpCbCr8, "4444AYpCbCr8"),
        PixelFormat(kCVPixelFormatType_4444AYpCbCr16, "4444AYpCbCr16"),
        PixelFormat(kCVPixelFormatType_444YpCbCr8, "444YpCbCr8"),
        PixelFormat(kCVPixelFormatType_422YpCbCr16, "422YpCbCr16"),
        PixelFormat(kCVPixelFormatType_422YpCbCr10, "422YpCbCr10"),
        PixelFormat(kCVPixelFormatType_444YpCbCr10, "444YpCbCr10"),
        PixelFormat(kCVPixelFormatType_420YpCbCr8Planar, "420YpCbCr8Planar"),
        PixelFormat(kCVPixelFormatType_420YpCbCr8PlanarFullRange, "420YpCbCr8PlanarFullRange"),
        PixelFormat(kCVPixelFormatType_422YpCbCr_4A_8BiPlanar, "422YpCbCr_4A_8BiPlanar"),
        PixelFormat(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange, "420YpCbCr8BiPlanarVideoRange"),
        PixelFormat(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, "420YpCbCr8BiPlanarFullRange"),
        PixelFormat(kCVPixelFormatType_422YpCbCr8_yuvs, "422YpCbCr8_yuvs"),
        PixelFormat(kCVPixelFormatType_422YpCbCr8FullRange, "422YpCbCr8FullRange"),
        PixelFormat(kCVPixelFormatType_OneComponent8, "OneComponent8"),
        PixelFormat(kCVPixelFormatType_TwoComponent8, "TwoComponent8"),
        PixelFormat(kCVPixelFormatType_30RGBLEPackedWideGamut, "30RGBLEPackedWideGamut"),
        PixelFormat(kCVPixelFormatType_OneComponent16Half, "OneComponent16Half"),
        PixelFormat(kCVPixelFormatType_OneComponent32Float, "OneComponent32Float"),
        PixelFormat(kCVPixelFormatType_TwoComponent16Half, "TwoComponent16Half"),
        PixelFormat(kCVPixelFormatType_TwoComponent32Float, "TwoComponent32Float"),
        PixelFormat(kCVPixelFormatType_64RGBAHalf, "64RGBAHalf"),
        PixelFormat(kCVPixelFormatType_128RGBAFloat, "128RGBAFloat"),
        PixelFormat(kCVPixelFormatType_14Bayer_GRBG, "14Bayer_GRBG"),
        PixelFormat(kCVPixelFormatType_14Bayer_RGGB, "14Bayer_RGGB"),
        PixelFormat(kCVPixelFormatType_14Bayer_BGGR, "14Bayer_BGGR"),
        PixelFormat(kCVPixelFormatType_14Bayer_GBRG, "14Bayer_GBRG"),
        ]
    
}
