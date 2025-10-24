//
//  VideoOverlayView.swift
//  Chef Quiz - 2025 iOS
//
//  Beautiful blurred transparent buttons for video overlay
//

import UIKit

class VideoOverlayView: UIView {
    
    // MARK: - Properties
    private let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
    private let blurView = UIVisualEffectView()
    private let stackView = UIStackView()
    
    // Button actions
    var onBackTapped: (() -> Void)?
    var onHintTapped: (() -> Void)?
    var onLevelTapped: (() -> Void)?
    var onCoinsTapped: (() -> Void)?
    var onGiftTapped: (() -> Void)?
    var onNextTapped: (() -> Void)?
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupOverlay()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupOverlay()
    }
    
    // MARK: - Setup
    private func setupOverlay() {
        backgroundColor = .clear  // Transparent background
        translatesAutoresizingMaskIntoConstraints = false
        
        // Setup stack view directly (no blur background)
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stackView)
        
        // Ensure the view is visible
        alpha = 1.0
        isHidden = false
        
        // Constraints
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        createButtons()
    }
    
    private func createButtons() {
        // Back button
        let backButton = createBlurredButton(
            systemName: "chevron.backward",
            tintColor: .systemPurple,
            action: { [weak self] in self?.onBackTapped?() }
        )
        
        // Hint button
        let hintButton = createBlurredButton(
            systemName: "wand.and.stars",
            tintColor: .systemYellow,
            action: { [weak self] in self?.onHintTapped?() }
        )
        
        // Level button
        let levelButton = createBlurredButton(
            systemName: "trophy",
            tintColor: .systemCyan,
            action: { [weak self] in self?.onLevelTapped?() }
        )
        
        // Coins button
        let coinButton = createBlurredButton(
            systemName: "centsign.circle",
            tintColor: .systemMint,
            action: { [weak self] in self?.onCoinsTapped?() }
        )
        
        // Gift button
        let giftButton = createBlurredButton(
            systemName: "giftcard",
            tintColor: .systemPink,
            action: { [weak self] in self?.onGiftTapped?() }
        )
        
        // Next button
        let nextButton = createBlurredButton(
            systemName: "chevron.forward.circle",
            tintColor: .systemOrange,
            action: { [weak self] in self?.onNextTapped?() }
        )
        
        [backButton, hintButton, levelButton, coinButton, giftButton, nextButton].forEach {
            stackView.addArrangedSubview($0)
        }
    }
    
    private func createBlurredButton(systemName: String, tintColor: UIColor, action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        
        // Button icon
        let iconImage = UIImage(systemName: systemName)?.withRenderingMode(.alwaysTemplate)
        button.setImage(iconImage, for: .normal)
        button.tintColor = tintColor
        
        // Enhanced button styling for visibility
        button.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = tintColor.withAlphaComponent(0.6).cgColor
        
        // Enhanced shadow effect for better visibility
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 3)
        button.layer.shadowRadius = 10
        button.layer.shadowOpacity = 0.5
        
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Constraints
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 44),
            button.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Action
        button.addAction(UIAction(handler: { _ in action() }), for: .touchUpInside)
        
        // Haptic feedback
        button.addAction(UIAction(handler: { _ in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }), for: .touchDown)
        
        return button
    }
    
    // MARK: - Animation Methods
    func showOverlay(animated: Bool = true) {
        if animated {
            alpha = 0
            transform = CGAffineTransform(translationX: 0, y: 20)
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
                self.alpha = 1
                self.transform = .identity
            }
        } else {
            alpha = 1
            transform = .identity
        }
    }
    
    func hideOverlay(animated: Bool = true) {
        if animated {
            UIView.animate(withDuration: 0.2) {
                self.alpha = 0
                self.transform = CGAffineTransform(translationX: 0, y: 20)
            }
        } else {
            alpha = 0
            transform = CGAffineTransform(translationX: 0, y: 20)
        }
    }
}

// MARK: - Coin Display Overlay
class CoinOverlayView: UIView {
    
    private let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
    private let blurView = UIVisualEffectView()
    private let coinLabel = UILabel()
    private let coinIcon = UIImageView()
    
    var coinCount: Int = 0 {
        didSet {
            coinLabel.text = "\(coinCount)"
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCoinOverlay()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCoinOverlay()
    }
    
    private func setupCoinOverlay() {
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false
        
        // Blur background
        blurView.effect = blurEffect
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.layer.cornerRadius = 16
        blurView.layer.masksToBounds = true
        
        // Coin icon
        coinIcon.image = UIImage(systemName: "centsign.circle.fill")
        coinIcon.tintColor = .systemYellow
        coinIcon.contentMode = .scaleAspectFit
        coinIcon.translatesAutoresizingMaskIntoConstraints = false
        
        // Coin label
        coinLabel.text = "0"
        coinLabel.textColor = .white
        coinLabel.font = .systemFont(ofSize: 16, weight: .bold)
        coinLabel.textAlignment = .center
        coinLabel.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(blurView)
        blurView.contentView.addSubview(coinIcon)
        blurView.contentView.addSubview(coinLabel)
        
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            coinIcon.leadingAnchor.constraint(equalTo: blurView.leadingAnchor, constant: 8),
            coinIcon.centerYAnchor.constraint(equalTo: blurView.centerYAnchor),
            coinIcon.widthAnchor.constraint(equalToConstant: 20),
            coinIcon.heightAnchor.constraint(equalToConstant: 20),
            
            coinLabel.leadingAnchor.constraint(equalTo: coinIcon.trailingAnchor, constant: 6),
            coinLabel.trailingAnchor.constraint(equalTo: blurView.trailingAnchor, constant: -8),
            coinLabel.centerYAnchor.constraint(equalTo: blurView.centerYAnchor)
        ])
        
        // Shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 8
        layer.shadowOpacity = 0.3
    }
    
    func updateCoins(_ count: Int, animated: Bool = true) {
        coinCount = count
        
        if animated {
            UIView.animate(withDuration: 0.2, animations: {
                self.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            }) { _ in
                UIView.animate(withDuration: 0.2) {
                    self.transform = .identity
                }
            }
        }
    }
}