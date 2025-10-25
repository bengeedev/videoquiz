//
//  GameViewController.swift
//  VideoQuiz iOS
//
//  Created by Benjamin Gievis
//

import UIKit
import StoreKit
import AVFoundation
import AVKit

class GameViewController: UIViewController {
    
    // MARK: - UI Elements
    let imageView = UIImageView()
    let videoPlayerView = UIView()  // Container for video player
    var videoPlayer: AVPlayer?
    var videoPlayerLayer: AVPlayerLayer?
    let videoControlButton = UIButton()  // Pause/Play button
    var isVideoPlaying = true
    let backgroundView = UIView()
    let letterCollectionView = GameBoardManager.UIComponents.setupLetterCollectionView()
    let keyboardCollectionView = GameBoardManager.UIComponents.setupKeyboardCollectionView()
    
    lazy var toolbar: GameToolbarView = {
        let toolbar = GameToolbarView()
        toolbar.onBackTapped = { [weak self] in self?.backTapped() }
        toolbar.onHintTapped = { [weak self] in self?.useHint() }
        toolbar.onLevelTapped = { [weak self] in self?.levelTapped() }
        toolbar.onCoinsTapped = { [weak self] in self?.coinsTapped() }
        toolbar.onGiftTapped = { [weak self] in self?.giftTapped() }
        toolbar.onNextTapped = { [weak self] in self?.nextTapped() }
        return toolbar
    }()
    
    let coinCountLabel: UILabel = {
        let label = UILabel()
        label.text = "100"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        label.layer.cornerRadius = 15
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Video overlay components
    lazy var videoOverlayView: VideoOverlayView = {
        let overlay = VideoOverlayView()
        overlay.onBackTapped = { [weak self] in self?.backTapped() }
        overlay.onHintTapped = { [weak self] in self?.useHint() }
        overlay.onLevelTapped = { [weak self] in self?.levelTapped() }
        overlay.onCoinsTapped = { [weak self] in self?.coinsTapped() }
        overlay.onGiftTapped = { [weak self] in self?.giftTapped() }
        overlay.onNextTapped = { [weak self] in self?.nextTapped() }
        overlay.translatesAutoresizingMaskIntoConstraints = false
        return overlay
    }()
    
    lazy var coinOverlayView: CoinOverlayView = {
        let overlay = CoinOverlayView()
        overlay.translatesAutoresizingMaskIntoConstraints = false
        return overlay
    }()
    
    var letterCollectionHeightConstraint: NSLayoutConstraint!
    
    // MARK: - View Model and Board Manager
    let viewModel = GameViewModel()
    private var gameBoardManager: GameBoardManager!
    
    // MARK: - Lifecycle
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1) Load levels & restore state
        viewModel.loadLevels(for: "en")
        viewModel.loadCurrentLevel(with: letterCollectionView)
        
        guard let gameBoardManager = viewModel.gameBoardManager else {
            fatalError("GameBoardManager not initialized after loadCurrentLevel()")
        }
        self.gameBoardManager = gameBoardManager
        
        // Set up the callback to refresh keyboard
        gameBoardManager.onKeyboardUpdateNeeded = { [weak self] in
            self?.keyboardCollectionView.reloadData()
        }
        
        // 2) Setup UI
        setupUI()
        setupGestures()
        setupNotifications()
        
        // 3) Update UI (including puzzle image)
        updateUI()
        
        // 4) Ensure collection views are properly configured for interaction
        letterCollectionView.reloadData()
        keyboardCollectionView.reloadData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTargetZoneLayout()
        updateKeyboardLayout()
        
