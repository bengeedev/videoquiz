//
//  WinModalViewController.swift
//  VideoQuiz iOS
//
//  Created by Benjamin Gievis
//

import UIKit

class WinModalViewController: UIViewController {
    private let completedLevel: Int
    private let coinsEarned: Int
    private weak var gameViewController: GameViewController?
    
    // UI Elements
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Congratulations!"
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textAlignment = .center
        label.textColor = .white
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let levelLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24)
        label.textAlignment = .center
        label.textColor = .white
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let coinsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .medium)
        label.textAlignment = .center
        label.textColor = .white
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Next Level", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 24, weight: .medium)
        button.backgroundColor = UIColor(red: 0.1, green: 0.4, blue: 0.1, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.alpha = 0
        button.translatesAutoresizingMaskIntoConstraints = false
        // Add shadow for depth
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        return button
    }()
    
    // Container view to group all UI elements
    private let containerView: UIView = {
       let view = UIView()
       view.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 0.95)
       view.layer.cornerRadius = 20
       view.alpha = 0
       view.translatesAutoresizingMaskIntoConstraints = false
       return view
    }()
    
    // Timer for coin count animation
    private var coinTimer: Timer?
    private var currentCoinCount: Int = 0
    
    // MARK: - Initializers
    init(completedLevel: Int, coinsEarned: Int, gameViewController: GameViewController) {
        self.completedLevel = completedLevel
        self.coinsEarned = coinsEarned
        self.gameViewController = gameViewController
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        setupUI()
        setupActions()
        updateLabels()
        // Immediately add coins to the global balance.
        gameViewController?.viewModel.addCoins(coinsEarned)
        stageAppearance()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(levelLabel)
        containerView.addSubview(coinsLabel)
        containerView.addSubview(nextButton)
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 300),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            levelLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            levelLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            levelLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            coinsLabel.topAnchor.constraint(equalTo: levelLabel.bottomAnchor, constant: 20),
            coinsLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            coinsLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            nextButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -30),
            nextButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 200),
            nextButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    private func setupActions() {
        nextButton.addTarget(self, action: #selector(nextLevelTapped), for: .touchUpInside)
    }
    
    private func updateLabels() {
        levelLabel.text = "Level \(completedLevel) Completed"
        coinsLabel.text = "You earned 0 coins"
    }
    
    // MARK: - Staged Appearance Animation
    private func stageAppearance() {
        // Fade in the container first
        UIView.animate(withDuration: 0.4, delay: 0.1, options: [], animations: {
            self.containerView.alpha = 1.0
        }, completion: { _ in
            self.showTitle()
        })
    }
    
    private func showTitle() {
        UIView.animate(withDuration: 0.4, animations: {
            self.titleLabel.alpha = 1.0
        }, completion: { _ in
            self.showLevelLabel()
        })
    }
    
    private func showLevelLabel() {
        UIView.animate(withDuration: 0.4, delay: 0.2, options: [], animations: {
            self.levelLabel.alpha = 1.0
        }, completion: { _ in
            self.showCoinsLabel()
        })
    }
    
    private func showCoinsLabel() {
        UIView.animate(withDuration: 0.4, delay: 0.2, options: [], animations: {
            self.coinsLabel.alpha = 1.0
        }, completion: { _ in
            self.animateCoinCount()
        })
    }
    
    // MARK: - Coin Count & Transfer Animation
    private func animateCoinCount() {
        currentCoinCount = 0
        let duration: TimeInterval = 1.5
        let interval: TimeInterval = 0.05
        let steps = Int(duration / interval)
        let increment = coinsEarned / steps
        coinTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: { timer in
            self.currentCoinCount += increment
            if self.currentCoinCount >= self.coinsEarned {
                self.currentCoinCount = self.coinsEarned
                timer.invalidate()
                // Launch the coin transfer effect
                self.launchCoinTransferAnimations()
                // Launch confetti and reveal the Next Level button
                self.launchConfetti()
                self.showNextButton()
            }
            self.coinsLabel.text = "You earned \(self.currentCoinCount) coins"
        })
    }
    
    private func showNextButton() {
        UIView.animate(withDuration: 0.4, delay: 0.3, options: [], animations: {
            self.nextButton.alpha = 1.0
        }, completion: nil)
    }
    
    // MARK: - Confetti Animation
    private func launchConfetti() {
        let confettiLayer = CAEmitterLayer()
        confettiLayer.emitterPosition = CGPoint(x: view.bounds.midX, y: -10)
        confettiLayer.emitterShape = .line
        confettiLayer.emitterSize = CGSize(width: view.bounds.size.width, height: 1)
        
        var cells: [CAEmitterCell] = []
        let colors: [UIColor] = [.systemRed, .systemBlue, .systemGreen, .systemOrange, .systemPurple, .systemYellow]
        for color in colors {
            let cell = CAEmitterCell()
            cell.birthRate = 4
            cell.lifetime = 8.0
            cell.velocity = CGFloat(150 + arc4random_uniform(50))
            cell.velocityRange = 100
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi / 4
            cell.spin = 3.5
            cell.spinRange = 1
            cell.scale = 0.6
            cell.scaleRange = 0.3
            cell.color = color.cgColor
            cell.contents = createConfettiImage(color: color)
            cells.append(cell)
        }
        confettiLayer.emitterCells = cells
        view.layer.addSublayer(confettiLayer)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            confettiLayer.birthRate = 0
        }
    }
    
    private func createConfettiImage(color: UIColor, size: CGSize = CGSize(width: 8, height: 8)) -> CGImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            color.setFill()
            context.fill(rect)
        }
        return image.cgImage
    }
    
    // MARK: - Coin Transfer Animation
    /// Programmatically draws a coin and returns it as a UIImage.
    private func createCoinImage() -> UIImage? {
        let size = CGSize(width: 30, height: 30)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            // Draw a filled yellow circle with an orange border to simulate a coin.
            let coinPath = UIBezierPath(ovalIn: rect)
            UIColor.systemYellow.setFill()
            coinPath.fill()
            UIColor.systemOrange.setStroke()
            coinPath.lineWidth = 2
            coinPath.stroke()
        }
    }
    
    /// Animate a single coin transferring from a start point to a target point.
    private func animateCoinTransfer(from startPoint: CGPoint, to targetPoint: CGPoint, in containerView: UIView, completion: (() -> Void)? = nil) {
        guard let coinImage = createCoinImage() else { return }
        let coinView = UIImageView(image: coinImage)
        coinView.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        coinView.center = startPoint
        containerView.addSubview(coinView)
        
        // Add a slight random offset to make multiple coins look natural.
        let randomOffsetX = CGFloat(arc4random_uniform(10)) - 5.0
        let randomOffsetY = CGFloat(arc4random_uniform(10)) - 5.0
        let adjustedTarget = CGPoint(x: targetPoint.x + randomOffsetX, y: targetPoint.y + randomOffsetY)
        
        UIView.animate(withDuration: 1.0, delay: 0, options: .curveEaseInOut, animations: {
            coinView.center = adjustedTarget
            coinView.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
            coinView.alpha = 0
        }, completion: { _ in
            coinView.removeFromSuperview()
            completion?()
        })
    }
    
    /// Launches multiple coin transfer animations.
    private func launchCoinTransferAnimations() {
        guard let window = view.window else { return }
        // Define the start point as the center of the containerView.
        let startPoint = containerView.center
        // Define the target point as the coin balance indicator.
        // Here, we assume the coin balance is at the top-right corner of the window.
        let targetPoint = CGPoint(x: window.bounds.width - 40, y: 60)
        // Animate 10 coins with slight delays between each.
        for i in 0..<10 {
            let delay = Double(i) * 0.1
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.animateCoinTransfer(from: startPoint, to: targetPoint, in: window)
            }
        }
    }
    
    // MARK: - Button Action
    @objc private func nextLevelTapped() {
        coinTimer?.invalidate()
        dismiss(animated: true) {
            self.gameViewController?.goToNextLevel()
        }
    }
}
