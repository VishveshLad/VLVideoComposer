//
//  CompositionManager.swift
//  VLVideoCompositionDemo
//


import AVFoundation
import UIKit

class CompositionManager {

    typealias compostionCompletionBlock = (_ composition: AVMutableComposition, _ videoComposition: AVMutableVideoComposition) -> Void
    static let shared = CompositionManager()
    
    // Change Audio Build Composition
    func buildCompositionForChangeAudio(url: URL, audio: URL, canvasSize: CGSize, completion:@escaping compostionCompletionBlock) -> Void {
        
        let avAsset = AVURLAsset(url: url)
        let avAudioAsset = AVURLAsset(url: audio)
        
        let mutableComposition = AVMutableComposition()
        
        // Video Track Setup
        var videoTrack:AVMutableCompositionTrack!
        if avAsset.tracks(withMediaType: .video).count > 0 {
            videoTrack = mutableComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
            do {
                try videoTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: avAsset.duration), of: avAsset.tracks(withMediaType: .video).first!, at: .zero)
            }
            catch {
            }
        }
        
        // Audio Track Setup
        var audioTrack: AVMutableCompositionTrack!
        if avAsset.tracks(withMediaType: .audio).count > 0 {
            audioTrack = mutableComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            do {
                try audioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: avAsset.duration), of: avAudioAsset.tracks(withMediaType: .audio).first!, at: .zero)
            }
            catch {
            }
        }
        
        // Layer Instructions
        var arrLayerInstruction = [AVMutableVideoCompositionLayerInstruction]()
        let layerInstruction = videoCompositionInstructionForTrack(track: videoTrack, asset: avAsset, videoSize: videoTrack.naturalSize, canvasSize: canvasSize, atTime: .zero)
        arrLayerInstruction = [layerInstruction]
        
        // Video Composition Instruction
        let mutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
        mutableVideoCompositionInstruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: videoTrack.asset!.duration)
        mutableVideoCompositionInstruction.layerInstructions = arrLayerInstruction
        
        // Build Final Composition
        let mutableVideoComposition = AVMutableVideoComposition()
        mutableVideoComposition.instructions = [mutableVideoCompositionInstruction]
        mutableVideoComposition.frameDuration = CMTimeMake(value: 1, timescale: 60)
        mutableVideoComposition.renderSize = videoTrack.naturalSize
        
        completion(mutableComposition, mutableVideoComposition)
    }
    
    // Multiple Video Merge Build Composition
    func buildCompositionForMultipleVideoMerge(arrUrls: [URL], canvasSize: CGSize, completion:@escaping compostionCompletionBlock) -> Void {
        var nextTrackTime: CMTime = .zero
        var finalDurationTime : CMTime = .zero
        // Layer Instructions
        var arrLayerInstruction = [AVMutableVideoCompositionLayerInstruction]()
        
        var renderSize : CGSize?
        
        let mutableComposition = AVMutableComposition()
        
        // add one by one video
        for url in arrUrls {
            let avAsset = AVURLAsset(url: url)
    //        let avAudioAsset = AVURLAsset(url: audio)
           
            // Video Track Setup
            var videoTrack:AVMutableCompositionTrack!
            if avAsset.tracks(withMediaType: .video).count > 0 {
                videoTrack = mutableComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
                do {
                    try videoTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: avAsset.duration), of: avAsset.tracks(withMediaType: .video).first!, at: nextTrackTime)
                }
                catch {
                }
            }
            
            // Audio Track Setup
            var audioTrack: AVMutableCompositionTrack!
            if avAsset.tracks(withMediaType: .audio).count > 0 {
                audioTrack = mutableComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
                do {
                    try audioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: avAsset.duration), of: avAsset.tracks(withMediaType: .audio).first!, at: nextTrackTime)
                }
                catch {
                }
            }
            
            // set time for next track
            nextTrackTime = avAsset.duration
            finalDurationTime = finalDurationTime + avAsset.duration
            
            if renderSize == nil {
                renderSize = videoTrack.naturalSize
            }
            
            let layerInstruction = videoCompositionInstructionForTrack(track: videoTrack, asset: avAsset, videoSize: videoTrack.naturalSize, canvasSize: canvasSize, atTime: .zero)
            arrLayerInstruction.append(layerInstruction)
        }
        
        // Video Composition Instruction
        let mutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
        mutableVideoCompositionInstruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: finalDurationTime)
        mutableVideoCompositionInstruction.layerInstructions = arrLayerInstruction
        
        // Build Final Composition
        let mutableVideoComposition = AVMutableVideoComposition()
        mutableVideoComposition.instructions = [mutableVideoCompositionInstruction]
        mutableVideoComposition.frameDuration = CMTimeMake(value: 1, timescale: 60)
        mutableVideoComposition.renderSize = renderSize ?? .zero //videoTrack.naturalSize
        
        completion(mutableComposition, mutableVideoComposition)
    }
    
    // Trim video Build Composition
    func buildCompositionForTrimVideoWithChangeAudio(url: URL, audio: URL? = nil, startTime: Double? = 0.0, durationTime: Double? = 0.0, canvasSize: CGSize, completion:@escaping compostionCompletionBlock) -> Void {
        
        let avAsset = AVURLAsset(url: url)
        var start: CMTime = .zero
        var duration: CMTime = avAsset.duration
        
        if let startTime = startTime, startTime < duration.seconds, startTime >= 0.0 {
            start = CMTime(seconds: startTime, preferredTimescale: avAsset.duration.timescale)
        }
        
        if let durationTime = durationTime, durationTime <= duration.seconds, durationTime > 0.0 {
            let durationData = min((start.seconds + durationTime),avAsset.duration.seconds) - (startTime ?? 0.0)
            duration = CMTime(seconds: durationData, preferredTimescale: avAsset.duration.timescale)
        }
        
        let mutableComposition = AVMutableComposition()
        
        // Video Track Setup
        var videoTrack:AVMutableCompositionTrack!
        if avAsset.tracks(withMediaType: .video).count > 0 {
            videoTrack = mutableComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
            do {
                try videoTrack.insertTimeRange(CMTimeRangeMake(start: start, duration: duration), of: avAsset.tracks(withMediaType: .video).first!, at: .zero)
            }
            catch {
            }
        }
        
        // Audio Track Setup
        var audioTrack: AVMutableCompositionTrack!
        if avAsset.tracks(withMediaType: .audio).count > 0 {
            audioTrack = mutableComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            do {
                if let audioUrl = audio {
                    let avAudioAsset = AVURLAsset(url: audioUrl)
                    try audioTrack.insertTimeRange(CMTimeRange(start: start, duration: duration), of: avAudioAsset.tracks(withMediaType: .audio).first!, at: .zero)
                }else {
                    try audioTrack.insertTimeRange(CMTimeRange(start: start, duration: duration), of: avAsset.tracks(withMediaType: .audio).first!, at: .zero)
                }
            }
            catch {
            }
        }
        
        // Layer Instructions
        var arrLayerInstruction = [AVMutableVideoCompositionLayerInstruction]()
        let layerInstruction = videoCompositionInstructionWithCanvas(videoTrack, asset: avAsset, canvasSize: canvasSize, atTime: .zero)
//        videoCompositionInstructionForTrack(track: videoTrack, asset: avAsset, videoSize: videoTrack.naturalSize, canvasSize: canvasSize, atTime: .zero)
        arrLayerInstruction = [layerInstruction]
        
        // Video Composition Instruction
        let mutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
        mutableVideoCompositionInstruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: videoTrack.asset!.duration)
        mutableVideoCompositionInstruction.layerInstructions = arrLayerInstruction
        
        // Build Final Composition
        let mutableVideoComposition = AVMutableVideoComposition()
        mutableVideoComposition.instructions = [mutableVideoCompositionInstruction]
        mutableVideoComposition.frameDuration = CMTimeMake(value: 1, timescale: 60)
        
        let assetTrack = avAsset.tracks(withMediaType: AVMediaType.video)[0]
        
