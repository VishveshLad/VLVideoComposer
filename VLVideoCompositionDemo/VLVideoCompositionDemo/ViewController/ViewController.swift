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
    @IBOutlet weak var viewScrollViewContent: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var storyBoardTrimmerView: TrimmerView!
    
    // THIRD PARTY
    private let viewTrimmer = TrimmerView()
    
    // TRIMMER VIEW
    private let trimView = UIView()
    private let leftHandleView = UIView()
    private let rightHandleView = UIView()
    private let leftHandleKnob = UIView()
    private let rightHandleKnob = UIView()
    private let leftMaskView = UIView()
    private let rightMaskView = UIView()
    let handleWidth: CGFloat = 15
    var cureentAVAsset: AVAsset?
    var minDuration = 1
    
    
    // MARK: Constraints
    private var currentLeftConstraint: CGFloat = 0
    private var currentRightConstraint: CGFloat = 0
    private var leftConstraint: NSLayoutConstraint?
    private var rightConstraint: NSLayoutConstraint?
    private var positionConstraint: NSLayoutConstraint?
    
    private var firstCellLeadingAnchor: NSLayoutXAxisAnchor?
    private var lastCellTrailingAnchor: NSLayoutXAxisAnchor?
    
    // Variables
    var avPlayer: AVPlayer!
    var isVideoPlaying = false
    var arrVideoUrl: [URL] = []
    var arrAudioUrl: [URL] = []
    var arrTimeLineImages: [UIImage] = []
    var currentIndex = 0
    var videoAlreadyPaused = true
    
    //Trimmed video
    var startTime: Double = 0.0
    var durationTime: Double = 0.0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.setupView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.buildVideoComposition()
    }
    
    func setupTimline() {
        self.setupTrimmerView()
    }
    
    // Build Video Composition
    func buildVideoComposition() {
        // Build Video Composition from Video File
        guard let sampleVideoFilePath = Bundle.main.path(forResource: "big_buck_bunny", ofType: "mp4") else { return }
        
        guard let sampleAudioFilePath = Bundle.main.path(forResource: "sample_audio", ofType: "mp3") else { return }
        
        //        guard let sampleFilePexels = Bundle.main.path(forResource: "640", ofType: "mp4") else { return }
        guard let sampleFilePexels = Bundle.main.path(forResource: "IMG_3946", ofType: "MOV") else { return }
        
        let urlVideo = URL(fileURLWithPath: sampleVideoFilePath)
        let urlVideoPexels = URL(fileURLWithPath: sampleFilePexels)
        let urlAudio = URL(fileURLWithPath: sampleAudioFilePath)
        
        
        self.storyBoardTrimmerView.asset = AVAsset(url: urlVideo)
        self.storyBoardTrimmerView.delegate = self
        
        self.arrVideoUrl = [urlVideo, urlVideoPexels]
        self.arrAudioUrl = [urlAudio]
        // Setup video timeline
        //        self.setupVideoTimeLine(urls: self.arrVideoUrl)
        //        self.setupVideoTimeLine(urls: [urlVideo])
        
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
            
            self.startTime = 10.0
            self.durationTime = 2.0
            self.setupVideoTimeLine(url: urlVideoPexels, startTime: self.startTime, durationTime: self.durationTime)
            // Trim Vide With Audio Change Option
            CompositionManager.shared.buildCompositionForTrimVideoWithChangeAudio(url: urlVideoPexels, audio: urlAudio, startTime: self.startTime, durationTime: self.durationTime, canvasSize: self.viewPlayer.frame.size) { composition, videoComposition in
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
    
    func setupVideoTimeLine(url: URL, startTime: Double? = 0.0, durationTime: Double? = 0.0) {
        let avAsset: AVAsset = AVAsset(url: url)
        self.cureentAVAsset = avAsset
        let track = avAsset.tracks(withMediaType: AVMediaType.video)[0]
        print("time line:- \(track.naturalSize)")
        
        let imageGenerator = AVAssetImageGenerator(asset: avAsset)
        imageGenerator.appliesPreferredTrackTransform = true
        let duration = Int(CMTimeGetSeconds(avAsset.duration))
        var start: CMTime = .zero
        var durationData: CMTime = avAsset.duration
        
        if let startTime = startTime, startTime < avAsset.duration.seconds, startTime >= 0.0 {
            start = CMTime(seconds: startTime, preferredTimescale: avAsset.duration.timescale)
        }
        
        if let durationTime = durationTime, durationTime <= avAsset.duration.seconds, durationTime > 0.0 {
            durationData = CMTime(seconds:  min((start.seconds + durationTime),avAsset.duration.seconds), preferredTimescale: avAsset.duration.timescale)
        }
        
        guard duration > 1 else {
            print("Video length is less than one second.")
            return
        }
        
        for i in Int(CMTimeGetSeconds(start))...(Int(CMTimeGetSeconds(durationData)) - 1) {
            do {
                let thumbnailImage = try imageGenerator.copyCGImage(at: CMTimeMake(value: Int64(i), timescale: 1), actualTime: nil)
                self.arrTimeLineImages.append(UIImage(cgImage: thumbnailImage))
            } catch let error {
                print(error)
            }
        }
        print("Total thumbnail images : \(self.arrTimeLineImages.count)")
        self.cvVideoTimeLine.reloadData()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.setupTimline()
//            self.addTrimmerView()
        }
    }
    
    // Create Player From Composition
    func createPlayer(from composition: AVComposition, videoComposition: AVVideoComposition) {
        // Create Player Item
        let playerItem = AVPlayerItem(asset: composition) // Composition
        playerItem.videoComposition = videoComposition // Video Composition
        
        // Initialize Player
        self.avPlayer = AVPlayer(playerItem: playerItem)
        
        // Add Notification observer for video end
        NotificationCenter.default.addObserver(self, selector: #selector(self.videoEnded(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        // Create Player Layer for Display inside any view
        let layer = AVPlayerLayer(player: self.avPlayer)
        layer.backgroundColor = UIColor.red.cgColor
        layer.frame = self.viewPlayer.bounds //CGRect(x: 0, y: 0, width: videoComposition.renderSize.width, height: videoComposition.renderSize.height)
        self.viewPlayer.layer.addSublayer(layer)
        layer.videoGravity = .resizeAspect
        
        
        let track = playerItem.asset.tracks(withMediaType: AVMediaType.video)[0]
        //        Asset.tracks(withMediaType: AVMediaType.video)[0]
        print("time video loaded line:- \(track.naturalSize)")
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
    
    private var minimumDistanceBetweenHandle: CGFloat {
        guard let asset = self.cureentAVAsset else { return 0 }
        return CGFloat(minDuration) * (self.cvVideoTimeLine.contentSize.width - UIScreen.main.bounds.width) / CGFloat(asset.duration.seconds)
//        return  20 //CGFloat(minDuration) * assetPreview.contentView.frame.width / CGFloat(asset.duration.seconds)
    }
    
    
    private func addTrimmerView() {
        
        guard let sampleVideoFilePath = Bundle.main.path(forResource: "big_buck_bunny", ofType: "mp4") else { return }
        
        let urlVideo = URL(fileURLWithPath: sampleVideoFilePath)
        self.viewTrimmer.asset = AVAsset(url: urlVideo)
        self.viewTrimmer.delegate = self
        self.viewTrimmer.translatesAutoresizingMaskIntoConstraints = false
        self.viewScrollViewContent.addSubview(viewTrimmer)
        
        self.firstCellLeadingAnchor = self.cvVideoTimeLine.cellForItem(at: IndexPath(item: 0, section: 0))?.leadingAnchor

//        self.scrollView.isHidden = true
//        self.cvVideoTimeLine.scrollToItem(at: IndexPath(item: self.arrTimeLineImages.count - 1, section: 0), at: .right, animated: false)
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//            self.lastCellTrailingAnchor = self.cvVideoTimeLine.cellForItem(at: IndexPath(item: self.cvVideoTimeLine.numberOfItems(inSection: 0) - 1 , section: 0))?.trailingAnchor
//            self.rightConstraint = self.viewTrimmer.trailingAnchor.constraint(equalTo: self.lastCellTrailingAnchor ?? self.cvVideoTimeLine.trailingAnchor)
//            self.rightConstraint?.isActive = true
//            self.cvVideoTimeLine.contentOffset = .zero
//            DispatchQueue.main.asyncAfter(deadline: .now()) {
//                self.scrollView.isHidden = false
//            }
//        }

        self.viewTrimmer.topAnchor.constraint(equalTo: self.viewVideoTimeLine.topAnchor).isActive = true
        self.viewTrimmer.bottomAnchor.constraint(equalTo: self.viewVideoTimeLine.bottomAnchor).isActive = true
        self.viewTrimmer.widthAnchor.constraint(equalToConstant: 100).isActive = true
//        self.viewTrimmer.widthAnchor.constraint(equalTo: self.viewVideoTimeLine.widthAnchor).isActive = true
        self.leftConstraint = viewTrimmer.leadingAnchor.constraint(equalTo: firstCellLeadingAnchor ?? self.viewVideoTimeLine.leadingAnchor)
//        self.rightConstraint = self.viewTrimmer.trailingAnchor.constraint(equalTo: self.lastCellTrailingAnchor ?? self.viewVideoTimeLine.trailingAnchor)
        
    }
    
    
    private func setupTrimmerView() {
        trimView.layer.borderWidth = 0.0
        trimView.layer.cornerRadius = 2.0
        trimView.translatesAutoresizingMaskIntoConstraints = false
        trimView.isUserInteractionEnabled = false
        self.viewScrollViewContent.addSubview(trimView)
        
        self.firstCellLeadingAnchor = self.cvVideoTimeLine.cellForItem(at: IndexPath(item: 0, section: 0))?.leadingAnchor
        
        self.scrollView.isHidden = true
        self.cvVideoTimeLine.scrollToItem(at: IndexPath(item: self.arrTimeLineImages.count - 1, section: 0), at: .right, animated: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.lastCellTrailingAnchor = self.cvVideoTimeLine.cellForItem(at: IndexPath(item: self.cvVideoTimeLine.numberOfItems(inSection: 0) - 1 , section: 0))?.trailingAnchor
            self.rightConstraint = self.trimView.trailingAnchor.constraint(equalTo: self.lastCellTrailingAnchor ?? self.cvVideoTimeLine.trailingAnchor)
            self.rightConstraint?.isActive = true
            self.setupHandleView()
            self.setupMaskView()
            self.setupGestures()
            self.cvVideoTimeLine.contentOffset = .zero
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                self.scrollView.isHidden = false
            }
        }
        
//        self.lastCellTrailingAnchor = self.cvVideoTimeLine.cellForItem(at: IndexPath(item: self.cvVideoTimeLine.numberOfItems(inSection: 0) - 1 , section: 0))?.trailingAnchor
        
        trimView.topAnchor.constraint(equalTo: self.viewVideoTimeLine.topAnchor).isActive = true
        trimView.bottomAnchor.constraint(equalTo: self.viewVideoTimeLine.bottomAnchor).isActive = true
        leftConstraint = trimView.leadingAnchor.constraint(equalTo: firstCellLeadingAnchor ?? self.cvVideoTimeLine.leadingAnchor)
//        constraint(equalTo: self.cvVideoTimeLine.contentOffset.x, constant: 50)
//        rightConstraint = trimView.trailingAnchor.constraint(equalTo:lastCellTrailingAnchor ?? self.cvVideoTimeLine.trailingAnchor)
//        constraint(equalTo: self.cvVideoTimeLine.rightAnchor, constant: -50)
        leftConstraint?.isActive = true
//        rightConstraint?.isActive = true
    }
    
    private func setupHandleView() {
        
        leftHandleView.isUserInteractionEnabled = true
        leftHandleView.layer.cornerRadius = 2.0
        leftHandleView.backgroundColor = .red
        leftHandleView.translatesAutoresizingMaskIntoConstraints = false
        self.viewScrollViewContent.addSubview(leftHandleView)
        
        leftHandleView.heightAnchor.constraint(equalTo: self.viewVideoTimeLine.heightAnchor).isActive = true
        leftHandleView.widthAnchor.constraint(equalToConstant: handleWidth).isActive = true
        leftHandleView.leftAnchor.constraint(equalTo: trimView.leftAnchor).isActive = true
        leftHandleView.centerYAnchor.constraint(equalTo: self.viewVideoTimeLine.centerYAnchor).isActive = true
        
        leftHandleKnob.translatesAutoresizingMaskIntoConstraints = false
        leftHandleView.addSubview(leftHandleKnob)
        
        leftHandleKnob.heightAnchor.constraint(equalTo: self.viewVideoTimeLine.heightAnchor, multiplier: 0.5).isActive = true
        leftHandleKnob.widthAnchor.constraint(equalToConstant: 2).isActive = true
        leftHandleKnob.centerYAnchor.constraint(equalTo: leftHandleView.centerYAnchor).isActive = true
        leftHandleKnob.centerXAnchor.constraint(equalTo: leftHandleView.centerXAnchor).isActive = true
        
        rightHandleView.isUserInteractionEnabled = true
        rightHandleView.layer.cornerRadius = 2.0
        rightHandleView.backgroundColor = .red
        rightHandleView.translatesAutoresizingMaskIntoConstraints = false
        self.viewScrollViewContent.addSubview(rightHandleView)
        
        rightHandleView.heightAnchor.constraint(equalTo: self.viewVideoTimeLine.heightAnchor).isActive = true
        rightHandleView.widthAnchor.constraint(equalToConstant: handleWidth).isActive = true
        rightHandleView.rightAnchor.constraint(equalTo: trimView.rightAnchor).isActive = true
        rightHandleView.centerYAnchor.constraint(equalTo: self.viewVideoTimeLine.centerYAnchor).isActive = true
        
        rightHandleKnob.translatesAutoresizingMaskIntoConstraints = false
        rightHandleView.addSubview(rightHandleKnob)
        
        rightHandleKnob.heightAnchor.constraint(equalTo: self.viewVideoTimeLine.heightAnchor, multiplier: 0.5).isActive = true
        rightHandleKnob.widthAnchor.constraint(equalToConstant: 2).isActive = true
        rightHandleKnob.centerYAnchor.constraint(equalTo: rightHandleView.centerYAnchor).isActive = true
        rightHandleKnob.centerXAnchor.constraint(equalTo: rightHandleView.centerXAnchor).isActive = true
    }
    
    private func setupMaskView() {
        
        leftMaskView.isUserInteractionEnabled = false
        leftMaskView.backgroundColor = .lightGray
        leftMaskView.alpha = 0.5
        leftMaskView.translatesAutoresizingMaskIntoConstraints = false
        self.viewScrollViewContent.insertSubview(leftMaskView, belowSubview: leftHandleView)
        
        leftMaskView.leadingAnchor.constraint(equalTo: self.firstCellLeadingAnchor ?? self.viewVideoTimeLine.leadingAnchor).isActive = true
        leftMaskView.bottomAnchor.constraint(equalTo: self.viewVideoTimeLine.bottomAnchor).isActive = true
        leftMaskView.topAnchor.constraint(equalTo: self.viewVideoTimeLine.topAnchor).isActive = true
        leftMaskView.rightAnchor.constraint(equalTo: leftHandleView.centerXAnchor).isActive = true
        
        
        rightMaskView.isUserInteractionEnabled = false
        rightMaskView.backgroundColor = .lightGray
        rightMaskView.alpha = 0.5
        rightMaskView.translatesAutoresizingMaskIntoConstraints = false
        self.viewScrollViewContent.insertSubview(rightMaskView, belowSubview: rightHandleView)
        
        rightMaskView.trailingAnchor.constraint(equalTo: self.lastCellTrailingAnchor ?? self.viewVideoTimeLine.trailingAnchor).isActive = true
        rightMaskView.bottomAnchor.constraint(equalTo: self.viewVideoTimeLine.bottomAnchor).isActive = true
        rightMaskView.topAnchor.constraint(equalTo: self.viewVideoTimeLine.topAnchor).isActive = true
        rightMaskView.leftAnchor.constraint(equalTo: rightHandleView.centerXAnchor).isActive = true
        
    }
    
    private func setupGestures() {
        
        let leftPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture))
        leftHandleView.addGestureRecognizer(leftPanGestureRecognizer)
        let rightPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture))
        rightHandleView.addGestureRecognizer(rightPanGestureRecognizer)
    }
    
    // MARK: - Trim Gestures
    @objc func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let view = gestureRecognizer.view, let superView = gestureRecognizer.view?.superview else { return }
        let isLeftGesture = view == leftHandleView
        switch gestureRecognizer.state {
            
        case .began:
            if isLeftGesture {
                currentLeftConstraint = leftConstraint!.constant
            } else {
                currentRightConstraint = rightConstraint!.constant
            }
//            updateSelectedTime(stoppedMoving: false)
        case .changed:
            let translation = gestureRecognizer.translation(in: superView)
            if isLeftGesture {
                updateLeftConstraint(with: translation)
            } else {
                updateRightConstraint(with: translation)
            }
            self.view.layoutIfNeeded()
//            if let startTime = startTime, isLeftGesture {
//                seek(to: startTime)
//            } else if let endTime = endTime {
//                seek(to: endTime)
//            }
//            updateSelectedTime(stoppedMoving: false)
            
        case .cancelled, .ended, .failed: break
//            updateSelectedTime(stoppedMoving: true)
        default: break
        }
    }
    
    private func updateLeftConstraint(with translation: CGPoint) {
        print("x position :- \(translation.x)")
        let maxConstraint = max(rightHandleView.frame.origin.x - handleWidth - minimumDistanceBetweenHandle, 0)
        print("max : \(maxConstraint)")
        print("current contraint : \(currentLeftConstraint + translation.x)")
        let newConstraint = min(max(0, currentLeftConstraint + translation.x), maxConstraint)
        print("new : \(newConstraint)")
        leftConstraint?.constant = newConstraint
    }
    
    private func updateRightConstraint(with translation: CGPoint) {
        print("x position :- \(translation.x)")
        let maxConstraint = min(2 * handleWidth - self.viewVideoTimeLine.frame.width + leftHandleView.frame.origin.x + minimumDistanceBetweenHandle, 0)
        print("max : \(maxConstraint)")
        print("current contraint : \(currentLeftConstraint + translation.x)")
        let newConstraint = max(min(0, currentRightConstraint + translation.x), maxConstraint)
        print("max : \(maxConstraint)")
        rightConstraint?.constant = newConstraint
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

extension ViewController: TrimmerViewDelegate{
    func didChangePositionBar(_ playerTime: CMTime) {
        print(playerTime.positionalTime)
    }
    
    func positionBarStoppedMoving(_ playerTime: CMTime) {
        print(playerTime.positionalTime)
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

