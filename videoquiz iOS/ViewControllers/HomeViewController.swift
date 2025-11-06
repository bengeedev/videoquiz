//
//  HomeViewController.swift
//  VideoQuiz iOS
//
//  Created by Benjamin Gievis
//

import UIKit

class HomeViewController: UIViewController {

    // MARK: - Properties

    private var themes: [Theme] = []
    private var categorizedThemes: [String: [Theme]] = [:]
    private var categoryOrder: [String] = []
    private var filteredThemes: [Theme] = []
    private var eventThemes: [Theme] = []  // Featured event themes for hero banner

    // Filter options
    enum FilterOption {
        case home
        case category(String)
        case new
        case recentlyPlayed
    }

    private var selectedFilter: FilterOption = .home
    private var availableFilters: [FilterOption] = [.home]

    // MARK: - UI Elements

    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let hamburgerButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "line.3.horizontal"), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Video Quiz"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let coinView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        view.layer.cornerRadius = 18
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let coinIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "dollarsign.circle.fill")
        imageView.tintColor = .systemYellow
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let coinLabel: UILabel = {
        let label = UILabel()
        label.text = "0"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var chipMenuCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.showsHorizontalScrollIndicator = false
        cv.contentInsetAdjustmentBehavior = .never
        return cv
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = createCompositionalLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.showsVerticalScrollIndicator = false
        cv.contentInsetAdjustmentBehavior = .never
        return cv
    }()

    // Side menu
    private let sideMenuViewController = SideMenuViewController()
    private var isSideMenuVisible = false
    private let sideMenuWidth: CGFloat = 280

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        setupSideMenu()
        setupActions()
        loadThemes()
        updateCoins()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        loadThemes()
        updateCoins()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)

        view.addSubview(collectionView)
        view.addSubview(chipMenuCollectionView)
        view.addSubview(headerView)
        headerView.addSubview(hamburgerButton)
        headerView.addSubview(titleLabel)
        headerView.addSubview(coinView)
        coinView.addSubview(coinIcon)
        coinView.addSubview(coinLabel)

        NSLayoutConstraint.activate([
            // Header
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),

            // Hamburger button
            hamburgerButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            hamburgerButton.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -15),
            hamburgerButton.widthAnchor.constraint(equalToConstant: 30),
            hamburgerButton.heightAnchor.constraint(equalToConstant: 30),

            // Title
            titleLabel.leadingAnchor.constraint(equalTo: hamburgerButton.trailingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: hamburgerButton.centerYAnchor),

            // Coin view
            coinView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            coinView.centerYAnchor.constraint(equalTo: hamburgerButton.centerYAnchor),
            coinView.heightAnchor.constraint(equalToConstant: 36),
            coinView.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),

            // Coin icon
            coinIcon.leadingAnchor.constraint(equalTo: coinView.leadingAnchor, constant: 8),
            coinIcon.centerYAnchor.constraint(equalTo: coinView.centerYAnchor),
            coinIcon.widthAnchor.constraint(equalToConstant: 24),
            coinIcon.heightAnchor.constraint(equalToConstant: 24),

            // Coin label
            coinLabel.leadingAnchor.constraint(equalTo: coinIcon.trailingAnchor, constant: 6),
            coinLabel.trailingAnchor.constraint(equalTo: coinView.trailingAnchor, constant: -12),
            coinLabel.centerYAnchor.constraint(equalTo: coinView.centerYAnchor),

            // Chip menu
            chipMenuCollectionView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            chipMenuCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chipMenuCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chipMenuCollectionView.heightAnchor.constraint(equalToConstant: 50),

            // Collection view
            collectionView.topAnchor.constraint(equalTo: chipMenuCollectionView.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupCollectionView() {
        // Chip menu setup
        chipMenuCollectionView.delegate = self
        chipMenuCollectionView.dataSource = self
        chipMenuCollectionView.register(ChipCell.self, forCellWithReuseIdentifier: "ChipCell")

        // Main collection view setup
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(HeroBannerCell.self, forCellWithReuseIdentifier: "HeroBannerCell")
        collectionView.register(ThemeCarouselCell.self, forCellWithReuseIdentifier: "ThemeCarouselCell")
        collectionView.register(ThemeGridCell.self, forCellWithReuseIdentifier: "ThemeGridCell")
        collectionView.register(SectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "SectionHeader")
    }

    private func setupSideMenu() {
        addChild(sideMenuViewController)
        view.addSubview(sideMenuViewController.view)
        sideMenuViewController.didMove(toParent: self)

        sideMenuViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sideMenuViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            sideMenuViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sideMenuViewController.view.widthAnchor.constraint(equalToConstant: sideMenuWidth),
            sideMenuViewController.view.trailingAnchor.constraint(equalTo: view.leadingAnchor)
        ])

        sideMenuViewController.delegate = self
    }

    private func setupActions() {
        hamburgerButton.addTarget(self, action: #selector(toggleSideMenu), for: .touchUpInside)
    }

    // MARK: - Compositional Layout

    private func createCompositionalLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self] (sectionIndex, environment) -> NSCollectionLayoutSection? in
            guard let self = self else { return nil }

            let screenWidth = environment.container.effectiveContentSize.width

            // Section 0: Hero Banner (if there are event themes)
            if sectionIndex == 0 && !self.eventThemes.isEmpty {
                return self.createHeroBannerSection(screenWidth: screenWidth)
            }

            // Regular category sections
            return self.createCategorySection(screenWidth: screenWidth)
        }

        return layout
    }

    private func createHeroBannerSection(screenWidth: CGFloat) -> NSCollectionLayoutSection {
        // Hero banner takes full width with padding
        let itemWidth = screenWidth - 40
        let itemHeight = itemWidth * 0.65 // Taller aspect ratio for hero banner

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .absolute(itemWidth),
            heightDimension: .absolute(itemHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(itemWidth),
            heightDimension: .absolute(itemHeight)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPaging
        section.interGroupSpacing = 16
        section.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 40, trailing: 20)

        return section
    }

    private func createCategorySection(screenWidth: CGFloat) -> NSCollectionLayoutSection {
        let itemWidth: CGFloat
        let itemHeight: CGFloat

        // Adaptive sizing for different devices
        if screenWidth > 400 {
            itemWidth = screenWidth * 0.75
            itemHeight = itemWidth * 0.56
        } else {
            itemWidth = screenWidth * 0.8
            itemHeight = itemWidth * 0.56
        }

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .absolute(itemWidth),
            heightDimension: .absolute(itemHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(itemWidth),
            heightDimension: .absolute(itemHeight)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPagingCentered
        section.interGroupSpacing = 16
        section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 32, trailing: 20)

        // Header
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(50)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section.boundarySupplementaryItems = [header]

        return section
    }

    // MARK: - Data Loading

    private func loadThemes() {
        themes = ThemeData.loadThemes()
        categorizeThemes()
        extractEventThemes()
        buildAvailableFilters()
        applyFilter(selectedFilter)

        print("📚 Loaded \(themes.count) themes")
        for (category, categoryThemes) in categorizedThemes {
            print("  - \(category): \(categoryThemes.count) themes")
        }
        if !eventThemes.isEmpty {
            print("🎉 Found \(eventThemes.count) event theme(s)")
        }
    }

    private func categorizeThemes() {
        categorizedThemes.removeAll()
        categoryOrder.removeAll()

        for theme in themes {
            let category = theme.mainCategory ?? "other"
            if categorizedThemes[category] == nil {
                categorizedThemes[category] = []
                categoryOrder.append(category)
            }
            categorizedThemes[category]?.append(theme)
        }

        // Sort categories: food -> animals -> science -> geography -> sports -> entertainment
        categoryOrder.sort { category1, category2 in
            let order = ["food": 0, "animals": 1, "science": 2, "geography": 3, "sports": 4, "entertainment": 5, "other": 99]
            return (order[category1] ?? 99) < (order[category2] ?? 99)
        }
    }

    private func extractEventThemes() {
        eventThemes = themes.filter { $0.isEvent }
    }

    private func buildAvailableFilters() {
        availableFilters = [.home]

        // Add category filters
        for category in categoryOrder {
            availableFilters.append(.category(category))
        }

        // Add special filters
        let hasNewThemes = themes.contains(where: { $0.isNew })
        if hasNewThemes {
            availableFilters.append(.new)
        }

        // TODO: Add recently played filter
        // availableFilters.append(.recentlyPlayed)

        chipMenuCollectionView.reloadData()
    }

    private func applyFilter(_ filter: FilterOption) {
        selectedFilter = filter

        switch filter {
        case .home:
            // Use horizontal carousels layout - no need to filter
            break

        case .category(let category):
            // Filter themes by category
            filteredThemes = themes.filter { $0.mainCategory == category }

        case .new:
            // Filter new themes
            filteredThemes = themes.filter { $0.isNew }

        case .recentlyPlayed:
            // TODO: Filter recently played themes
            filteredThemes = []
        }

        // Change layout by completely recreating the collection view layout
        let newLayout: UICollectionViewLayout

        switch filter {
        case .home:
            newLayout = createCompositionalLayout()
        default:
            newLayout = createGridLayout()
        }

        // Perform the layout transition safely
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.setCollectionViewLayout(newLayout, animated: false)
        collectionView.reloadData()
        chipMenuCollectionView.reloadData()

        // Select the appropriate chip in the chip menu
        if let index = availableFilters.firstIndex(where: { filtersAreEqual($0, selectedFilter) }) {
            chipMenuCollectionView.selectItem(at: IndexPath(item: index, section: 0), animated: false, scrollPosition: [])
        }
    }

    private func createGridLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 16
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)

        // 2 column grid
        let screenWidth = UIScreen.main.bounds.width
        let itemWidth = (screenWidth - 56) / 2  // 20 padding each side + 16 spacing
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth * 1.2)

        return layout
    }

    private func filterTitle(for filter: FilterOption) -> String {
        switch filter {
        case .home:
            return "Home"
        case .category(let category):
            return category.capitalized
        case .new:
            return "New"
        case .recentlyPlayed:
            return "Recently Played"
        }
    }

    private func updateCoins() {
        let coins = UserDefaults.standard.integer(forKey: "ChefQuizGlobalCoins")
        coinLabel.text = "\(coins)"
    }

    // MARK: - Actions

    @objc private func toggleSideMenu() {
        isSideMenuVisible.toggle()

        let targetPosition: CGFloat = isSideMenuVisible ? sideMenuWidth : 0

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.view.layoutIfNeeded()
            self.sideMenuViewController.view.transform = CGAffineTransform(translationX: targetPosition, y: 0)
            self.view.backgroundColor = self.isSideMenuVisible ? UIColor.black.withAlphaComponent(0.5) : UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
        }
    }

    private func themeSelected(_ theme: Theme) {
        // Close side menu if open
        if isSideMenuVisible {
            toggleSideMenu()
        }

        guard theme.isUnlocked else {
            showLockedThemeAlert()
            return
        }

        guard !theme.levels.isEmpty else {
            showNoLevelsAlert(themeName: theme.name)
            return
        }

        // Present game with selected theme
        let gameViewController = GameViewController()
        gameViewController.selectedTheme = theme
        gameViewController.modalPresentationStyle = .fullScreen
        present(gameViewController, animated: true)
    }

    private func showLockedThemeAlert() {
        let alert = UIAlertController(
            title: "Theme Locked",
            message: "Complete more levels to unlock this theme!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func showNoLevelsAlert(themeName: String) {
        let alert = UIAlertController(
            title: "No Levels Available",
            message: "The \(themeName) theme doesn't have any levels yet. Stay tuned!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UICollectionView DataSource & Delegate

extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if collectionView == chipMenuCollectionView {
            return 1
        }

        // Main collection view
        switch selectedFilter {
        case .home:
            // Add 1 section for hero banner if there are event themes
            let heroBannerSections = eventThemes.isEmpty ? 0 : 1
            return heroBannerSections + categoryOrder.count
        default:
            return 1  // Grid view has single section
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == chipMenuCollectionView {
            return availableFilters.count
        }

        // Main collection view
        switch selectedFilter {
        case .home:
            // Section 0 is hero banner if we have event themes
            if section == 0 && !eventThemes.isEmpty {
                return eventThemes.count
            }

            // Calculate actual category index
            let categoryIndex = eventThemes.isEmpty ? section : section - 1
            let category = categoryOrder[categoryIndex]
            return categorizedThemes[category]?.count ?? 0
        default:
            return filteredThemes.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == chipMenuCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChipCell", for: indexPath) as! ChipCell
            let filter = availableFilters[indexPath.item]
            cell.configure(with: filterTitle(for: filter))
            return cell
        }

        // Main collection view
        switch selectedFilter {
        case .home:
            // Section 0 is hero banner if we have event themes
            if indexPath.section == 0 && !eventThemes.isEmpty {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HeroBannerCell", for: indexPath) as! HeroBannerCell
                let theme = eventThemes[indexPath.item]
                cell.configure(with: theme)
                return cell
            }

            // Regular category sections
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ThemeCarouselCell", for: indexPath) as! ThemeCarouselCell
            let categoryIndex = eventThemes.isEmpty ? indexPath.section : indexPath.section - 1
            let category = categoryOrder[categoryIndex]
            if let theme = categorizedThemes[category]?[indexPath.item] {
                cell.configure(with: theme)
            }
            return cell

        default:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ThemeGridCell", for: indexPath) as! ThemeGridCell
            let theme = filteredThemes[indexPath.item]
            cell.configure(with: theme)
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "SectionHeader", for: indexPath) as! SectionHeaderView

        // Calculate actual category index (accounting for hero banner)
        let categoryIndex = (!eventThemes.isEmpty && indexPath.section > 0) ? indexPath.section - 1 : indexPath.section
        let category = categoryOrder[categoryIndex]
        let categoryTitle = category.capitalized.replacingOccurrences(of: "_", with: " ")
        header.configure(with: categoryTitle)

        return header
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == chipMenuCollectionView {
            let filter = availableFilters[indexPath.item]
            applyFilter(filter)
            return
        }

        // Main collection view
        let theme: Theme?
        switch selectedFilter {
        case .home:
            let category = categoryOrder[indexPath.section]
            theme = categorizedThemes[category]?[indexPath.item]
        default:
            theme = filteredThemes[indexPath.item]
        }

        if let theme = theme {
            themeSelected(theme)
        }
    }

    // Helper to compare filters (since FilterOption is an enum with associated values)
    private func filtersAreEqual(_ filter1: FilterOption, _ filter2: FilterOption) -> Bool {
        switch (filter1, filter2) {
        case (.home, .home):
            return true
        case (.category(let cat1), .category(let cat2)):
            return cat1 == cat2
        case (.new, .new):
            return true
        case (.recentlyPlayed, .recentlyPlayed):
            return true
        default:
            return false
        }
    }
}

// MARK: - SideMenuDelegate

extension HomeViewController: SideMenuDelegate {
    func sideMenuDidSelectSettings() {
        toggleSideMenu()
        print("Settings selected")
    }

    func sideMenuDidSelectGameCenter() {
        toggleSideMenu()
        print("Game Center selected")
    }

    func sideMenuDidSelectReset() {
        toggleSideMenu()
        showResetAlert()
    }

    private func showResetAlert() {
        let alert = UIAlertController(
            title: "Reset Game",
            message: "Are you sure you want to reset all progress? This cannot be undone.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { _ in
            self.resetGameData()
        })
        present(alert, animated: true)
    }

    private func resetGameData() {
        UserDefaults.standard.removeObject(forKey: "ChefQuizPuzzleState")
        UserDefaults.standard.removeObject(forKey: "ChefQuizGlobalCoins")
        UserDefaults.standard.removeObject(forKey: "VideoQuizCompletedLevels")
        UserDefaults.standard.synchronize()

        updateCoins()
        loadThemes()

        print("Game data has been reset.")
    }
}

// MARK: - Hero Banner Cell

class HeroBannerCell: UICollectionViewCell {

    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
        return view
    }()

    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.8).cgColor
        ]
        layer.locations = [0.4, 1.0]
        return layer
    }()

    private let eventBadge: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 1.0, green: 0.27, blue: 0.23, alpha: 1.0)
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let eventLabel: UILabel = {
        let label = UILabel()
        label.text = "FEATURED EVENT"
        label.font = .systemFont(ofSize: 11, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = .white
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.9)
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let levelCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .white.withAlphaComponent(0.8)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = backgroundImageView.bounds

        // Shadow
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.3
        containerView.layer.shadowOffset = CGSize(width: 0, height: 8)
        containerView.layer.shadowRadius = 16
        containerView.layer.masksToBounds = false
    }

    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(backgroundImageView)
        backgroundImageView.layer.addSublayer(gradientLayer)
        containerView.addSubview(eventBadge)
        eventBadge.addSubview(eventLabel)
        containerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(levelCountLabel)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            backgroundImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            eventBadge.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            eventBadge.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            eventBadge.heightAnchor.constraint(equalToConstant: 24),

            eventLabel.leadingAnchor.constraint(equalTo: eventBadge.leadingAnchor, constant: 12),
            eventLabel.trailingAnchor.constraint(equalTo: eventBadge.trailingAnchor, constant: -12),
            eventLabel.centerYAnchor.constraint(equalTo: eventBadge.centerYAnchor),

            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            iconImageView.bottomAnchor.constraint(equalTo: titleLabel.topAnchor, constant: -12),
            iconImageView.widthAnchor.constraint(equalToConstant: 48),
            iconImageView.heightAnchor.constraint(equalToConstant: 48),

            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            titleLabel.bottomAnchor.constraint(equalTo: descriptionLabel.topAnchor, constant: -8),

            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            descriptionLabel.bottomAnchor.constraint(equalTo: levelCountLabel.topAnchor, constant: -8),

            levelCountLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            levelCountLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
        ])
    }

    func configure(with theme: Theme) {
        titleLabel.text = theme.name
        descriptionLabel.text = theme.description
        iconImageView.image = UIImage(systemName: theme.icon)
        levelCountLabel.text = "\(theme.levels.count) levels"

        // Set placeholder background with theme color
        if let themeColor = UIColor(hex: theme.color) {
            containerView.backgroundColor = themeColor.withAlphaComponent(0.3)
            gradientLayer.colors = [
                themeColor.withAlphaComponent(0.5).cgColor,
                UIColor.black.withAlphaComponent(0.9).cgColor
            ]
            iconImageView.tintColor = themeColor
            setNeedsLayout()
        }
    }
}

