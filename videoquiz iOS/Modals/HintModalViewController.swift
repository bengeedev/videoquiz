//
//  HintModalViewController.swift
//  Chef Quiz - 2025 iOS
//

import UIKit

class HintModalViewController: UIViewController {
    
    private weak var gameViewController: GameViewController?
    
    // Your hint array with cost
    private let hints = [
        ("remove-1-letter", "Remove 1 Letter", 30),
        ("remove-2-letters", "Remove 2 Letters", 50),
        ("reveal-1-letter", "Reveal 1 Letter", 50),
        ("reveal-2-letters", "Reveal 2 Letters", 80),
        ("skip-level", "Skip Level", 500)
    ]
    
    // UI elements
    private let wandIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "wand.and.stars"))
        imageView.tintColor = .systemYellow
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Hints"
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
    
    // Collection view for hints
    private let hintCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "HintCell")
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = true  // Ensure scrolling is enabled
        return collectionView
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
    
    init(gameViewController: GameViewController) {
        self.gameViewController = gameViewController
        super.init(nibName: nil, bundle: nil)
    }
    
    // Required init
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // -------------------------------------
    // MARK: - View Lifecycle
    // -------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // Assign dataSource & delegate
        hintCollectionView.dataSource = self
        hintCollectionView.delegate = self
        
        print("🎯 Collection view setup complete")
        print("🎯 Hints array: \(hints)")
        
        // Add tap gesture for hint selection
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hintTapped(_:)))
        hintCollectionView.addGestureRecognizer(tapGesture)
        
        // Dismiss button action
        dismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
    }
    
    private func setupUI() {
        // Glass-morphism background
        view.backgroundColor = .clear
        
        // Add blur background
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blurView)
        
        // Top content stack (icon, title, buttons)
        let topStackView = UIStackView(arrangedSubviews: [wandIcon, titleLabel, hintCollectionView])
        topStackView.axis = .vertical
        topStackView.spacing = 15
        topStackView.alignment = .fill
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
            
            wandIcon.heightAnchor.constraint(equalToConstant: 40),
            
            // Ensure collection view has enough space for all buttons
            hintCollectionView.heightAnchor.constraint(greaterThanOrEqualToConstant: 350)
        ])
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
    
    // -------------------------------------
    // MARK: - Tap Gesture Handling
    // -------------------------------------
    @objc private func hintTapped(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: hintCollectionView)
        guard let indexPath = hintCollectionView.indexPathForItem(at: point),
              let vm = gameViewController?.viewModel else { return }
        
        let (key, _, cost) = hints[indexPath.row]
        switch key {
        case "remove-1-letter":
            let result = vm.tryRemoveIncorrectLetters(amount: 1, cost: cost)
            if result.success {
                // Track hint usage for achievements
                vm.trackHintUsage()
                
                dismiss(animated: true) {
                    self.gameViewController?.animateRemoveLetters(result.removedIndices)
                }
            }
        case "remove-2-letters":
            let result = vm.tryRemoveIncorrectLetters(amount: 2, cost: cost)
            if result.success {
                // Track hint usage for achievements
                vm.trackHintUsage()
                
                dismiss(animated: true) {
                    self.gameViewController?.animateRemoveLetters(result.removedIndices)
                }
            }
        case "reveal-1-letter", "reveal-2-letters":
            let amount = (key == "reveal-1-letter") ? 1 : 2
            // Use the *animated* version to get the "flying tile" effect:
            if let revealData = vm.tryRevealLettersAnimated(amount: amount, cost: cost) {
                // Track hint usage for achievements
                vm.trackHintUsage()
                
                dismiss(animated: true) {
                    self.gameViewController?.animateRevealLetters(revealData)
                }
            } else {
                print("Not enough coins or reveal failed.")
            }
        case "skip-level":
            if vm.trySkipLevel(cost: cost) {
                dismiss(animated: true)
            }
        default:
            break
        }
    }
}

// ---------------------------------------------------
// MARK: - UICollectionViewDataSource & Delegate Flow
// ---------------------------------------------------
extension HintModalViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("🎯 Number of hints: \(hints.count)")
        return hints.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HintCell", for: indexPath)
        
        // Clear previous subviews
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        
        print("🎯 Creating hint cell for index \(indexPath.row)")
        
        let (key, title, cost) = hints[indexPath.row]
        
        // Label to display the hint title and cost
        let label = UILabel()
        label.text = "\(title) (\(cost))"
        label.textAlignment = .center
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOffset = CGSize(width: 0, height: 1)
        label.layer.shadowRadius = 2
        label.layer.shadowOpacity = 0.5
        label.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(label)
        
        // Add constraints to center the label
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: cell.contentView.leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(lessThanOrEqualTo: cell.contentView.trailingAnchor, constant: -10)
        ])
        
        // Determine if this hint is available
        let canUse = isHintEnabled(key: key, cost: cost)
        cell.contentView.alpha = 1.0  // Keep full opacity for visibility
        cell.isUserInteractionEnabled = canUse
        
        // Glass-morphism styling for hint cells
        if canUse {
            cell.contentView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.8)
            cell.contentView.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.6).cgColor
            label.textColor = .white
        } else {
            cell.contentView.backgroundColor = UIColor.gray.withAlphaComponent(0.6)  // More visible gray
            cell.contentView.layer.borderColor = UIColor.gray.withAlphaComponent(0.4).cgColor
            label.textColor = .white.withAlphaComponent(0.7)  // Slightly dimmed text
        }
        
        print("🎯 Hint \(indexPath.row): \(title) - Available: \(canUse)")
        
        cell.contentView.layer.cornerRadius = 12
        cell.contentView.layer.borderWidth = 1
        cell.contentView.layer.shadowColor = UIColor.black.cgColor
        cell.contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cell.contentView.layer.shadowRadius = 8
        cell.contentView.layer.shadowOpacity = 0.3
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Single-column layout, full width minus some insets
        let width = collectionView.bounds.width - 40
        return CGSize(width: width, height: 60)  // Increased height for better visibility
    }
    
    // Helper to see if a hint is usable
    private func isHintEnabled(key: String, cost: Int) -> Bool {
        guard let vm = gameViewController?.viewModel else { return false }
        
        // Check coins first
        if vm.coins < cost { return false }
        
        // Then check if the hint is actually possible
        switch key {
        case "remove-1-letter":
            return vm.canRemoveIncorrectLetters(amount: 1)
        case "remove-2-letters":
            return vm.canRemoveIncorrectLetters(amount: 2)
        case "reveal-1-letter":
            return vm.canRevealLetters(amount: 1)
        case "reveal-2-letters":
            return vm.canRevealLetters(amount: 2)
        case "skip-level":
            return true
        default:
            return false
        }
    }
}