//        let transform = assetTrack.preferredTransform
//        let assetInfo = orientationFromTransform(transform)
//        let naturalSize = videoTrack.naturalSize
        
        // Wrong Way
//        if assetInfo.isPortrait {
//            let widthRatio = naturalSize.height / canvasSize.height
//            let newWidth = canvasSize.width * widthRatio
//
//            let hightRatio = naturalSize.width / canvasSize.width
//            let newHight = canvasSize.height * hightRatio
//            mutableVideoComposition.renderSize = CGSize(width: newWidth, height: newHight)
//        }else{
//            let widthRatio = naturalSize.width / canvasSize.width
//            let newWidth = canvasSize.width * widthRatio
//
//            let hightRatio = naturalSize.height / canvasSize.height
//            let newHight = canvasSize.height * hightRatio
//            mutableVideoComposition.renderSize = CGSize(width: newWidth, height: newHight)
//        }
        
        mutableVideoComposition.renderSize = canvasSize
        
        
        completion(mutableComposition, mutableVideoComposition)
    }
    
    
    // Video Composition Instruction For Track
    func videoCompositionInstructionForTrack(track: AVCompositionTrack, asset: AVAsset, videoSize:CGSize, canvasSize:CGSize, atTime: CMTime) -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let assetTrack = asset.tracks(withMediaType: AVMediaType.video)[0]
        
        let transform = assetTrack.preferredTransform
        let assetInfo = orientationFromTransform(transform: transform)
        
        var trackSize = canvasSize
        let naturalSize = videoSize
        if assetInfo.isPortrait {
            trackSize = CGSize.init(width: trackSize.height, height: trackSize.width)
        }
        let aspectFillRatio:CGFloat = min(naturalSize.width/trackSize.width,naturalSize.height/trackSize.height)
        
        // Set correct transform.
        if assetInfo.isPortrait {
            var transform = CGAffineTransform.init(scaleX: aspectFillRatio, y: aspectFillRatio)
            transform = transform.translatedBy(x: trackSize.width, y: 0)
            transform = transform.rotated(by: CGFloat(Double.pi / 2))
            transform = transform.translatedBy(x: ((videoSize.height/aspectFillRatio) / 2.0 - trackSize.height/2.0), y: -((videoSize.width/aspectFillRatio) / 2.0 - trackSize.width/2.0))
            instruction.setTransform(transform, at: atTime)
        } else {
            let scaleFactor = CGAffineTransform(scaleX: aspectFillRatio, y: aspectFillRatio)
            
            let posX = naturalSize.width/2 - (assetTrack.naturalSize.width * aspectFillRatio)/2
            let posY = naturalSize.height/2 - (assetTrack.naturalSize.height * aspectFillRatio)/2
            let moveFactor = CGAffineTransform(translationX: posX, y: posY)
            
            let concat = assetTrack.preferredTransform.concatenating(scaleFactor).concatenating(moveFactor)

            instruction.setTransform(concat, at: atTime)
        }
        return instruction
    }
    
    // Manage Orientations From Transfrom
    func orientationFromTransform(transform: CGAffineTransform) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
        var assetOrientation = UIImage.Orientation.up
        var isPortrait = false
        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            assetOrientation = .right
            isPortrait = true
        } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
            assetOrientation = .left
            isPortrait = true
        } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
            assetOrientation = .up
        } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            assetOrientation = .down
        }
        return (assetOrientation, isPortrait)
    }
    
    func videoCompositionInstructionWithCanvas(_ track: AVCompositionTrack, asset: AVAsset, canvasSize: CGSize, atTime: CMTime) -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let assetTrack = asset.tracks(withMediaType: AVMediaType.video)[0]
        
        let transform = assetTrack.preferredTransform
        let assetInfo = orientationFromTransform(transform)
        
