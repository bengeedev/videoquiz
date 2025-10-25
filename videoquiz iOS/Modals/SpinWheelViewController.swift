//
//  SpinWheelViewController.swift
//  VideoQuiz iOS
//
//  Created by Benjamin Gievis
//

import UIKit
import QuartzCore

// MARK: - SpinWheelView (Custom Wheel View)
class SpinWheelView: UIView {
    // Define 10 segments/prizes (as strings)
    var segments: [String] = ["0", "10", "20", "30", "40", "50", "60", "70", "80", "100"]
    // Define 10 segment colors (cycle or add more as desired)
    var segmentColors: [UIColor] = [
        .systemRed, .systemBlue, .systemGreen, .systemOrange, .systemPurple,
        .systemYellow, .systemPink, .systemTeal, .systemIndigo, .brown
    ]
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    private func commonInit() {
        backgroundColor = .clear
    }
    
    override func draw(_ rect: CGRect) {
        let centerPoint = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let segmentCount = segments.count
        let anglePerSegment = (2 * CGFloat.pi) / CGFloat(segmentCount)
        
        for i in 0..<segmentCount {
            // Calculate start and end angles for the segment
            let startAngle = anglePerSegment * CGFloat(i) - CGFloat.pi / 2
            let endAngle = startAngle + anglePerSegment
            
            // Draw the wedge for the segment
            let path = UIBezierPath()
            path.move(to: centerPoint)
            path.addArc(withCenter: centerPoint, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            path.close()
            
            // Fill segment with its color
            let color = segmentColors[i % segmentColors.count]
            color.setFill()
            path.fill()
            
            // Draw a white border for separation
            UIColor.white.setStroke()
            path.lineWidth = 2
            path.stroke()
            
            // Draw the prize text for the segment
            let text = segments[i]
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 16),
                .foregroundColor: UIColor.white
            ]
            let textSize = text.size(withAttributes: attributes)
            let midAngle = (startAngle + endAngle) / 2
            // Position the text at about 60% of the radius from the center
            let textRadius = radius * 0.6
            let textX = centerPoint.x + textRadius * cos(midAngle) - textSize.width / 2
            let textY = centerPoint.y + textRadius * sin(midAngle) - textSize.height / 2
            let textRect = CGRect(x: textX, y: textY, width: textSize.width, height: textSize.height)
            text.draw(in: textRect, withAttributes: attributes)
        }
        
        // Draw a circle in the middle
        let centerCirclePath = UIBezierPath(arcCenter: centerPoint, radius: radius * 0.15, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        UIColor.darkGray.setFill()
        centerCirclePath.fill()
        UIColor.white.setStroke()
        centerCirclePath.lineWidth = 2
        centerCirclePath.stroke()
    }
}

// MARK: - SpinWheelViewController
class SpinWheelViewController: UIViewController {
    
    // Reference to game view model for awarding coins
    private weak var gameViewModel: GameViewModel?
    
    // Our custom wheel view
    private let spinWheelView: SpinWheelView = {
        let wheel = SpinWheelView()
        wheel.translatesAutoresizingMaskIntoConstraints = false
        return wheel
    }()
    
