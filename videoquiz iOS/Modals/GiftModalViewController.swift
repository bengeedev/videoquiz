//
//  GiftModalViewController.swift
//  VideoQuiz iOS
//
//  Created by Benjamin Gievis
//

import UIKit

class GiftModalViewController: UIViewController {
    private weak var gameViewController: GameViewController?
    
    // UI Elements
    private let giftIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "gift.circle.fill"))
        imageView.tintColor = .systemPink // Matches the gift button tint
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Gift Coins"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let spinWheelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Spin Wheel", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = UIColor(red: 0.1, green: 0.4, blue: 0.1, alpha: 1.0) // Dark green
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        // Add shadow
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        return button
    }()
    
    private let scratchGameButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Scratch Game", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = UIColor(red: 0.1, green: 0.4, blue: 0.1, alpha: 1.0) // Dark green
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        // Add shadow
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        return button
    }()
    
    private let watchAdButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Watch Ad", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = UIColor(red: 0.1, green: 0.4, blue: 0.1, alpha: 1.0) // Dark green
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        // Add shadow
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        return button
    }()
    
    private let closeLabel: UILabel = {
        let label = UILabel()
        label.text = "Close"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textColor = .white
        label.isUserInteractionEnabled = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    init(gameViewController: GameViewController) {
        self.gameViewController = gameViewController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        
        // Add highlight effect to buttons
        [spinWheelButton, scratchGameButton, watchAdButton].forEach { button in
            button.addTarget(self, action: #selector(buttonPressed), for: .touchDown)
            button.addTarget(self, action: #selector(buttonReleased), for: [.touchUpInside, .touchUpOutside])
        }
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 1.0) // Dark blue-gray
        
        let stackView = UIStackView(arrangedSubviews: [giftIcon, titleLabel, spinWheelButton, scratchGameButton, watchAdButton, closeLabel])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            giftIcon.widthAnchor.constraint(equalToConstant: 100),
            giftIcon.heightAnchor.constraint(equalToConstant: 100),
            
            spinWheelButton.widthAnchor.constraint(equalToConstant: 220),
            spinWheelButton.heightAnchor.constraint(equalToConstant: 50),
            scratchGameButton.widthAnchor.constraint(equalToConstant: 220),
            scratchGameButton.heightAnchor.constraint(equalToConstant: 50),
            watchAdButton.widthAnchor.constraint(equalToConstant: 220),
            watchAdButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupActions() {
        spinWheelButton.addTarget(self, action: #selector(spinWheelTapped), for: .touchUpInside)
        scratchGameButton.addTarget(self, action: #selector(scratchGameTapped), for: .touchUpInside)
        watchAdButton.addTarget(self, action: #selector(watchAdTapped), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(closeTapped))
        closeLabel.addGestureRecognizer(tapGesture)
    }
    
    @objc private func buttonPressed(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }
    
    @objc private func buttonReleased(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = .identity
        }
    }
    
    // Mini-Game: Spin the Wheel
    @objc private func spinWheelTapped() {
        let spinVC = SpinWheelViewController(gameViewModel: gameViewController?.viewModel)
        spinVC.modalPresentationStyle = .overFullScreen
        present(spinVC, animated: true)
    }
    
    // Mini-Game: Scratch Card
    @objc private func scratchGameTapped() {
        let scratchVC = ScratchCardViewController(gameViewModel: gameViewController?.viewModel)
        scratchVC.modalPresentationStyle = .overFullScreen
        present(scratchVC, animated: true)
    }
    
    // Mini-Game: Watch Ad
    @objc private func watchAdTapped() {
        let watchAdVC = WatchAdViewController(gameViewModel: gameViewController?.viewModel)
        watchAdVC.modalPresentationStyle = .overFullScreen
        present(watchAdVC, animated: true)
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}