        // Update video player layer frame
        videoPlayerLayer?.frame = videoPlayerView.bounds
    }
    
    func animateRemoveLetters(_ removedIndices: [Int]) {
        print("Removed indices: \(removedIndices)")
        
        // Ensure viewModel reflects the latest state
        _ = viewModel.availableLetters // Just to trigger any refresh if needed
        
        // Reload data first to sync the collection view with availableLetters
        keyboardCollectionView.reloadData()
        keyboardCollectionView.layoutIfNeeded()
        
        let indexPaths = removedIndices.map { IndexPath(item: $0, section: 0) }
        print("IndexPaths to animate: \(indexPaths)")
        
        // Fetch cells after reload to ensure they match the updated state
        let cellsToAnimate = indexPaths.compactMap { keyboardCollectionView.cellForItem(at: $0) as? GameBoardManager.KeyboardCell }
        print("Cells found: \(cellsToAnimate.count)")
        
        guard !cellsToAnimate.isEmpty else {
            print("No cells to animate - possibly already reloaded.")
            return
        }
        
        UIView.animate(withDuration: 0.5, animations: {
            cellsToAnimate.forEach { cell in
                cell.letterLabel.alpha = 0
                cell.contentView.backgroundColor = UIColor.lightGray
                cell.letterLabel.textColor = UIColor.darkGray
            }
        }) { _ in
            // Final reload sets the cell’s label to "" from the updated data model
            self.keyboardCollectionView.reloadData()
            self.letterCollectionView.reloadData()
        }

    }
    
    // ------------------------------------------------
    // MARK: - Automatically Save When View Disappears
    // ------------------------------------------------
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.saveGameState()
        stopVideo()  // Stop video when leaving the screen
    }
    
    deinit {
        stopVideo()  // Clean up when view controller is deallocated
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - UI Update
    func updateUI() {
        letterCollectionView.reloadData()
        keyboardCollectionView.reloadData()
        updateCoinDisplay()
        
        // Handle media (image or video) based on current level
        switch viewModel.currentLevelMedia {
        case .image(let imageName):
            print("Loading image: \(imageName)")
            imageView.image = UIImage(named: imageName.lowercased()) ?? UIImage(named: "placeholder")
            showImageView()
            
        case .video(let videoName):
            print("Loading video: \(videoName)")
            loadVideo(named: videoName.lowercased())
            showVideoView()
            
        case .placeholder:
            print("No media available, using placeholder")
            imageView.image = UIImage(named: "placeholder")
            showImageView()
        }
    }
    
    func updateCoinDisplay() {
        coinCountLabel.text = "\(viewModel.coins)"
        coinOverlayView.updateCoins(viewModel.coins, animated: true)
        
        // Add a subtle animation when coins change
        UIView.animate(withDuration: 0.2, animations: {
            self.coinCountLabel.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }) { _ in
            UIView.animate(withDuration: 0.2) {
                self.coinCountLabel.transform = .identity
            }
        }
    }
    
    // MARK: - Video Handling
    private func loadVideo(named videoName: String) {
        // Stop current video if playing
        stopVideo()
        
        // Debug: List all files in bundle
        if let bundlePath = Bundle.main.resourcePath {
            let fileManager = FileManager.default
            do {
                let files = try fileManager.contentsOfDirectory(atPath: bundlePath)
                let mp4Files = files.filter { $0.hasSuffix(".mp4") }
                print("Available MP4 files in bundle: \(mp4Files)")
            } catch {
                print("Error listing bundle contents: \(error)")
            }
        }
        
        // Find video file in bundle
        guard let videoURL = Bundle.main.url(forResource: videoName, withExtension: "mp4") else {
            print("Could not find video file: \(videoName).mp4")
            print("Bundle path: \(Bundle.main.bundlePath)")
            showImageView() // Fallback to image view
            return
        }
        
        print("Found video file: \(videoURL)")
        
        // Create player
        videoPlayer = AVPlayer(url: videoURL)
        
        // Create player layer
        videoPlayerLayer = AVPlayerLayer(player: videoPlayer)
        videoPlayerLayer?.videoGravity = .resizeAspectFill
        videoPlayerLayer?.frame = videoPlayerView.bounds
        videoPlayerLayer?.backgroundColor = UIColor.black.cgColor
        
        // Add layer to container
        if let layer = videoPlayerLayer {
            videoPlayerView.layer.addSublayer(layer)
        }
        
        // Set up looping
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(videoDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: videoPlayer?.currentItem
        )
        
        // Start playing
        videoPlayer?.play()
        isVideoPlaying = true
        updateVideoControlButton()
    }
    
    private func stopVideo() {
        videoPlayer?.pause()
        videoPlayerLayer?.removeFromSuperlayer()
        videoPlayerLayer = nil
        videoPlayer = nil
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    @objc private func videoDidFinishPlaying() {
        // Loop the video
        videoPlayer?.seek(to: .zero)
        if isVideoPlaying {
            videoPlayer?.play()
        }
    }
    
    private func showImageView() {
        imageView.isHidden = false
        videoPlayerView.isHidden = true
        videoControlButton.isHidden = true  // Hide button when showing image
        stopVideo()
        
        // Show traditional toolbar for images
        toolbar.isHidden = false
        coinCountLabel.isHidden = false
        
        // Hide video overlay
        videoOverlayView.isHidden = true
        coinOverlayView.isHidden = true
        
        // For images, position game area below image (not overlay)
        backgroundView.topAnchor.constraint(equalTo: imageView.bottomAnchor).isActive = true
        backgroundView.topAnchor.constraint(equalTo: view.centerYAnchor, constant: 50).isActive = false
    }
    
    private func showVideoView() {
        imageView.isHidden = true
        videoPlayerView.isHidden = false
        videoControlButton.isHidden = false  // Make sure button is visible
        
        // Hide traditional toolbar for videos
        toolbar.isHidden = true
        coinCountLabel.isHidden = true
        
        // Show video overlay
        videoOverlayView.isHidden = false
        coinOverlayView.isHidden = false
        
        // For videos, position game area lower to fill space where old bar was
        backgroundView.topAnchor.constraint(equalTo: view.centerYAnchor, constant: 80).isActive = true
        backgroundView.topAnchor.constraint(equalTo: imageView.bottomAnchor).isActive = false
        
        // Animate overlay appearance
        videoOverlayView.showOverlay(animated: true)
        
        // Debug button state
        print("Showing video view and control button")
        print("Button frame: \(videoControlButton.frame)")
        print("Button isHidden: \(videoControlButton.isHidden)")
        print("Button alpha: \(videoControlButton.alpha)")
        print("Button superview: \(videoControlButton.superview?.description ?? "nil")")
    }
    
    // MARK: - Video Control Button Setup
    private func setupVideoControlButton() {
        videoControlButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Glass-morphism styling
        videoControlButton.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        videoControlButton.layer.cornerRadius = 25
        videoControlButton.layer.borderWidth = 1
        videoControlButton.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        
        // Add subtle shadow for depth
        videoControlButton.layer.shadowColor = UIColor.black.cgColor
        videoControlButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        videoControlButton.layer.shadowRadius = 8
        videoControlButton.layer.shadowOpacity = 0.3
        
        // Make sure button is visible and on top
        videoControlButton.alpha = 1.0
        videoControlButton.isHidden = false
        videoControlButton.layer.zPosition = 1000  // High z-index to ensure it's on top
        
        // Set initial state (playing)
        updateVideoControlButton()
        
        // Add action
        videoControlButton.addTarget(self, action: #selector(videoControlButtonTapped), for: .touchUpInside)
        
        print("Video control button setup complete")
    }
    
    private func updateVideoControlButton() {
        if isVideoPlaying {
            // Show pause icon
            let pauseImage = UIImage(systemName: "pause.fill")
            videoControlButton.setImage(pauseImage, for: .normal)
        } else {
            // Show play icon
            let playImage = UIImage(systemName: "play.fill")
            videoControlButton.setImage(playImage, for: .normal)
        }
        
        // Glass-morphism icon styling
        videoControlButton.tintColor = .white
        videoControlButton.imageView?.contentMode = .scaleAspectFit
        videoControlButton.imageView?.layer.shadowColor = UIColor.black.cgColor
        videoControlButton.imageView?.layer.shadowOffset = CGSize(width: 0, height: 1)
        videoControlButton.imageView?.layer.shadowRadius = 2
        videoControlButton.imageView?.layer.shadowOpacity = 0.5
    }
    
    @objc private func videoControlButtonTapped() {
        print("Video control button tapped!")
        
        // Add subtle tap animation
        UIView.animate(withDuration: 0.1, animations: {
            self.videoControlButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.videoControlButton.transform = .identity
            }
        }
        
        if isVideoPlaying {
            // Pause video
            print("Pausing video")
            videoPlayer?.pause()
            isVideoPlaying = false
        } else {
            // Play video
            print("Playing video")
            videoPlayer?.play()
            isVideoPlaying = true
        }
        
        updateVideoControlButton()
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    // MARK: - Layout Methods
    func updateTargetZoneLayout() {
        let letterCount = viewModel.targetLetters.count
        let layout = createTargetZoneLayout(forLetterCount: letterCount)
        letterCollectionView.setCollectionViewLayout(layout, animated: false)
    }
    
    func createTargetZoneLayout(forLetterCount count: Int) -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { (sectionIndex, environment) -> NSCollectionLayoutSection? in
            let sideInsets: CGFloat = 20
            let availableWidth = environment.container.effectiveContentSize.width - 2 * sideInsets
            let interItemSpacing: CGFloat = 5.0
            let totalSpacing = interItemSpacing * CGFloat(max(count - 1, 0))
            let itemWidth = min((availableWidth - totalSpacing) / CGFloat(count), 50)
            let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(itemWidth),
                                                  heightDimension: .absolute(itemWidth))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .absolute(itemWidth))
            let subitems = Array(repeating: item, count: count)
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: subitems)
            group.interItemSpacing = .fixed(interItemSpacing)
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: sideInsets, bottom: 10, trailing: sideInsets)
            section.orthogonalScrollingBehavior = .continuous
            return section
        }
    }
    
    func updateKeyboardLayout() {
        let rows = 3
        let cols = 7
        let spacing: CGFloat = 5.0
        
        let availableWidth = keyboardCollectionView.bounds.width
        guard availableWidth > 0 else { return }
        
        let totalHorizontalSpacing = CGFloat(cols - 1) * spacing
        let cellWidth = (availableWidth - totalHorizontalSpacing) / CGFloat(cols)
        let totalKeyboardHeight = CGFloat(rows) * cellWidth + CGFloat(rows - 1) * spacing
        
        if let layout = keyboardCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .vertical
            layout.itemSize = CGSize(width: cellWidth, height: cellWidth)
            layout.minimumInteritemSpacing = spacing
            layout.minimumLineSpacing = spacing
            layout.sectionInset = .zero
            layout.invalidateLayout()
        }
        
        keyboardCollectionView.reloadData()
    }
    
    // MARK: - UI Setup
    func setupUI() {
        view.backgroundColor = .black  // Use black background instead of green
        view.addSubview(imageView)
        view.addSubview(videoPlayerView)  // Add video player view
        view.addSubview(videoControlButton)  // Add button to main view (on top of everything)
        view.addSubview(backgroundView)
        view.addSubview(toolbar)
        view.addSubview(coinCountLabel)
        
        // Add video overlay components
        view.addSubview(videoOverlayView)
        view.addSubview(coinOverlayView)
        
        // Ensure overlay components are on top
        videoOverlayView.layer.zPosition = 20
        videoOverlayView.isHidden = false  // Make sure it's visible
        coinOverlayView.layer.zPosition = 20
        backgroundView.addSubview(letterCollectionView)
        backgroundView.addSubview(keyboardCollectionView)
        
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .gray
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        videoPlayerView.backgroundColor = .black
        videoPlayerView.translatesAutoresizingMaskIntoConstraints = false
        videoPlayerView.isHidden = true  // Initially hidden
        videoPlayerView.layer.zPosition = 1  // Behind game elements but above background
        
        // Setup video control button
        setupVideoControlButton()
        
        // Replace green background with blur
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.isUserInteractionEnabled = false  // Allow touches to pass through blur
        backgroundView.addSubview(blurView)
        
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: backgroundView.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor)
        ])
        
        backgroundView.backgroundColor = .clear
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.isUserInteractionEnabled = true
        backgroundView.layer.zPosition = 5  // Above video but below overlay controls
        
        gameBoardManager.registerCells(for: letterCollectionView)
        gameBoardManager.registerCells(for: keyboardCollectionView)
        
        letterCollectionView.dataSource = self
        letterCollectionView.delegate = self
        letterCollectionView.backgroundColor = .clear
        letterCollectionView.translatesAutoresizingMaskIntoConstraints = false
        letterCollectionView.isUserInteractionEnabled = true
        letterCollectionView.isScrollEnabled = false  // Ensure scrolling doesn't interfere
        letterCollectionView.layer.zPosition = 10  // Ensure it's above blur background
        
        keyboardCollectionView.dataSource = self
        keyboardCollectionView.delegate = self
        keyboardCollectionView.backgroundColor = .clear  // Make background clear
        keyboardCollectionView.translatesAutoresizingMaskIntoConstraints = false
        keyboardCollectionView.isUserInteractionEnabled = true
        keyboardCollectionView.isScrollEnabled = true  // Allow scrolling for keyboard
        keyboardCollectionView.layer.zPosition = 10  // Ensure it's above blur background
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.7),
            
            videoPlayerView.topAnchor.constraint(equalTo: view.topAnchor),
            videoPlayerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            videoPlayerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            videoPlayerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),  // Full screen video
            
            // Video control button constraints (positioned in top left)
            videoControlButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            videoControlButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            videoControlButton.widthAnchor.constraint(equalToConstant: 50),
            videoControlButton.heightAnchor.constraint(equalToConstant: 50),
            
            backgroundView.topAnchor.constraint(equalTo: imageView.bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            coinCountLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            coinCountLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            coinCountLabel.widthAnchor.constraint(equalToConstant: 80),
            coinCountLabel.heightAnchor.constraint(equalToConstant: 30),
            
            // Video overlay constraints - position at bottom of screen with more spacing
            videoOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            videoOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            videoOverlayView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -5),
            videoOverlayView.heightAnchor.constraint(equalToConstant: 80),
            
            // Coin overlay constraints (top-right of video)
            coinOverlayView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            coinOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            coinOverlayView.widthAnchor.constraint(equalToConstant: 100),
            coinOverlayView.heightAnchor.constraint(equalToConstant: 32),
            
            letterCollectionView.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 20),
            letterCollectionView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 20),
            letterCollectionView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -20)
        ])
        
        letterCollectionHeightConstraint = letterCollectionView.heightAnchor.constraint(equalToConstant: 50)
        letterCollectionHeightConstraint.priority = UILayoutPriority(999)
        letterCollectionHeightConstraint.isActive = true
        
        NSLayoutConstraint.activate([
            keyboardCollectionView.topAnchor.constraint(equalTo: letterCollectionView.bottomAnchor, constant: 20),
            keyboardCollectionView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 20),
            keyboardCollectionView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -20),
            keyboardCollectionView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -5)
        ])
        
    }
    
    // MARK: - Gestures
    func setupGestures() {
        let letterTap = UITapGestureRecognizer(target: self, action: #selector(handleLetterTap(_:)))
        letterCollectionView.addGestureRecognizer(letterTap)
        
        let keyboardTap = UITapGestureRecognizer(target: self, action: #selector(handleKeyboardTap(_:)))
        keyboardCollectionView.addGestureRecognizer(keyboardTap)
    }
    
    // MARK: - Notifications
    func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(coinsUpdated(_:)),
            name: .coinsUpdated,
            object: nil
        )
    }
    
    @objc private func coinsUpdated(_ notification: Notification) {
        DispatchQueue.main.async {
            self.updateCoinDisplay()
        }
    }
    
    
    @objc func handleLetterTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: letterCollectionView)
        guard let indexPath = letterCollectionView.indexPathForItem(at: point) else { return }
        let slotIndex = indexPath.item
        
        // If slot is frozen (hint letter), skip removal
        if viewModel.isSlotFrozen(slotIndex) {
            return
        }
        
        // If the slot has a letter, remove it with animation
        if let removedLetter = viewModel.currentGuess[slotIndex], !removedLetter.isEmpty {
            if let tileIndex = viewModel.getTileIndexForSlot(slotIndex) {
                // Get cells for animation
                if let sourceCell = letterCollectionView.cellForItem(at: indexPath),
                   let targetCell = keyboardCollectionView.cellForItem(at: IndexPath(item: tileIndex, section: 0)) {
                    
                    // Clean up any error state before removal
                    cleanupErrorState(for: sourceCell)
                    
                    // Animate the removal with reverse flying effect
                    animateLetterRemoval(from: sourceCell, to: targetCell, tileIndex: tileIndex, slotIndex: slotIndex)
                } else {
                    // Fallback if cells not found
                    viewModel.removeLetterFromSlot(slotIndex)
                    let kbIndexPath = IndexPath(item: tileIndex, section: 0)
                    keyboardCollectionView.reloadItems(at: [kbIndexPath])
                    letterCollectionView.reloadItems(at: [indexPath])
                    viewModel.saveGameState()
                }
            }
        }
    }

    @objc func handleKeyboardTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: keyboardCollectionView)
        guard let keyboardIndexPath = keyboardCollectionView.indexPathForItem(at: point) else { return }
        
        let tileIndex = keyboardIndexPath.item
        let tile = viewModel.availableLetters[tileIndex]
        guard !tile.isUsed else { return }
        
        // Find first empty slot, or if grid is full, find the first slot that can be replaced
        let targetIndex: Int
        if let emptyIndex = viewModel.currentGuess.firstIndex(where: { $0 == nil }) {
            targetIndex = emptyIndex
        } else {
            guard let replaceableIndex = viewModel.currentGuess.enumerated().first(where: { index, letter in
                letter != nil && !viewModel.isSlotFrozen(index)
            })?.offset else { return }
            targetIndex = replaceableIndex
        }
        
        // Get cells for animation
        guard let keyboardCell = keyboardCollectionView.cellForItem(at: keyboardIndexPath) else { return }
        let targetIndexPath = IndexPath(item: targetIndex, section: 0)
        letterCollectionView.layoutIfNeeded()
        guard let targetCell = letterCollectionView.cellForItem(at: targetIndexPath) as? GameBoardManager.LetterSlotCell else { return }
        
        // Add subtle tap animation to keyboard cell
        UIView.animate(withDuration: 0.1, animations: {
            keyboardCell.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                keyboardCell.transform = .identity
            }
        }
        
        // Create flying animation with proper timing
        animateLetterInsertion(from: keyboardCell, to: targetCell, tileIndex: tileIndex, slotIndex: targetIndex)
    }

    // MARK: - Enhanced Animation Helpers
    
    /// Animates letter insertion with proper timing to avoid blinking
    private func animateLetterInsertion(from keyboardCell: UICollectionViewCell, to targetCell: GameBoardManager.LetterSlotCell, tileIndex: Int, slotIndex: Int) {
        // Create snapshot for flying animation
        guard let snapshot = keyboardCell.snapshotView(afterScreenUpdates: false) else { return }
        snapshot.frame = keyboardCollectionView.convert(keyboardCell.frame, to: view)
        
        // Add subtle shadow for depth
        snapshot.layer.shadowColor = UIColor.black.cgColor
        snapshot.layer.shadowRadius = 4
        snapshot.layer.shadowOpacity = 0.3
        snapshot.layer.shadowOffset = CGSize(width: 0, height: 2)
        snapshot.layer.zPosition = 100  // Ensure snapshot is above everything
        
        view.addSubview(snapshot)
        
        // Hide original keyboard cell temporarily
        keyboardCell.alpha = 0.3
        
        // Light haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Get target frame
        let targetFrame = letterCollectionView.convert(targetCell.frame, to: view)
        
        // Smooth flying animation
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.5,
            options: [.curveEaseOut],
            animations: {
                snapshot.frame = targetFrame
                snapshot.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            }
        ) { _ in
            // Insert the letter AFTER animation completes
            _ = self.viewModel.insertLetterAtExactIndex(tileIndex, intoSlot: slotIndex)
            
            // Configure the target cell with the new letter
            targetCell.configure(with: self.viewModel.currentGuess[slotIndex] ?? "", state: .normal)
            
            // Update UI
            self.keyboardCollectionView.performBatchUpdates({
                self.keyboardCollectionView.reloadItems(at: [IndexPath(item: tileIndex, section: 0)])
            }, completion: nil)
            
            self.letterCollectionView.performBatchUpdates({
                self.letterCollectionView.reloadItems(at: [IndexPath(item: slotIndex, section: 0)])
            }, completion: nil)
            
            // Remove snapshot and restore keyboard cell
            snapshot.removeFromSuperview()
            keyboardCell.alpha = 1.0
            
            // Add arrival glow effect
            self.addArrivalGlowEffect(to: targetCell)
            
            self.viewModel.saveGameState()
        }
    }
    
    /// Animates letter removal with reverse flying effect - preserves red state until removal
    private func animateLetterRemoval(from sourceCell: UICollectionViewCell, to targetCell: UICollectionViewCell, tileIndex: Int, slotIndex: Int) {
        // Clean up only animation effects, preserve red background
        sourceCell.layer.borderWidth = 0.0
        sourceCell.layer.borderColor = UIColor.clear.cgColor
        sourceCell.transform = .identity
        // Keep the red background - it will be cleared when the cell is reconfigured
        
        // Create snapshot for flying animation
        guard let snapshot = sourceCell.snapshotView(afterScreenUpdates: false) else { return }
        snapshot.frame = letterCollectionView.convert(sourceCell.frame, to: view)
        
        // Add subtle shadow for depth
        snapshot.layer.shadowColor = UIColor.black.cgColor
        snapshot.layer.shadowRadius = 4
        snapshot.layer.shadowOpacity = 0.3
        snapshot.layer.shadowOffset = CGSize(width: 0, height: 2)
        snapshot.layer.zPosition = 100  // Ensure snapshot is above everything
        
        view.addSubview(snapshot)
        
        // Hide original source cell temporarily
        sourceCell.alpha = 0.3
        
        // Light haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Get target frame
        let targetFrame = keyboardCollectionView.convert(targetCell.frame, to: view)
        
        // Smooth reverse flying animation
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.5,
            options: [.curveEaseOut],
            animations: {
                snapshot.frame = targetFrame
                snapshot.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }
        ) { _ in
            // Remove the letter AFTER animation completes
            self.viewModel.removeLetterFromSlot(slotIndex)
            
            // Update UI - this will reconfigure cells and clear red state
            self.keyboardCollectionView.performBatchUpdates({
                self.keyboardCollectionView.reloadItems(at: [IndexPath(item: tileIndex, section: 0)])
            }, completion: nil)
            
            self.letterCollectionView.performBatchUpdates({
                self.letterCollectionView.reloadItems(at: [IndexPath(item: slotIndex, section: 0)])
            }, completion: nil)
            
            // Remove snapshot and restore source cell
            snapshot.removeFromSuperview()
            sourceCell.alpha = 1.0
            
            // Add return glow effect
            self.addReturnGlowEffect(to: targetCell)
            
            self.viewModel.saveGameState()
        }
    }
    
    /// Cleans up error animation effects without interfering with persistent red state
    private func cleanupErrorState(for cell: UICollectionViewCell) {
        // Remove only animation-related effects, NOT the persistent red background
        cell.layer.borderWidth = 0.0
        cell.layer.borderColor = UIColor.clear.cgColor
        cell.transform = .identity
        // DON'T clear backgroundColor - let the cell configuration handle the state
    }
    
    /// Adds a subtle glow effect behind the returned letter
    private func addReturnGlowEffect(to cell: UICollectionViewCell) {
        // Create a subtle glow behind the cell
        cell.layer.shadowColor = UIColor.systemOrange.cgColor
        cell.layer.shadowRadius = 6
        cell.layer.shadowOpacity = 0.5
        cell.layer.shadowOffset = CGSize(width: 0, height: 0)
        
        // Animate the glow appearing
        cell.layer.shadowOpacity = 0.0
        
        UIView.animate(
            withDuration: 0.15,
            delay: 0,
            options: [.curveEaseOut],
            animations: {
                cell.layer.shadowOpacity = 0.5
            }
        ) { _ in
            // Fade out the glow after a moment
            UIView.animate(
                withDuration: 0.3,
                delay: 0.2,
                options: [.curveEaseOut],
                animations: {
                    cell.layer.shadowOpacity = 0.0
                },
                completion: { _ in
                    // Clean up shadow properties
                    cell.layer.shadowRadius = 0
                    cell.layer.shadowOpacity = 0
                }
            )
        }
    }
    
    /// Adds a subtle glow effect behind the arrived letter
    private func addArrivalGlowEffect(to cell: UICollectionViewCell) {
        // Create a subtle glow behind the cell
        cell.layer.shadowColor = UIColor.systemBlue.cgColor
        cell.layer.shadowRadius = 8
        cell.layer.shadowOpacity = 0.6
        cell.layer.shadowOffset = CGSize(width: 0, height: 0)
        
        // Animate the glow appearing
        cell.layer.shadowOpacity = 0.0
        
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: [.curveEaseOut],
            animations: {
                cell.layer.shadowOpacity = 0.6
            }
        ) { _ in
            // Fade out the glow after a moment
            UIView.animate(
                withDuration: 0.4,
                delay: 0.3,
                options: [.curveEaseOut],
                animations: {
                    cell.layer.shadowOpacity = 0.0
                },
                completion: { _ in
                    // Clean up shadow properties
                    cell.layer.shadowRadius = 0
                    cell.layer.shadowOpacity = 0
                }
            )
        }
    }
    
    // MARK: - Toolbar Actions
    func backTapped() {
        dismiss(animated: true)
    }
    
    func useHint() {
        let hintModal = HintModalViewController(gameViewController: self)
        hintModal.modalPresentationStyle = .formSheet
        present(hintModal, animated: true)
    }
    
    func levelTapped() {
        let achievementModal = AchievementModalViewController(viewModel: viewModel)
        achievementModal.modalPresentationStyle = .formSheet
        present(achievementModal, animated: true)
    }
    
    func coinsTapped() {
        let coinModal = CoinModalViewController(coinCount: viewModel.coins, viewModel: viewModel)
        coinModal.modalPresentationStyle = .formSheet
        present(coinModal, animated: true)
    }
    
    func giftTapped() {
        let giftModal = GiftModalViewController(gameViewController: self)
        giftModal.modalPresentationStyle = .formSheet
        present(giftModal, animated: true)
    }
    
    func nextTapped() {
        let nextLevelModal = NextLevelModalViewController(gameViewController: self)
        nextLevelModal.modalPresentationStyle = .formSheet
        present(nextLevelModal, animated: true)
    }
    
    // MARK: - Handle Win Logic
    func handleWin() {
        letterCollectionView.isUserInteractionEnabled = false
        keyboardCollectionView.isUserInteractionEnabled = false
        
        let letterCells = letterCollectionView.visibleCells
        Animations.animateWin(for: letterCells) { [weak self] in
            self?.presentWinModal()
        }
    }
    
    private func presentWinModal() {
        let completedLevel = viewModel.completedLevel
        // Award coins based on level difficulty (longer words = more coins)
        let wordLength = viewModel.targetLetters.count
        let coinsEarned = min(50 + (wordLength - 3) * 5, 100) // Base 50, +5 per extra letter, max 100
        
        // Award the coins immediately
        viewModel.addCoins(coinsEarned)
        
        // Track level completion for achievements
        viewModel.trackLevelCompletion(usedHints: false) // TODO: Track if hints were actually used
        
        let winModal = WinModalViewController(
            completedLevel: completedLevel,
            coinsEarned: coinsEarned,
            gameViewController: self
        )
        winModal.modalPresentationStyle = .overFullScreen
        winModal.modalTransitionStyle = .crossDissolve
        present(winModal, animated: true)
    }
    
    public func goToNextLevel() {
        // Advance to the next level in the model
        viewModel.advanceToNextLevel()
        viewModel.loadCurrentLevel(with: letterCollectionView)
        
        guard let gameBoardManager = viewModel.gameBoardManager else { return }
        self.gameBoardManager = gameBoardManager
        
        // Re-enable user interaction
        letterCollectionView.isUserInteractionEnabled = true
        keyboardCollectionView.isUserInteractionEnabled = true
        
        // Now refresh UI with the new level data (including new puzzle image)
        updateUI()
    }
}

