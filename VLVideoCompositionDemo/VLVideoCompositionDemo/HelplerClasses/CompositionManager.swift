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
        
        if let startTime = startTime, startTime < duration.seconds {
            start = CMTime(seconds: startTime, preferredTimescale: avAsset.duration.timescale)
        }
        
        if let durationTime = durationTime, durationTime <= duration.seconds {
            duration = CMTime(seconds: durationTime, preferredTimescale: avAsset.duration.timescale)
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
}
