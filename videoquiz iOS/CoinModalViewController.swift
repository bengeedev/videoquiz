//
//  CoinModalViewController.swift
//  Chef Quiz - 2025 iOS
//

import UIKit

class CoinModalViewController: UIViewController {

    // We keep a reference to the GameViewModel so we can adjust global coins.
    private weak var gameViewModel: GameViewModel?
    
    // If you want to display the coin count when this modal opens,
    // you can pass it in or just use `gameViewModel?.coins` at runtime.
    private let initialCoinCount: Int
    
    // MARK: - UI Elements
    
    private let coinIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "centsign.circle.fill"))
        imageView.tintColor = .systemYellow
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let coinsTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Coins"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 28, weight: .semibold)
        label.textColor = .white
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOffset = CGSize(width: 0, height: 2)
        label.layer.shadowRadius = 4
        label.layer.shadowOpacity = 0.5
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    
    // Example purchase buttons (mock IAP). Each one calls `gameViewModel?.addCoins(...)`.
    
    private let buy100Button: UIButton = {
        return CoinModalViewController.createPurchaseButton(coinAmount: "100", price: "$0.99")
    }()
    
    private let buy250Button: UIButton = {
        return CoinModalViewController.createPurchaseButton(coinAmount: "250", price: "$2.49")
    }()
    
    private let buy500Button: UIButton = {
        return CoinModalViewController.createPurchaseButton(coinAmount: "500", price: "$4.99")
    }()
    
    private let buy1000Button: UIButton = {
        return CoinModalViewController.createPurchaseButton(coinAmount: "1000", price: "$9.99")
    }()
    
    private let buy2500Button: UIButton = {
        return CoinModalViewController.createPurchaseButton(coinAmount: "2500", price: "$19.99")
    }()
    
    // Optional “Remove Ads” button (fake IAP example):
    private let removeAdsButton: UIButton = {
        return CoinModalViewController.createPurchaseButton(coinAmount: "Remove Ads", price: "$1.99")
    }()
    
    private let dismissButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Close", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.systemRed.withAlphaComponent(0.8)
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemRed.withAlphaComponent(0.6).cgColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 8
        button.layer.shadowOpacity = 0.3
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Helper Functions
    
    private static func createPurchaseButton(coinAmount: String, price: String) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.8)
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGreen.withAlphaComponent(0.6).cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        // Enhanced shadow for glass effect
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 8
        
        // Create custom layout with coin amount and price
        let coinLabel = UILabel()
        coinLabel.text = coinAmount
        coinLabel.font = .systemFont(ofSize: 28, weight: .bold)
        coinLabel.textColor = .white
        coinLabel.textAlignment = .left
        
        let coinsTextLabel = UILabel()
        coinsTextLabel.text = "coins"
        coinsTextLabel.font = .systemFont(ofSize: 16, weight: .medium)
        coinsTextLabel.textColor = .white.withAlphaComponent(0.8)
        coinsTextLabel.textAlignment = .left
        
        let priceLabel = UILabel()
        priceLabel.text = price
        priceLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        priceLabel.textColor = .white
        priceLabel.textAlignment = .right
        
        let coinStack = UIStackView(arrangedSubviews: [coinLabel, coinsTextLabel])
        coinStack.axis = .horizontal
        coinStack.alignment = .center
        coinStack.spacing = 4
        
        let mainStack = UIStackView(arrangedSubviews: [coinStack, priceLabel])
        mainStack.axis = .horizontal
        mainStack.distribution = .equalSpacing
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        button.addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -20),
            mainStack.centerYAnchor.constraint(equalTo: button.centerYAnchor)
        ])
        
        return button
    }
    
    // MARK: - Init
    
    init(coinCount: Int, viewModel: GameViewModel) {
        self.initialCoinCount = coinCount
        self.gameViewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    // Or remove coinCount from init if you prefer just gameViewModel?.coins directly.
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // Coin count removed to prevent overlap with close button
        
        // Add button targets
        buy100Button.addTarget(self, action: #selector(buy100Tapped), for: .touchUpInside)
        buy250Button.addTarget(self, action: #selector(buy250Tapped), for: .touchUpInside)
        buy500Button.addTarget(self, action: #selector(buy500Tapped), for: .touchUpInside)
        buy1000Button.addTarget(self, action: #selector(buy1000Tapped), for: .touchUpInside)
        buy2500Button.addTarget(self, action: #selector(buy2500Tapped), for: .touchUpInside)
        removeAdsButton.addTarget(self, action: #selector(removeAdsTapped), for: .touchUpInside)
        dismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        
        // Add a "pressed" highlight effect
        let purchaseButtons = [buy100Button, buy250Button, buy500Button, buy1000Button, buy2500Button, removeAdsButton]
        purchaseButtons.forEach { button in
            button.addTarget(self, action: #selector(buttonPressed), for: .touchDown)
            button.addTarget(self, action: #selector(buttonReleased), for: [.touchUpInside, .touchUpOutside])
        }
    }
    
    private func setupUI() {
        // Glass-morphism background
        view.backgroundColor = .clear
        
        // Add blur background
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blurView)
        
        // Top content stack (icon, title, coin count, purchase buttons)
        let topStackView = UIStackView(arrangedSubviews: [
            coinIcon,
            coinsTitleLabel,
            buy100Button,
            buy250Button,
            buy500Button,
            buy1000Button,
            buy2500Button,
            removeAdsButton
        ])
        topStackView.axis = .vertical
        topStackView.spacing = 15
        topStackView.alignment = .center
        topStackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(topStackView)
        view.addSubview(dismissButton)
        
        NSLayoutConstraint.activate([
            // Blur background fills entire view
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Top content stack positioned at top
            topStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            topStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            topStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            
            // Close button positioned at bottom
            dismissButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            dismissButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dismissButton.widthAnchor.constraint(equalToConstant: 120),
            dismissButton.heightAnchor.constraint(equalToConstant: 50),
            
            coinIcon.widthAnchor.constraint(equalToConstant: 60),
            coinIcon.heightAnchor.constraint(equalToConstant: 60),
            
            buy100Button.widthAnchor.constraint(equalTo: topStackView.widthAnchor),
            buy100Button.heightAnchor.constraint(equalToConstant: 70),
            buy250Button.widthAnchor.constraint(equalTo: topStackView.widthAnchor),
            buy250Button.heightAnchor.constraint(equalToConstant: 70),
            buy500Button.widthAnchor.constraint(equalTo: topStackView.widthAnchor),
            buy500Button.heightAnchor.constraint(equalToConstant: 70),
            buy1000Button.widthAnchor.constraint(equalTo: topStackView.widthAnchor),
            buy1000Button.heightAnchor.constraint(equalToConstant: 70),
            buy2500Button.widthAnchor.constraint(equalTo: topStackView.widthAnchor),
            buy2500Button.heightAnchor.constraint(equalToConstant: 70),
            removeAdsButton.widthAnchor.constraint(equalTo: topStackView.widthAnchor),
            removeAdsButton.heightAnchor.constraint(equalToConstant: 70)
        ])
    }
    
    // MARK: - Button Actions
    
    @objc private func buttonPressed(_ sender: UIButton) {
        // Simple shrink animation on touch-down
        UIView.animate(withDuration: 0.1) {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }
    
    @objc private func buttonReleased(_ sender: UIButton) {
        // Restore the button's transform
        UIView.animate(withDuration: 0.1) {
            sender.transform = .identity
        }
    }
    
    @objc private func buy100Tapped() {
        print("Fake purchase: Buy 100 coins")
        gameViewModel?.addCoins(100)  // Global coin method in your GameViewModel
        dismiss(animated: true)
    }
    
    @objc private func buy250Tapped() {
        print("Fake purchase: Buy 250 coins")
        gameViewModel?.addCoins(250)
        dismiss(animated: true)
    }
    
    @objc private func buy500Tapped() {
        print("Fake purchase: Buy 500 coins")
        gameViewModel?.addCoins(500)
        dismiss(animated: true)
    }
    
    @objc private func buy1000Tapped() {
        print("Fake purchase: Buy 1000 coins")
        gameViewModel?.addCoins(1000)
        dismiss(animated: true)
    }
    
    @objc private func buy2500Tapped() {
        print("Fake purchase: Buy 2500 coins")
        gameViewModel?.addCoins(2500)
        dismiss(animated: true)
    }
    
    @objc private func removeAdsTapped() {
        print("Fake purchase: Remove Ads")
        // If removing ads doesn't affect coins, do nothing besides closing
        dismiss(animated: true)
    }
    
    @objc private func dismissTapped() {
        // Add subtle tap animation
        UIView.animate(withDuration: 0.1, animations: {
            self.dismissButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.dismissButton.transform = .identity
            }
        }
        
        dismiss(animated: true)
    }
}
