//
//  VideoBuilder.swift
//  Paintist
//
//  Created by Yuanbin Cai on 2020/5/14.
//  Copyright © 2020 thinkyeah. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

public struct RenderSettings {

    var size: CGSize
    var fps: Int32 = 12   // frames per second
    var avCodecKey = AVVideoCodecType.h264
    var videoFilename = "render"
    var videoFilenameExt = "mp4"
    
    var outputURL: URL {
        // Use the CachesDirectory so the rendered video file sticks around as long as we need it to.
        // Using the CachesDirectory ensures the file won't be included in a backup of the app.
        let fileManager = FileManager.default
        if let tmpDirURL = try? fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
            return tmpDirURL.appendingPathComponent(videoFilename).appendingPathExtension(videoFilenameExt)
        }
        fatalError("URLForDirectory() failed")
    }
}

public protocol VideoImagesProvider {
    
    func prepare()
    
    var imagesCount: Int { get }
    
    func nextImage(frameIndex: Int) -> UIImage?
    
}

public class SimpleVideoImagesProvider: VideoImagesProvider {
    
    private let images: [UIImage]
    
    init(images: [UIImage]) {
        self.images = images
    }
    
    public var imagesCount: Int {
        images.count
    }
    
    public func prepare() {
        
    }
    
    public func nextImage(frameIndex: Int) -> UIImage? {
        images.count > frameIndex ? images[frameIndex] : nil
    }
}

public class VideoBuilder {

    private static let log = Log(type: VideoBuilder.self)
    
    // Apple suggests a timescale of 600 because it's a multiple of standard video rates 24, 25, 30, 60 fps etc.
    static let TIME_SCALE: Int32 = 600

    private let settings: RenderSettings
    private let videoWriter: VideoWriter
    private let imagesProvider: VideoImagesProvider
    
    private var progressUpdate: ((_ totalFrame: Int, _ currentFrame: Int) -> Void)?
    
    private var frameNum = 0

    private static func saveToLibrary(videoURL: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }

            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
                
            }) { success, error in
                if !success {
                    VideoBuilder.log.e("Could not save video to photo library, error: \(error?.localizedDescription ?? "Unknown")")
                }
            }
        }
    }

    private static func removeFileAtURL(fileURL: URL) {
        do {
            try FileManager.default.removeItem(atPath: fileURL.path)
            
        } catch _ as NSError {
            // Assume file doesn't exist.
        }
    }

    init(renderSettings: RenderSettings, imagesProvider: VideoImagesProvider) {
        settings = renderSettings
        self.imagesProvider = imagesProvider
        videoWriter = VideoWriter(renderSettings: settings)
    }

    func render(progressUpdate: ((_ totalFrame: Int, _ currentFrame: Int) -> Void)? = nil, completion: (() -> Void)?) {
        // The VideoWriter will fail if a file exists at the URL, so clear it out first.
        VideoBuilder.removeFileAtURL(fileURL: settings.outputURL)
        self.progressUpdate = progressUpdate
        
        videoWriter.start()
        videoWriter.render(appendPixelBuffers: appendPixelBuffers) {
            VideoBuilder.saveToLibrary(videoURL: self.settings.outputURL)
            self.progressUpdate = nil
            completion?()
        }
    }

    // This is the callback function for VideoWriter.render()
    fileprivate func appendPixelBuffers(writer: VideoWriter) -> Bool {
        imagesProvider.prepare()
        
        let frameDuration = CMTimeMake(value: Int64(VideoBuilder.TIME_SCALE / settings.fps), timescale: VideoBuilder.TIME_SCALE)
        
        let imagesCount = imagesProvider.imagesCount
        while frameNum < imagesCount {
            if !writer.isReadyForData {
                // Inform writer we have more buffers to write.
                return false
            }

            let goon = autoreleasepool { () -> Bool in
                guard let image = imagesProvider.nextImage(frameIndex: frameNum) else {
                    return false
                }
                
                let presentationTime = CMTimeMultiply(frameDuration, multiplier: Int32(frameNum))
                let success = videoWriter.addImage(image: image, withPresentationTime: presentationTime)
                if !success {
                    fatalError("addImage() failed")
                }

                DispatchQueue.main.async {
                    self.progressUpdate?(imagesCount, self.frameNum)
                }
                frameNum += 1
                
                return true
            }
            
            if !goon {
                break
            }
        }

        // Inform writer all buffers have been written.
        return true
    }
}

private class VideoWriter {

    let renderSettings: RenderSettings

