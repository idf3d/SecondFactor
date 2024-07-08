//
//  QRDetector.swift
//  ykoath
//
//  Created on 14.07.2018.
//  Copyright © 2018 https://github.com/idf3d. All rights reserved.
//

import Foundation
import CoreImage

class QRDetector {
    private class func performDetection(_ image: CIImage) -> String? {

        let context = CIContext(options: nil)
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: nil)

        guard let features = detector?.features(in: image) as? [CIQRCodeFeature] else {
            return nil
        }

        return features.first?.messageString
    }

    class func detect(_ images: [CIImage], completion: @escaping (String?)->Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            for image in images {
                guard let str = performDetection(image) else {
                    continue
                }

                completion(str)
                return
            }

            // if we're here - nothing is detected
            completion(nil)
        }
    }

    class func detect(_ image: CIImage, completion: @escaping (String?)->Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let str = QRDetector.performDetection(image)
            completion(str)
        }
    }

    class func detect(_ url: URL, completion: @escaping (String?)->Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let image = CIImage(contentsOf: url) else {
                completion(nil)
                return
            }

            let str = QRDetector.performDetection(image)
            completion(str)
        }
    }

    class func detectFromScreens(completion handler: @escaping (String?)->Void) {
        var displayCount: UInt32 = 0
        var result = CGGetActiveDisplayList(0, nil, &displayCount)

        guard result == CGError.success else {
            handler(nil)
            return
        }

        let allocated = Int(displayCount)
        let activeDisplays = UnsafeMutablePointer<CGDirectDisplayID>.allocate(capacity: allocated)
        result = CGGetActiveDisplayList(displayCount, activeDisplays, &displayCount)

        guard result == CGError.success else {
            handler(nil)
            return
        }

        var images = [CIImage]()

        for i in 0..<displayCount {
            let display = activeDisplays[Int(i)]
            guard let screenShot = CGDisplayCreateImage(display) else {
                continue
            }

            images.append(CIImage(cgImage: screenShot))
        }

        detect(images, completion: handler)
    }
}
