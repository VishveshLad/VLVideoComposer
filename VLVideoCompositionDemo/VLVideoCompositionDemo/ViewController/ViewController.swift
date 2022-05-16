//
//  ViewController.swift
//  VLVideoCompositionDemo
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    // Outlets
    @IBOutlet weak var viewPlayer: UIView!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var btnPlayPause: UIButton!
    @IBOutlet weak var lblCurrentTime: UILabel!
    @IBOutlet weak var lblRemainingTime: UILabel!
    @IBOutlet weak var viewVideoTimeLine: UIView!
    @IBOutlet weak var cvVideoTimeLine: UICollectionView!
    
    // Variables
    var avPlayer: AVPlayer!
    var isVideoPlaying = false
    var arrVideoUrl: [URL] = []
    var arrAudioUrl: [URL] = []
    var arrTimeLineImages: [UIImage] = []
    var currentIndex = 0
    var videoAlreadyPaused = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.setupView()
        // Build Video Composition from Video File
        guard let sampleVideoFilePath = Bundle.main.path(forResource: "big_buck_bunny", ofType: "mp4") else { return }
        
        guard let sampleAudioFilePath = Bundle.main.path(forResource: "sample_audio", ofType: "mp3") else { return }
        
        guard let sampleFilePexels = Bundle.main.path(forResource: "pexels-arvin-latifi-6466763", ofType: "mp4") else { return }
        
        let urlVideo = URL(fileURLWithPath: sampleVideoFilePath)
        let urlVideoPexels = URL(fileURLWithPath: sampleFilePexels)
        let urlAudio = URL(fileURLWithPath: sampleAudioFilePath)
        self.arrVideoUrl = [urlVideo, urlVideoPexels]
        self.arrAudioUrl = [urlAudio]
        // Setup video timeline
