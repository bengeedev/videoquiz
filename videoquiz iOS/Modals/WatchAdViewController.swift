//
//  WatchAdViewController.swift
//  videoquiz iOS
//
//  Created by Benjamin Gievis on 07/03/2025.
//


import UIKit

class WatchAdViewController: UIViewController {
    
    // Reference to game view model for awarding coins
    private weak var gameViewModel: GameViewModel?
    
    private let adLabel: UILabel = {
        let label = UILabel()
        label.text = "Watching Ad..."
        label.textColor = .white
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let progressLabel: UILabel = {
        let label = UILabel()
        label.text = "5"
        label.textColor = .yellow
        label.font = .systemFont(ofSize: 34, weight: .heavy)
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
        button.isEnabled = false // disabled until the ad finishes
        return button
    }()
    
    private var countdown = 5
    private var timer: Timer?
    private var coinReward = 25 // Default coin reward for watching ad
    
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
        
        setupUI()
        startAdCountdown()
    }
    
    private func setupUI() {
        view.addSubview(adLabel)
        view.addSubview(progressLabel)
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            adLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            adLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),
            
            progressLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressLabel.topAnchor.constraint(equalTo: adLabel.bottomAnchor, constant: 20),
            
            closeButton.topAnchor.constraint(equalTo: progressLabel.bottomAnchor, constant: 40),
            closeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 120),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    }
    
    private func startAdCountdown() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] _ in
            guard let self = self else { return }
            self.countdown -= 1
            self.progressLabel.text = "\(self.countdown)"
            if self.countdown <= 0 {
                self.timer?.invalidate()
                self.timer = nil
                self.adLabel.text = "Ad Finished!"
                self.progressLabel.text = ""
                self.closeButton.isEnabled = true
                self.closeButton.backgroundColor = .systemGreen
                // Award coins for watching the ad
                self.gameViewModel?.addCoins(self.coinReward)
            }
        })
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Clean up timer if user closes early
        timer?.invalidate()
        timer = nil
    }
}