//        instruction.setTransform(transform, at: atTime)
//        return instruction
        
        var scaleToFitRatio = canvasSize.width / assetTrack.naturalSize.width
        if assetInfo.isPortrait {
            //MAKE NEW RENDER SIZE (Wrong Way)
//            let y =  ((assetTrack.naturalSize.height / canvasSize.height) * canvasSize.height) / 4
//            instruction.setTransform(transform.concatenating(CGAffineTransform(translationX: 0,y: y)), at: atTime)
//            return instruction
            
            // SET CANVAS SIZE
            scaleToFitRatio = canvasSize.height / assetTrack.naturalSize.width
//            let scaleToFitRatioHeight = (canvasSize.height / assetTrack.naturalSize.height) * canvasSize.height
            
            let aspectWidth = canvasSize.width * (assetTrack.naturalSize.height / canvasSize.height)
            let videoWidth = (canvasSize.height * abs(assetTrack.naturalSize.width)) / abs(assetTrack.naturalSize.height)
            
            let x : CGFloat = canvasSize.width / 4 //(canvasSize.width - (canvasSize.width/2.3))  //(canvasSize.width - videoWidth) / 2
            
            
            //(canvasSize.height - scaleToFitRatioHeight) / 2
            let scaleFactor = CGAffineTransform(scaleX: scaleToFitRatio, y: scaleToFitRatio).concatenating(CGAffineTransform(translationX: 0,y: 0))
//            let scaleFactor = CGAffineTransform(scaleX: scaleToFitRatio, y: scaleToFitRatio) // OLDER CODE
            instruction.setTransform(assetTrack.preferredTransform.concatenating(scaleFactor),at: atTime)
        } else {
            // MAKE NEW RANDER SIZE (Wrong Way)
//            instruction.setTransform(transform.concatenating(CGAffineTransform(translationX: 0.01,y: 0)), at: atTime)
//            return instruction
            
            // SET CANVAS SIZE
            let scaleFactor = CGAffineTransform(scaleX: scaleToFitRatio,y: scaleToFitRatio)
//            let scaleToFitRatioHeight = (((assetTrack.naturalSize.height) - (canvasSize.height)) / 2)
            let y = canvasSize.height / 4 //((canvasSize.height / 2) - scaleToFitRatioHeight) - 20
            var concat = assetTrack.preferredTransform.concatenating(scaleFactor).concatenating(CGAffineTransform(translationX: 0,y: 0))
//            var concat = assetTrack.preferredTransform.concatenating(scaleFactor).concatenating(CGAffineTransform(translationX: 0,y: canvasSize.width / 2)) // OLDER CODE
            if assetInfo.orientation == .down {
                let fixUpsideDown = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
                let windowBounds = canvasSize //UIScreen.main.bounds
                let yFix = assetTrack.naturalSize.height + windowBounds.height
                let centerFix = CGAffineTransform(translationX: assetTrack.naturalSize.width,y: yFix)
                concat = fixUpsideDown.concatenating(centerFix).concatenating(scaleFactor)
            }
            instruction.setTransform(concat, at: atTime)
        }
        
        return instruction
    }
    
    func orientationFromTransform(
      _ transform: CGAffineTransform
    ) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
      var assetOrientation = UIImage.Orientation.up
      var isPortrait = false
      let tfA = transform.a
      let tfB = transform.b
      let tfC = transform.c
      let tfD = transform.d

      if tfA == 0 && tfB == 1.0 && tfC == -1.0 && tfD == 0 {
        assetOrientation = .right
        isPortrait = true
      } else if tfA == 0 && tfB == -1.0 && tfC == 1.0 && tfD == 0 {
        assetOrientation = .left
        isPortrait = true
      } else if tfA == 1.0 && tfB == 0 && tfC == 0 && tfD == 1.0 {
        assetOrientation = .up
      } else if tfA == -1.0 && tfB == 0 && tfC == 0 && tfD == -1.0 {
        assetOrientation = .down
      }
      return (assetOrientation, isPortrait)
    }
}