// MARK: - Theme Carousel Cell

class ThemeCarouselCell: UICollectionViewCell {

    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
        return view
    }()

    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.7).cgColor
        ]
        layer.locations = [0.5, 1.0]
        return layer
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = .white
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.9)
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let levelCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .white.withAlphaComponent(0.8)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.progressTintColor = .white
        progressView.trackTintColor = UIColor.white.withAlphaComponent(0.3)
        progressView.layer.cornerRadius = 2
        progressView.clipsToBounds = true
        progressView.translatesAutoresizingMaskIntoConstraints = false
        return progressView
    }()

    private let newBadge: UILabel = {
        let label = UILabel()
        label.text = "NEW"
        label.font = .systemFont(ofSize: 11, weight: .black)
        label.textColor = .white
        label.backgroundColor = .systemRed
        label.textAlignment = .center
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    private let lockOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        view.layer.cornerRadius = 20
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    private let lockImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "lock.fill")
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = backgroundImageView.bounds

        // Add shadow
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.3
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 8
        containerView.layer.shadowPath = UIBezierPath(roundedRect: containerView.bounds, cornerRadius: 20).cgPath
    }

    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(backgroundImageView)
        backgroundImageView.layer.addSublayer(gradientLayer)
        containerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(levelCountLabel)
        containerView.addSubview(progressView)
        containerView.addSubview(newBadge)
        containerView.addSubview(lockOverlay)
        lockOverlay.addSubview(lockImageView)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            backgroundImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            iconImageView.bottomAnchor.constraint(equalTo: titleLabel.topAnchor, constant: -12),
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            titleLabel.bottomAnchor.constraint(equalTo: descriptionLabel.topAnchor, constant: -6),

            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            descriptionLabel.bottomAnchor.constraint(equalTo: levelCountLabel.topAnchor, constant: -8),

            levelCountLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            levelCountLabel.bottomAnchor.constraint(equalTo: progressView.topAnchor, constant: -6),

            progressView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            progressView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            progressView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            progressView.heightAnchor.constraint(equalToConstant: 4),

            newBadge.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            newBadge.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            newBadge.widthAnchor.constraint(equalToConstant: 50),
            newBadge.heightAnchor.constraint(equalToConstant: 24),

            lockOverlay.topAnchor.constraint(equalTo: containerView.topAnchor),
            lockOverlay.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            lockOverlay.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            lockOverlay.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            lockImageView.centerXAnchor.constraint(equalTo: lockOverlay.centerXAnchor),
            lockImageView.centerYAnchor.constraint(equalTo: lockOverlay.centerYAnchor),
            lockImageView.widthAnchor.constraint(equalToConstant: 50),
            lockImageView.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    func configure(with theme: Theme) {
        titleLabel.text = theme.name
        descriptionLabel.text = theme.description
        iconImageView.image = UIImage(systemName: theme.icon)
        levelCountLabel.text = "\(theme.levels.count) levels"
        progressView.progress = Float(theme.completionPercentage)
        lockOverlay.isHidden = theme.isUnlocked

        // Show NEW badge for recently added themes
        newBadge.isHidden = !theme.isNew

        // Set theme color for progress bar
        if let color = UIColor(hex: theme.color) {
            progressView.progressTintColor = color
        }

        // Load video thumbnail as background
        loadVideoThumbnail(for: theme)
    }

    private func loadVideoThumbnail(for theme: Theme) {
        // For now, use a gradient background based on theme color
        // TODO: Extract actual video thumbnail from first level
        setPlaceholderBackground(color: theme.color)
    }

    private func setPlaceholderBackground(color: String) {
        if let themeColor = UIColor(hex: color) {
            // Set background color directly on container for visibility
            containerView.backgroundColor = themeColor.withAlphaComponent(0.3)

            gradientLayer.colors = [
                themeColor.withAlphaComponent(0.6).cgColor,
                UIColor.black.withAlphaComponent(0.9).cgColor
            ]

            // Force redraw
            setNeedsLayout()
        }
    }
}