    var videoWriter: AVAssetWriter!
    var videoWriterInput: AVAssetWriterInput!
    var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor!

    var isReadyForData: Bool {
        return videoWriterInput?.isReadyForMoreMediaData ?? false
    }

    static func pixelBufferFromImage(image: UIImage, pixelBufferPool: CVPixelBufferPool, size: CGSize) -> CVPixelBuffer {
        var pixelBufferOut: CVPixelBuffer?

        let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBufferOut)
        if status != kCVReturnSuccess {
            fatalError("CVPixelBufferPoolCreatePixelBuffer() failed")
        }

        let pixelBuffer = pixelBufferOut!

        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

        let data = CVPixelBufferGetBaseAddress(pixelBuffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: data, width: Int(size.width), height: Int(size.height),
                                bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)

        context!.clear(CGRect(x:0,y: 0,width: size.width,height: size.height))

        let horizontalRatio = size.width / image.size.width
        let verticalRatio = size.height / image.size.height
        //aspectRatio = max(horizontalRatio, verticalRatio) // ScaleAspectFill
        let aspectRatio = min(horizontalRatio, verticalRatio) // ScaleAspectFit

        let newSize = CGSize(width: image.size.width * aspectRatio, height: image.size.height * aspectRatio)

        let x = newSize.width < size.width ? (size.width - newSize.width) / 2 : 0
        let y = newSize.height < size.height ? (size.height - newSize.height) / 2 : 0

        context?.draw(image.cgImage!, in: CGRect(x:x,y: y, width: newSize.width, height: newSize.height))
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

        return pixelBuffer
    }

    init(renderSettings: RenderSettings) {
        self.renderSettings = renderSettings
    }

    func start() {
        let avOutputSettings: [String: Any] = [
            AVVideoCodecKey: renderSettings.avCodecKey,
            AVVideoWidthKey: NSNumber(value: Float(renderSettings.size.width)),
            AVVideoHeightKey: NSNumber(value: Float(renderSettings.size.height))
        ]

        func createPixelBufferAdaptor() {
            let sourcePixelBufferAttributesDictionary = [
                kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32ARGB),
                kCVPixelBufferWidthKey as String: NSNumber(value: Float(renderSettings.size.width)),
                kCVPixelBufferHeightKey as String: NSNumber(value: Float(renderSettings.size.height))
            ]
            pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput,
                                                                      sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
        }

        func createAssetWriter(outputURL: URL) -> AVAssetWriter {
            guard let assetWriter = try? AVAssetWriter(outputURL: outputURL, fileType: AVFileType.mp4) else {
                fatalError("AVAssetWriter() failed")
            }

            guard assetWriter.canApply(outputSettings: avOutputSettings, forMediaType: AVMediaType.video) else {
                fatalError("canApplyOutputSettings() failed")
            }

            return assetWriter
        }

        videoWriter = createAssetWriter(outputURL: renderSettings.outputURL)
        videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: avOutputSettings)

        if videoWriter.canAdd(videoWriterInput) {
            videoWriter.add(videoWriterInput)
        
        } else {
            fatalError("canAddInput() returned false")
        }

        // The pixel buffer adaptor must be created before we start writing.
        createPixelBufferAdaptor()

        if videoWriter.startWriting() == false {
            fatalError("startWriting() failed")
        }

        videoWriter.startSession(atSourceTime: CMTime.zero)

        precondition(pixelBufferAdaptor.pixelBufferPool != nil, "nil pixelBufferPool")
    }

    func render(appendPixelBuffers: ((VideoWriter) -> Bool)?, completion: (() -> Void)?) {
        precondition(videoWriter != nil, "Call start() to initialze the writer")

        let queue = DispatchQueue(label: "mediaInputQueue")
        videoWriterInput.requestMediaDataWhenReady(on: queue) {
            let isFinished = appendPixelBuffers?(self) ?? false
            if isFinished {
                self.videoWriterInput.markAsFinished()
                self.videoWriter.finishWriting() {
                    DispatchQueue.main.async {
                        completion?()
                    }
                }
                
            } else {
                // Fall through. The closure will be called again when the writer is ready.
            }
        }
    }

    func addImage(image: UIImage, withPresentationTime presentationTime: CMTime) -> Bool {
        precondition(pixelBufferAdaptor != nil, "Call start() to initialze the writer")

        let pixelBuffer = VideoWriter.pixelBufferFromImage(image: image, pixelBufferPool: pixelBufferAdaptor.pixelBufferPool!, size: renderSettings.size)
        return pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
    }
}