    // Pointer view to indicate the winning segment
    private let pointerView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = .clear
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let spinButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("SPIN", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 24)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemPink
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // Label to display the spin result
    private let resultLabel: UILabel = {
        let label = UILabel()
        label.text = "Spin to win!"
        label.textColor = .white
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Close", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .darkGray
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // The possible prizes that match our wheel segments
    private let possiblePrizes = [0, 10, 20, 30, 40, 50, 60, 70, 80, 100]
    // Delay before showing the win overlay (seconds)
    private let overlayDelay: TimeInterval = 0.5
    // Is wheel currently spinning
    private var isSpinning = false
    
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
        setupLayout()
        createPointer()
        
        spinButton.addTarget(self, action: #selector(spinWheel), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        
        resetWheelPosition()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    private func resetWheelPosition() {
        // Reset wheel to starting position
        spinWheelView.transform = .identity
    }
    
    private func setupLayout() {
        // Container view for wheel and pointer - this helps with layout
        let wheelContainer = UIView()
        wheelContainer.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(wheelContainer)
        wheelContainer.addSubview(spinWheelView)
        wheelContainer.addSubview(pointerView)
        view.addSubview(spinButton)
        view.addSubview(resultLabel)
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            wheelContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            wheelContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            wheelContainer.widthAnchor.constraint(equalToConstant: 280),
            wheelContainer.heightAnchor.constraint(equalToConstant: 280),
            
            spinWheelView.centerXAnchor.constraint(equalTo: wheelContainer.centerXAnchor),
            spinWheelView.centerYAnchor.constraint(equalTo: wheelContainer.centerYAnchor),
            spinWheelView.widthAnchor.constraint(equalToConstant: 250),
            spinWheelView.heightAnchor.constraint(equalToConstant: 250),
            
            pointerView.centerXAnchor.constraint(equalTo: wheelContainer.centerXAnchor),
            pointerView.bottomAnchor.constraint(equalTo: wheelContainer.centerYAnchor),
            pointerView.widthAnchor.constraint(equalToConstant: 30),
            pointerView.heightAnchor.constraint(equalToConstant: 50),
            
            spinButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinButton.topAnchor.constraint(equalTo: wheelContainer.bottomAnchor, constant: 20),
            spinButton.widthAnchor.constraint(equalToConstant: 120),
            spinButton.heightAnchor.constraint(equalToConstant: 50),
            
            resultLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            resultLabel.bottomAnchor.constraint(equalTo: wheelContainer.topAnchor, constant: -10),
            resultLabel.widthAnchor.constraint(equalToConstant: 250),
            
            closeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            closeButton.topAnchor.constraint(equalTo: spinButton.bottomAnchor, constant: 20),
            closeButton.widthAnchor.constraint(equalToConstant: 120),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func createPointer() {
        // Draw a triangle pointer
        let pointerSize = CGSize(width: 30, height: 50)
        UIGraphicsBeginImageContextWithOptions(pointerSize, false, 0)
        
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.move(to: CGPoint(x: pointerSize.width/2, y: 0))
        ctx.addLine(to: CGPoint(x: pointerSize.width, y: pointerSize.height))
        ctx.addLine(to: CGPoint(x: 0, y: pointerSize.height))
        ctx.closePath()
        
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.fillPath()
        
        ctx.move(to: CGPoint(x: pointerSize.width/2, y: 0))
        ctx.addLine(to: CGPoint(x: pointerSize.width, y: pointerSize.height))
        ctx.addLine(to: CGPoint(x: 0, y: pointerSize.height))
        ctx.closePath()
        
        ctx.setStrokeColor(UIColor.black.cgColor)
        ctx.setLineWidth(2)
        ctx.strokePath()
        
        let pointerImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        pointerView.image = pointerImage
    }
    
    @objc private func spinWheel() {
        // Prevent multiple spins
        if isSpinning {
            return
        }
        
        isSpinning = true
        spinButton.isEnabled = false
        
        // Provide haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Fewer rotations for smoother feel
        let fullRotations = Int.random(in: 3...5) // Reduced from 6-12 to 3-5
        let randomFinalAngle = CGFloat.random(in: 0..<360) // Random final position in degrees
        let totalRotationDegrees = CGFloat(fullRotations) * 360 + randomFinalAngle
        let totalRotationRadians = totalRotationDegrees * .pi / 180
        
        print("🎡 Spinning: \(fullRotations) full rotations + \(randomFinalAngle)° = \(totalRotationDegrees)° total")
        print("📐 Total rotation in radians: \(totalRotationRadians)")
        print("🔄 That's \(totalRotationDegrees / 360) complete rotations")
        
        // Smoother animation with bounce effect
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.fromValue = 0
        rotationAnimation.toValue = totalRotationRadians
        rotationAnimation.duration = 4.0 // Longer duration for smoother feel
        rotationAnimation.timingFunction = CAMediaTimingFunction(controlPoints: 0.25, 0.1, 0.25, 1.0) // Custom easing for bounce
        rotationAnimation.fillMode = .forwards
        rotationAnimation.isRemovedOnCompletion = false
        
        // Add a subtle bounce effect at the end
        let bounceAnimation = CAKeyframeAnimation(keyPath: "transform.rotation")
        bounceAnimation.values = [
            0,
            totalRotationRadians * 0.8, // Slow down to 80%
            totalRotationRadians * 0.95, // Bounce back to 95%
            totalRotationRadians // Final position
        ]
        bounceAnimation.keyTimes = [0, 0.7, 0.85, 1.0] // Timing for bounce
        bounceAnimation.duration = 4.0
        bounceAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        bounceAnimation.fillMode = .forwards
        bounceAnimation.isRemovedOnCompletion = false
        
        // Set the final transform
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            self.handleSpinComplete(finalAngle: randomFinalAngle)
        }
        
        spinWheelView.layer.add(bounceAnimation, forKey: "bounceRotation")
        spinWheelView.transform = CGAffineTransform(rotationAngle: totalRotationRadians)
        
        CATransaction.commit()
    }
    
    private func handleSpinComplete(finalAngle: CGFloat) {
        // Calculate which segment the wheel landed on
        let segmentCount = self.spinWheelView.segments.count
        let segmentAngle = 360.0 / CGFloat(segmentCount) // Degrees per segment
        
        // Convert final angle to segment index (0-based)
        let normalizedAngle = finalAngle.truncatingRemainder(dividingBy: 360)
        let segmentIndex = Int(normalizedAngle / segmentAngle)
        
        // Get the prize
        let prize = self.possiblePrizes[segmentIndex]
        self.resultLabel.text = "Result: \(prize) coins"
        
        print("🎯 Wheel landed on segment \(segmentIndex) (angle: \(normalizedAngle)°), prize: \(prize)")
        
        // Show win overlay
        DispatchQueue.main.asyncAfter(deadline: .now() + self.overlayDelay) {
            self.showWinOverlay(prize: prize)
        }
        
        // Reset spinning state
        self.isSpinning = false
        self.spinButton.isEnabled = true
    }
    
    /// Displays a non‑blocking overlay with win information.
    private func showWinOverlay(prize: Int) {
        // Award coins to the game view model
        gameViewModel?.addCoins(prize)
        
        let overlay = UIView(frame: CGRect(x: 0, y: 0, width: 250, height: 100))
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        overlay.layer.cornerRadius = 10
        overlay.center = view.center
        
        let winLabel = UILabel(frame: overlay.bounds)
        winLabel.text = "You won \(prize) coins!"
        winLabel.textColor = .white
        winLabel.textAlignment = .center
        winLabel.font = .boldSystemFont(ofSize: 24)
        overlay.addSubview(winLabel)
        overlay.alpha = 0
        
        view.addSubview(overlay)
        
        // Animate the overlay in, pause, then fade out.
        UIView.animate(withDuration: 0.5, animations: {
            overlay.alpha = 1
        }, completion: { _ in
            UIView.animate(withDuration: 0.5, delay: 1.5, options: [], animations: {
                overlay.alpha = 0
            }, completion: { _ in
                overlay.removeFromSuperview()
                self.launchConfetti()
            })
        })
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    // MARK: - Confetti Animation
    
    /// Generates a small colored square image for confetti.
    private func createConfettiImage(color: UIColor, size: CGSize = CGSize(width: 8, height: 8)) -> CGImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            color.setFill()
            context.fill(rect)
        }
        return image.cgImage
    }
    
    /// Launches a colorful confetti animation using CAEmitterLayer.
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
        
        // Stop emitting confetti after 3 seconds.
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            confettiLayer.birthRate = 0
        }
    }
}