// MARK: - Section Header View

class SectionHeaderView: UICollectionReusableView {

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let seeAllButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("See All", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.tintColor = .white.withAlphaComponent(0.7)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true // Hide for now
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(titleLabel)
        addSubview(seeAllButton)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            seeAllButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            seeAllButton.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    func configure(with title: String) {
        titleLabel.text = title
    }
}

// MARK: - Side Menu Delegate Protocol

protocol SideMenuDelegate: AnyObject {
    func sideMenuDidSelectSettings()
    func sideMenuDidSelectGameCenter()
    func sideMenuDidSelectReset()
}

// MARK: - Side Menu View Controller

class SideMenuViewController: UIViewController {

    weak var delegate: SideMenuDelegate?

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1.0)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Menu"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let settingsButton: UIButton = {
        let button = createMenuButton(title: "Settings", icon: "gearshape.fill")
        return button
    }()

    private let gameCenterButton: UIButton = {
        let button = createMenuButton(title: "Game Center", icon: "gamecontroller.fill")
        return button
    }()

    private let resetButton: UIButton = {
        let button = createMenuButton(title: "Reset Progress", icon: "arrow.counterclockwise.circle.fill")
        button.tintColor = .systemRed
        return button
    }()

    private let ludobrosLabel: UILabel = {
        let label = UILabel()
        label.text = "Ludobros"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.7)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }

    private func setupUI() {
        view.addSubview(containerView)

        let stackView = UIStackView(arrangedSubviews: [
            settingsButton,
            gameCenterButton,
            resetButton
        ])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(titleLabel)
        containerView.addSubview(stackView)
        containerView.addSubview(ludobrosLabel)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            titleLabel.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),

            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),

            ludobrosLabel.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            ludobrosLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor)
        ])
    }

    private static func createMenuButton(title: String, icon: String) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.title = title
        config.image = UIImage(systemName: icon)
        config.imagePlacement = .leading
        config.imagePadding = 12
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        config.baseForegroundColor = .white

        let button = UIButton(configuration: config)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        button.contentHorizontalAlignment = .leading
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return button
    }

    private func setupActions() {
        settingsButton.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
        gameCenterButton.addTarget(self, action: #selector(gameCenterTapped), for: .touchUpInside)
        resetButton.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)
    }

    @objc private func settingsTapped() {
        delegate?.sideMenuDidSelectSettings()
    }

    @objc private func gameCenterTapped() {
        delegate?.sideMenuDidSelectGameCenter()
    }

    @objc private func resetTapped() {
        delegate?.sideMenuDidSelectReset()
    }
}

