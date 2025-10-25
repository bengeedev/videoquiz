import UIKit

class GameToolbarView: UIView {
    
    let stackView = UIStackView()
    let buttonSize: CGFloat = 40
    let spacing: CGFloat = 10
    
    // Closure properties for button actions
    var onBackTapped: (() -> Void)?
    var onHintTapped: (() -> Void)?
    var onLevelTapped: (() -> Void)?
    var onCoinsTapped: (() -> Void)?
    var onGiftTapped: (() -> Void)?
    var onNextTapped: (() -> Void)?
    
    // MARK: - Initializers
    init() {
        super.init(frame: .zero)
        setupToolbar()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupToolbar()
    }
    
    // MARK: - Setup Toolbar
    private func setupToolbar() {
        backgroundColor = UIColor.black.withAlphaComponent(0.7)
        translatesAutoresizingMaskIntoConstraints = false
        
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = spacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: self.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        
        // Create buttons with tailored icon and background colors
        let backButton = createButton(
            systemName: "chevron.backward",
            tintColor: .systemPurple,
            backgroundColor: UIColor.systemPurple.withAlphaComponent(0.2)
        ) { [weak self] in
            self?.onBackTapped?()
        }
        let hintButton = createButton(
            systemName: "wand.and.stars",
            tintColor: .systemYellow,
            backgroundColor: UIColor.systemYellow.withAlphaComponent(0.2)
        ) { [weak self] in
            self?.onHintTapped?()
        }
        let levelButton = createButton(
            systemName: "trophy",
            tintColor: .systemCyan,
            backgroundColor: UIColor.systemCyan.withAlphaComponent(0.2)
        ) { [weak self] in
            self?.onLevelTapped?()
        }
        let coinButton = createButton(
            systemName: "centsign.circle",
            tintColor: .systemMint,
            backgroundColor: UIColor.systemMint.withAlphaComponent(0.2)
        ) { [weak self] in
            self?.onCoinsTapped?()
        }
        let giftButton = createButton(
            systemName: "giftcard",
            tintColor: .systemPink,
            backgroundColor: UIColor.systemPink.withAlphaComponent(0.2)
        ) { [weak self] in
            self?.onGiftTapped?()
        }
        let nextButton = createButton(
            systemName: "chevron.forward.circle",
            tintColor: .systemOrange,
            backgroundColor: UIColor.systemOrange.withAlphaComponent(0.2)
        ) { [weak self] in
            self?.onNextTapped?()
        }
        
        [backButton, hintButton, levelButton, coinButton, giftButton, nextButton].forEach {
            stackView.addArrangedSubview($0)
        }
    }
    
    private func createButton(systemName: String,
                              tintColor: UIColor,
                              backgroundColor: UIColor,
                              action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: systemName)?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.tintColor = tintColor
        button.backgroundColor = backgroundColor // Use the passed background color
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: buttonSize),
            button.heightAnchor.constraint(equalToConstant: buttonSize)
        ])
        
        button.addAction(UIAction(handler: { _ in action() }), for: .touchUpInside)
        return button
    }
}
