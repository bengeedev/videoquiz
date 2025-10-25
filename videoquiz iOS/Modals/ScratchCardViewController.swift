//
//  ScratchCardViewController.swift
//  VideoQuiz iOS
//
//  Created by Benjamin Gievis
//

import UIKit

class ScratchCardViewController: UIViewController {
    
    // Reference to game view model for awarding coins
    private weak var gameViewModel: GameViewModel?

    private let hiddenPrizeLabel: UILabel = {
        let label = UILabel()
        label.text = "You Won 100 Coins!"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        // The label stays hidden behind the scratch cover until reveal
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // Our custom scratch view that will “erase” its cover image as the user scratches.
    private var scratchImageView: ScratchImageView!
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Close", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .darkGray
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var coinPrize: Int = 0
    // Set a delay (in seconds) before showing the prize alert after the overlay is removed.
    private let alertDelay: TimeInterval = 2.0

    init(gameViewModel: GameViewModel? = nil) {
        self.gameViewModel = gameViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        coinPrize = [10, 20, 50, 100, 200].randomElement() ?? 0
        hiddenPrizeLabel.text = "You Won \(coinPrize) Coins!"

        setupUI()
    }
    
    private func setupUI() {
        // Add the prize label first so it sits behind the scratch cover.
        view.addSubview(hiddenPrizeLabel)
        NSLayoutConstraint.activate([
            hiddenPrizeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hiddenPrizeLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Create the scratch image view with a fixed size.
        scratchImageView = ScratchImageView(frame: CGRect(x: 0, y: 0, width: 300, height: 100))
        scratchImageView.translatesAutoresizingMaskIntoConstraints = false
        // Set a scratch threshold (number of brush strokes) before reveal.
        scratchImageView.threshold = 50
        // When the threshold is met, trigger the reveal.
        scratchImageView.onScratchThresholdReached = { [weak self] in
            self?.revealPrize()
        }
        view.addSubview(scratchImageView)
        NSLayoutConstraint.activate([
            scratchImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scratchImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            scratchImageView.widthAnchor.constraint(equalToConstant: 300),
            scratchImageView.heightAnchor.constraint(equalToConstant: 100)
        ])
        
        view.addSubview(closeButton)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        NSLayoutConstraint.activate([
            closeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            closeButton.topAnchor.constraint(equalTo: scratchImageView.bottomAnchor, constant: 40),
            closeButton.widthAnchor.constraint(equalToConstant: 120),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func revealPrize() {
        // Fade out the scratch cover for a smooth reveal.
        UIView.animate(withDuration: 0.5, animations: {
            self.scratchImageView.alpha = 0
        }) { _ in
            self.scratchImageView.removeFromSuperview()
            // Extend the delay before showing the alert.
            DispatchQueue.main.asyncAfter(deadline: .now() + self.alertDelay) {
                self.presentPrizeAlert()
            }
        }
    }
    
    private func presentPrizeAlert() {
        // Award coins to the game view model
        gameViewModel?.addCoins(coinPrize)
        
        let alert = UIAlertController(title: "Congratulations!",
                                      message: "You Won \(self.coinPrize) Coins!",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Awesome!", style: .default, handler: { _ in
            self.launchConfetti()
            // Dismiss the scratch card after confetti
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.dismiss(animated: true)
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc private func closeTapped() {
        if scratchImageView.superview != nil {
            revealPrize()
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    // Programmatically generate a small colored square for confetti.
    private func createConfettiImage(color: UIColor, size: CGSize = CGSize(width: 8, height: 8)) -> CGImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            color.setFill()
            context.fill(rect)
        }
        return image.cgImage
    }
    
    private func launchConfetti() {
        let confettiLayer = CAEmitterLayer()
        confettiLayer.emitterPosition = CGPoint(x: view.bounds.midX, y: view.bounds.minY - 50)
        confettiLayer.emitterShape = .line
        confettiLayer.emitterSize = CGSize(width: view.bounds.size.width, height: 1)
        
        let colors: [UIColor] = [.systemRed, .systemBlue, .systemGreen, .systemOrange, .systemPurple, .systemYellow]
        var cells: [CAEmitterCell] = []
        for color in colors {
            let cell = CAEmitterCell()
            cell.birthRate = 3
            cell.lifetime = 8
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
}

// MARK: - Custom ScratchImageView

/// A UIImageView subclass that simulates a scratch-off effect by erasing parts of its cover image.
/// It draws into an offscreen image context for smoother performance.
class ScratchImageView: UIImageView {
    /// The number of brush strokes needed to trigger a full reveal.
    var threshold: Int = 50
    /// Called when the scratch threshold is reached.
    var onScratchThresholdReached: (() -> Void)?
    
    /// Internal counter for the number of scratch strokes.
    private var scratchCounter: Int = 0
    /// Brush size for erasing.
    private let brushSize: CGFloat = 30

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        // Generate a cover image (solid color; can be replaced with a pattern if desired).
        image = generateCoverImage()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isUserInteractionEnabled = true
        image = generateCoverImage()
    }
    
    /// Create the initial cover image.
    private func generateCoverImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)
        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(UIColor.lightGray.cgColor)
            context.fill(bounds)
            let img = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return img
        }
        return nil
    }
    
    // Update the cover image by “erasing” circles as the user moves their finger.
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        scratchAt(point: point)
    }
    
    /// Erases a circular area from the cover image at the given point.
    private func scratchAt(point: CGPoint) {
        let rect = CGRect(x: point.x - brushSize/2,
                          y: point.y - brushSize/2,
                          width: brushSize,
                          height: brushSize)
        
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)
        image?.draw(in: bounds)
        if let context = UIGraphicsGetCurrentContext() {
            context.setBlendMode(.clear)
            context.fillEllipse(in: rect)
        }
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.image = newImage
        
        scratchCounter += 1
        if scratchCounter >= threshold {
            onScratchThresholdReached?()
            scratchCounter = 0 // Reset to avoid multiple triggers.
        }
    }
}