//        self.setupVideoTimeLine(urls: self.arrVideoUrl)
        self.setupVideoTimeLine(urls: [urlVideo])
        
        DispatchQueue.main.async {
            // Change Audio
            /*
            CompositionManager.shared.buildCompositionForChangeAudio(url: urlVideo, audio: urlAudio, canvasSize: self.viewPlayer.frame.size) { composition, videoComposition in
                DispatchQueue.main.async {
                    self.createPlayer(from: composition, videoComposition: videoComposition)
                }
            }
            */
            
            // Merge Video
            /*
            CompositionManager.shared.buildCompositionForMultipleVideoMerge(arrUrls: [urlVideo, urlVideoPexels], canvasSize: self.viewPlayer.frame.size) { composition, videoComposition in
                DispatchQueue.main.async {
                    self.createPlayer(from: composition, videoComposition: videoComposition)
                }
            }
             */
            
            // Trim Vide With Audio Change Option
            CompositionManager.shared.buildCompositionForTrimVideoWithChangeAudio(url: urlVideo, audio: urlAudio, startTime: 3.0, durationTime: 5.0, canvasSize: self.viewVideoTimeLine.frame.size) { composition, videoComposition in
                DispatchQueue.main.async {
                    self.createPlayer(from: composition, videoComposition: videoComposition)
                }
            }
        }
    }

    func setupView() {
        self.cvVideoTimeLine.delegate = self
        self.cvVideoTimeLine.dataSource = self
        self.cvVideoTimeLine.showsHorizontalScrollIndicator = false
        self.cvVideoTimeLine.alwaysBounceHorizontal = false
        self.cvVideoTimeLine.bounces = false
        // set flowlayout
        let flowLayout = UICollectionViewFlowLayout()
        let padding = UIScreen.main.bounds.width / 2
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: padding, bottom: 0, right: padding)
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.itemSize =  CGSize(width: self.cvVideoTimeLine.bounds.height, height: self.cvVideoTimeLine.bounds.height)
        self.cvVideoTimeLine.collectionViewLayout = flowLayout
        self.cvVideoTimeLine.reloadData()
    }
    
    func setupVideoTimeLine(urls: [URL]) {
        for url in urls {
            let asset: AVAsset = AVAsset(url: url)
            
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            let duration = Int(CMTimeGetSeconds(asset.duration))
            
            guard duration > 1 else {
                print("Video length is less than one second.")
                return
            }
            
            for i in 0...duration - 1 {
                do {
                    let thumbnailImage = try imageGenerator.copyCGImage(at: CMTimeMake(value: Int64(i), timescale: 1), actualTime: nil)
                    self.arrTimeLineImages.append(UIImage(cgImage: thumbnailImage))
                } catch let error {
                    print(error)
                }
            }
        }
        print("Total thumbnail images : \(self.arrTimeLineImages.count)")
        self.cvVideoTimeLine.reloadData()
    }
    
    // Create Player From Composition
    func createPlayer(from composition: AVComposition, videoComposition: AVVideoComposition) {
        // Create Player Item
        let playerItem = AVPlayerItem(asset: composition) // Composition
        playerItem.videoComposition = videoComposition // Video Composition
        
        // Initialize Player
        self.avPlayer = AVPlayer(playerItem: playerItem)
        
        if let avPlayerVideoURL = (self.avPlayer.currentItem?.asset as? AVURLAsset)?.url{
            print("composition URL:- \(avPlayerVideoURL)")
        }
        
        // Add Notification observer for video end
        NotificationCenter.default.addObserver(self, selector: #selector(self.videoEnded(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        // Create Player Layer for Display inside any view
        let layer = AVPlayerLayer(player: self.avPlayer)
        layer.frame = CGRect(origin: .zero, size: viewPlayer.frame.size)
        self.viewPlayer.layer.addSublayer(layer)
        
        // Auto Play Player
//        self.avPlayer.play()
        
        // Setup and start timer to display on progress bar
        setupProgressTimer()
        
        // setup time labels
        self.lblRemainingTime.text = self.avPlayer.currentItem?.duration.positionalTime
    }
    
    // Timer for display progress
    
    func setupProgressTimer() {
        self.avPlayer.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(0.02, preferredTimescale: 600), queue: DispatchQueue.main) { [weak self] time in
            if (self?.isVideoPlaying ?? false) {
                let currentSeconds = CMTimeGetSeconds(time)
                guard let duration = self?.avPlayer?.currentItem?.duration else { return }
                let remainingTime = duration - time
                let totalSeconds = CMTimeGetSeconds(duration)
                
                self?.lblCurrentTime.text = time.positionalTime
                self?.lblRemainingTime.text = remainingTime.positionalTime
                
                let progress: Float = Float(currentSeconds/totalSeconds)
                self?.progressBar.progress = progress
                
                let contentSizeWidth = (self?.cvVideoTimeLine?.contentSize.width ?? .zero) - UIScreen.main.bounds.width
                let collectionViewProcess = contentSizeWidth * CGFloat(progress)
    //                print("Collection View Size : \(contentSizeWidth) and process width \(collectionViewProcess) & Progress bar Process : \(progress)")
                
                self?.cvVideoTimeLine.layoutIfNeeded()
                self?.cvVideoTimeLine.setContentOffset(CGPoint(x: collectionViewProcess, y: self?.cvVideoTimeLine.bounds.origin.y ?? .zero), animated: false)
                /*
                if currentSeconds == totalSeconds {
                    self?.avPlayer.seek(to: .zero, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
                    self?.progressBar.progress = 0
                    self?.isVideoPlaying = false
                    self?.btnPlayPause.isSelected = false
                    self?.cvVideoTimeLine.setContentOffset(.zero, animated: true)
                }
                */
            }
        }
    }
    
    @IBAction func btnPlayPressed(_ sender: Any) {
        // Manage Video Play Pause
        self.HandlePlayPauseVideo()
        // OLDER CODE
        // Play Player if
        /*
        if self.avPlayer.rate == 0 {
            self.avPlayer.play()
        }
        */
    }
    
    func HandlePlayPauseVideo() {
        if self.isVideoPlaying {
            self.avPlayer.pause()
        }else{
            self.avPlayer.play()
        }
        self.isVideoPlaying = !self.isVideoPlaying
        self.btnPlayPause.isSelected = self.isVideoPlaying
        self.videoAlreadyPaused = !self.videoAlreadyPaused
    }
    
    func pauseVideo(){
        self.isVideoPlaying = false
        self.avPlayer.pause()
        self.btnPlayPause.isSelected = false
    }
    
    func playVideo() {
        self.isVideoPlaying = true
        self.avPlayer.play()
        self.btnPlayPause.isSelected = true
    }
    
    func updateProgressBar(_ scrollWidth: CGFloat) {
        let contentSizeWidth = (self.cvVideoTimeLine?.contentSize.width ?? .zero) - UIScreen.main.bounds.width
        let contentProgress = scrollWidth / contentSizeWidth
        self.progressBar.progress = Float(contentProgress)
        
        guard let duration = self.avPlayer?.currentItem?.duration else { return }
        let totalSeconds = CMTimeGetSeconds(duration)
        let seekTime = totalSeconds * contentProgress
        
        let time = CMTime(seconds: seekTime, preferredTimescale: 1000000)
        let remainingTime = duration - time
//        print("seekTime: \(CMTimeGetSeconds(time))")
        
        //  update ui
        self.avPlayer.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
        
        self.lblCurrentTime.text = time.positionalTime
        self.lblRemainingTime.text = remainingTime.positionalTime
    }
    
    @objc func videoEnded(_ notification: Notification) {
        print("Video Ended")
        self.avPlayer.seek(to: .zero, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        self.progressBar.progress = 0
        self.isVideoPlaying = false
        self.btnPlayPause.isSelected = false
        self.videoAlreadyPaused = true
        self.cvVideoTimeLine.setContentOffset(.zero, animated: true)
    }
}

// MARK: Collection View Delegate and data source method
extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.arrTimeLineImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoTimeLineCell", for: indexPath) as? VideoTimeLineCell else {
            return UICollectionViewCell()
        }
        cell.contentView.backgroundColor = .lightGray
        cell.imgVideoThumbnailImage.image = self.arrTimeLineImages[indexPath.item]
        cell.lblVideoThumbnailIndex.text = "\(indexPath.item + 1)"
        return cell
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        print("Scroll offSet:- \(scrollView.contentOffset.x)")
        if self.isVideoPlaying == false {
            self.updateProgressBar(scrollView.contentOffset.x)
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
//        print("Scroll End Dragging")
        if self.videoAlreadyPaused == false {
            self.playVideo()
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
//        print("Scroll BeginDragging")
        self.pauseVideo()
    }
}
// MARK: CMTime Extestion
extension CMTime {
    var roundedSeconds: TimeInterval {
        return seconds.rounded(.down)
    }
    var hours:  Int { return Int(roundedSeconds / 3600) }
    var minute: Int { return Int(roundedSeconds.truncatingRemainder(dividingBy: 3600) / 60) }
    var second: Int { return Int(roundedSeconds.truncatingRemainder(dividingBy: 60)) }
    var positionalTime: String {
        return hours > 0 ?
            String(format: "%d:%02d:%02d",
                   hours, minute, second) :
            String(format: "%02d:%02d",
                   minute, second)
    }
}

// MARK: Collection View Cell
class VideoTimeLineCell: UICollectionViewCell {
    @IBOutlet weak var imgVideoThumbnailImage: UIImageView!
    @IBOutlet weak var lblVideoThumbnailIndex: UILabel!
}

