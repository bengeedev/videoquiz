//
//  MenuViewController.swift
//  VideoQuiz iOS
//
//  Created by Benjamin Gievis
//

import UIKit

class MenuViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5) // Translucent black overlay
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let chefQuizLabel: UILabel = {
        let label = UILabel()
        label.text = "Chef Quiz"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 48, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let playButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Play", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 24, weight: .medium)
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
    
    private let settingsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Settings", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 24, weight: .medium)
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
    
    private let gameCenterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "gamecontroller"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor(red: 0.1, green: 0.4, blue: 0.1, alpha: 1.0) // Dark green
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        // Add shadow
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        return button
    }()
    
    private let ludobrosLabel: UILabel = {
        let label = UILabel()
        label.text = "Ludobros"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let ludobrosLogo: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "ludobros-logo"))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    // MARK: - NEW: Reset Button
    private let resetButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Reset Game", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .medium)
        button.backgroundColor = UIColor(red: 0.5, green: 0.1, blue: 0.1, alpha: 1.0) // Reddish
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        // Shadow
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        setupBackgroundSlideshow()
        // Hide navigation bar for a clean look
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = .black // Default background; slideshow plus overlay will layer on top
        
        // We use a vertical stack for your main menu items
        let stackView = UIStackView(arrangedSubviews: [
            chefQuizLabel,
            playButton,
            settingsButton,
            gameCenterButton,
            ludobrosLabel,
            ludobrosLogo,
            // Insert the reset button at the bottom or wherever you want in the stack:
            resetButton
        ])
        stackView.axis = .vertical
        stackView.spacing = 30
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(backgroundImageView)
        view.addSubview(overlayView)
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // Buttons
            playButton.widthAnchor.constraint(equalToConstant: 200),
            playButton.heightAnchor.constraint(equalToConstant: 60),
            
            settingsButton.widthAnchor.constraint(equalToConstant: 200),
            settingsButton.heightAnchor.constraint(equalToConstant: 60),
            
            gameCenterButton.widthAnchor.constraint(equalToConstant: 60),
            gameCenterButton.heightAnchor.constraint(equalToConstant: 60),
            
            ludobrosLogo.widthAnchor.constraint(equalToConstant: 100),
            ludobrosLogo.heightAnchor.constraint(equalToConstant: 50),
            
            // Reset Button
            resetButton.widthAnchor.constraint(equalToConstant: 200),
            resetButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - Setup Actions
    private func setupActions() {
        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        settingsButton.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
        gameCenterButton.addTarget(self, action: #selector(gameCenterTapped), for: .touchUpInside)
        
        // NEW: Action for the Reset button
        resetButton.addTarget(self, action: #selector(resetGameDataTapped), for: .touchUpInside)
    }
    
    // MARK: - Background Slideshow (Placeholder)
    private func setupBackgroundSlideshow() {
        let images = ["carrot", "cat", "tree", "apple", "garden"] // Add more as needed
        var currentIndex = 0
        
        backgroundImageView.image = UIImage(named: images[currentIndex])
        
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            currentIndex = (currentIndex + 1) % images.count
            UIView.transition(with: self.backgroundImageView,
                              duration: 1.0,
                             options: .transitionCrossDissolve,
                             animations: {
                self.backgroundImageView.image = UIImage(named: images[currentIndex])
            })
        }
    }
    
    // MARK: - Button Methods
    @objc private func playTapped() {
        // Present the main game
        let gameViewController = GameViewController()
        gameViewController.modalPresentationStyle = .fullScreen
        present(gameViewController, animated: true)
    }
    
    @objc private func settingsTapped() {
        print("Settings tapped - Navigate to settings screen if desired.")
    }
    
    @objc private func gameCenterTapped() {
        print("Game Center tapped - Implement Game Center features here.")
    }
    
    // MARK: - NEW: Reset the Game
    @objc private func resetGameDataTapped() {
        let alert = UIAlertController(
            title: "Reset Game",
            message: "Are you sure you want to reset all progress? This cannot be undone.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { _ in
            self.resetGameData()
            let resetLabel = UILabel()
            resetLabel.text = "Game Reset!"
            resetLabel.textColor = .white
            resetLabel.backgroundColor = UIColor.black.withAlphaComponent(0.8)
            resetLabel.textAlignment = .center
            resetLabel.frame = CGRect(x: 0, y: 0, width: 120, height: 40)
            resetLabel.center = self.view.center
            resetLabel.layer.cornerRadius = 10
            resetLabel.clipsToBounds = true
            self.view.addSubview(resetLabel)
            
            UIView.animate(withDuration: 1.0, animations: {
                resetLabel.alpha = 0
            }) { _ in
                resetLabel.removeFromSuperview()
            }
        })
        present(alert, animated: true)
    }
    
    private func resetGameData() {
        // Remove persisted puzzle state
        UserDefaults.standard.removeObject(forKey: "ChefQuizPuzzleState")
        // Remove global coins data if needed
        UserDefaults.standard.removeObject(forKey: "ChefQuizGlobalCoins")
        UserDefaults.standard.synchronize()
        
        print("Game data has been reset. The next time you press Play, it starts from Level 1 with default coin balance.")
    }

}