// MARK: - UICollectionViewDataSource & Delegate
extension GameViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int { return 1 }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == letterCollectionView {
            return viewModel.targetLetters.count
        } else {
            return viewModel.availableLetters.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == letterCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LetterSlotCell", for: indexPath) as! GameBoardManager.LetterSlotCell
            let displayChar = viewModel.currentGuess[indexPath.item] ?? ""
            
            if viewModel.isSlotFrozen(indexPath.item) {
                // If the slot is frozen, color it as hint
                cell.configure(with: displayChar, state: .hint)
            }
            else if !viewModel.currentGuess.contains(where: { $0 == nil }) && viewModel.checkWin() {
                // The guess is complete AND correct - show as winning!
                cell.configure(with: displayChar, state: .correct)
            }
            else if !viewModel.currentGuess.contains(where: { $0 == nil }) && !viewModel.checkWin() {
                // The guess is complete but incorrect
                cell.configure(with: displayChar, state: .incorrect)
            }
            else {
                cell.configure(with: displayChar, state: .normal)
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "KeyboardCell", for: indexPath) as! GameBoardManager.KeyboardCell
            let tile = viewModel.availableLetters[indexPath.item]
            cell.configure(with: tile)
            return cell
        }
    }
}

extension GameViewController {
    func animateRevealLetters(_ revealData: [(slotIndex: Int, tileIndex: Int, letter: String)]) {
        for reveal in revealData {
            let targetIndexPath = IndexPath(item: reveal.slotIndex, section: 0)
            let keyboardIndexPath = IndexPath(item: reveal.tileIndex, section: 0)
            
            guard let keyboardCell = keyboardCollectionView.cellForItem(at: keyboardIndexPath),
                  let targetCell = letterCollectionView.cellForItem(at: targetIndexPath) as? GameBoardManager.LetterSlotCell else {
                continue
            }
            
            // Convert target cell frame to the main view coordinate space
            let targetFrame = letterCollectionView.convert(targetCell.frame, to: view)
            // Create a snapshot of the keyboard cell
            guard let snapshot = keyboardCell.snapshotView(afterScreenUpdates: false) else { continue }
            snapshot.frame = keyboardCollectionView.convert(keyboardCell.frame, to: view)
            snapshot.layer.zPosition = 100  // Ensure snapshot is above everything
            view.addSubview(snapshot)
            
            // Animate the snapshot moving to the target cell frame
            UIView.animate(withDuration: 0.3, animations: {
                snapshot.frame = targetFrame
            }) { _ in
                snapshot.removeFromSuperview()
                // After the animation, update the target cell to show the revealed letter in hint style
                targetCell.configure(with: reveal.letter, state: .hint)
                // Reload the keyboard cell to reflect that the tile is now used
                self.keyboardCollectionView.reloadItems(at: [keyboardIndexPath])
            }
        }
        
        // Optionally, do a final board reload after a short delay:
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.letterCollectionView.reloadData()
            self.keyboardCollectionView.reloadData()
            // Check for a win
            if self.viewModel.checkWin() {
                self.handleWin()
            }
        }
    }
}