// MARK: - Chip Cell

class ChipCell: UICollectionViewCell {

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .white.withAlphaComponent(0.7)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        view.layer.cornerRadius = 18
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override var isSelected: Bool {
        didSet {
            updateAppearance()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    func configure(with title: String) {
        titleLabel.text = title
        updateAppearance()
    }

    private func updateAppearance() {
        if isSelected {
            // Active chip - use bright accent color
            containerView.backgroundColor = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0) // Bright blue
            titleLabel.textColor = .white
            titleLabel.font = .systemFont(ofSize: 15, weight: .bold)
        } else {
            // Inactive chip - subtle background
            containerView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
            titleLabel.textColor = .white.withAlphaComponent(0.7)
            titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        }
    }
}

// MARK: - Theme Grid Cell (for vertical grid view)

class ThemeGridCell: UICollectionViewCell {

    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        return view
    }()

    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.7).cgColor
        ]
        layer.locations = [0.3, 1.0]
        return layer
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .white
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let levelCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.8)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let newBadge: UILabel = {
        let label = UILabel()
        label.text = "NEW"
        label.font = .systemFont(ofSize: 10, weight: .black)
        label.textColor = .white
        label.backgroundColor = .systemRed
        label.textAlignment = .center
        label.layer.cornerRadius = 6
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    private let lockOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    private let lockImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "lock.fill")
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = containerView.bounds

        // Add shadow
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.2
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 4
    }

    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.layer.addSublayer(gradientLayer)
        containerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(levelCountLabel)
        containerView.addSubview(newBadge)
        containerView.addSubview(lockOverlay)
        lockOverlay.addSubview(lockImageView)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            iconImageView.widthAnchor.constraint(equalToConstant: 32),
            iconImageView.heightAnchor.constraint(equalToConstant: 32),

            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            titleLabel.bottomAnchor.constraint(equalTo: levelCountLabel.topAnchor, constant: -4),

            levelCountLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            levelCountLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),

            newBadge.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            newBadge.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            newBadge.widthAnchor.constraint(equalToConstant: 40),
            newBadge.heightAnchor.constraint(equalToConstant: 18),

            lockOverlay.topAnchor.constraint(equalTo: containerView.topAnchor),
            lockOverlay.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            lockOverlay.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            lockOverlay.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            lockImageView.centerXAnchor.constraint(equalTo: lockOverlay.centerXAnchor),
            lockImageView.centerYAnchor.constraint(equalTo: lockOverlay.centerYAnchor),
            lockImageView.widthAnchor.constraint(equalToConstant: 30),
            lockImageView.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    func configure(with theme: Theme) {
        titleLabel.text = theme.name
        iconImageView.image = UIImage(systemName: theme.icon)
        levelCountLabel.text = "\(theme.levels.count) levels"
        newBadge.isHidden = !theme.isNew
        lockOverlay.isHidden = theme.isUnlocked

        // Set theme color gradient
        if let themeColor = UIColor(hex: theme.color) {
            // Set background color for visibility
            containerView.backgroundColor = themeColor.withAlphaComponent(0.3)

            gradientLayer.colors = [
                themeColor.withAlphaComponent(0.6).cgColor,
                UIColor.black.withAlphaComponent(0.9).cgColor
            ]
            iconImageView.tintColor = themeColor

            // Force redraw
            setNeedsLayout()
        }
    }
}
