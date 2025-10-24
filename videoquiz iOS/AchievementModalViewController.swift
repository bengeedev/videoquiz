// AchievementModalViewController.swift
import UIKit

class AchievementModalViewController: UIViewController {
    private weak var gameViewModel: GameViewModel?
    
    // UI Elements
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Achievements"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let achievementTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(AchievementCell.self, forCellReuseIdentifier: AchievementCell.reuseIdentifier)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        return tableView
    }()
    
    private let dismissButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Close", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        button.setTitleColor(.white, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // Get achievements from AchievementManager
    private var achievements: [Achievement] {
        return AchievementManager.shared.getAllAchievements()
    }
    
    init(viewModel: GameViewModel) {
        self.gameViewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        achievementTableView.dataSource = self
        achievementTableView.delegate = self
        
        dismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 1.0) // Dark blue-gray
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, achievementTableView, dismissButton])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
            // Removed the heightAnchor constraint to allow dynamic sizing
        ])
    }
    
    @objc private func dismissTapped() {
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension AchievementModalViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return achievements.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AchievementCell.reuseIdentifier, for: indexPath) as? AchievementCell else {
            return UITableViewCell()
        }
        let achievement = achievements[indexPath.row]
        cell.configure(with: achievement.name, color: achievement.color, isUnlocked: achievement.isUnlocked)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}
