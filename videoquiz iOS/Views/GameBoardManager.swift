//
//  GameBoardManager.swift
//  Chef Quiz - 2025 iOS
//
//  Created by Benjamin Gievis on 03/03/2025
//

import UIKit

class GameBoardManager {
    
    // ---------------------------
    // MARK: - Internal Properties
    // ---------------------------
    
    var onKeyboardUpdateNeeded: (() -> Void)? // Callback to refresh keyboard UI
    
    // Expose `originalTargetWord` so GameViewModel can read/write it.
    var originalTargetWord: String = ""
    
    /// Current guess array, each index is a letter the user placed (or nil).
    private var currentGuess: [String?] = []
    
    /// This indicates whether each slot is “frozen” (i.e. placed via hint).
    /// Frozen slots cannot be tapped or removed by the user.
    var frozenSlots = Set<Int>()
    
    private var availableLetters: [LetterTile] = []
    private var initialAvailableLetters: [LetterTile] = []
    private var guessMapping: [Int?] = []
    private weak var collectionView: UICollectionView?
    
    // We no longer store puzzle-based coins here:
    // private var coins: Int = 0  <-- REMOVED
    
    // Determines whether we skip shuffling stock letters
    private var skipShuffle: Bool = false
    
    // MARK: - Nested Classes
    class LetterSlotCell: UICollectionViewCell {
        let letterLabel: UILabel = {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.8
            return label
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            contentView.addSubview(letterLabel)
            setupConstraints()
            setupStyle()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            contentView.addSubview(letterLabel)
            setupConstraints()
            setupStyle()
        }
        
        private func setupConstraints() {
            NSLayoutConstraint.activate([
                letterLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
                letterLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
                letterLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
                letterLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5)
            ])
        }
        
        private func setupStyle() {
            layer.cornerRadius = 12
            layer.borderWidth = 1
            layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
            layer.masksToBounds = false
            
            // Add subtle shadow for depth
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOffset = CGSize(width: 0, height: 2)
            layer.shadowRadius = 8
            layer.shadowOpacity = 0.3
            
            contentView.layer.masksToBounds = true
            contentView.layer.cornerRadius = 12
        }
        
        func configure(with letter: String, state: LetterTileState) {
            letterLabel.text = letter
            if letter.isEmpty {
                // Empty slot - glass effect with subtle border
                layer.borderWidth = 1
                layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
                contentView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
                letterLabel.textColor = .white.withAlphaComponent(0.5)
            } else {
                layer.borderWidth = 1
                switch state {
                case .normal:
                    // Normal letter - glass effect with white background
                    contentView.backgroundColor = UIColor.white.withAlphaComponent(0.9)
                    layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
                    letterLabel.textColor = .black
                case .selected:
                    // Selected letter - subtle highlight
                    contentView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3)
                    layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.5).cgColor
                    letterLabel.textColor = .white
                case .correct:
                    // Correct letter - green glass effect
                    contentView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.8)
                    layer.borderColor = UIColor.systemGreen.withAlphaComponent(0.6).cgColor
                    letterLabel.textColor = .white
                case .incorrect:
                    // Incorrect letter - red glass effect
                    contentView.backgroundColor = UIColor.systemRed.withAlphaComponent(0.8)
                    layer.borderColor = UIColor.systemRed.withAlphaComponent(0.6).cgColor
                    letterLabel.textColor = .white
                case .hint:
                    // Hint letter - blue glass effect
                    contentView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.8)
                    layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.6).cgColor
                    letterLabel.textColor = .white
                }
            }
        }
    }
    
    class KeyboardCell: UICollectionViewCell {
        let letterLabel: UILabel = {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.8
            return label
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            contentView.addSubview(letterLabel)
            setupConstraints()
            setupStyle()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            contentView.addSubview(letterLabel)
            setupConstraints()
            setupStyle()
        }
        
        private func setupConstraints() {
            NSLayoutConstraint.activate([
                letterLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
                letterLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
                letterLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
                letterLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5)
            ])
        }
        
        private func setupStyle() {
            layer.cornerRadius = 12
            layer.borderWidth = 1
            layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
            layer.masksToBounds = false
            
            // Add subtle shadow for depth
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOffset = CGSize(width: 0, height: 2)
            layer.shadowRadius = 8
            layer.shadowOpacity = 0.3
            
            contentView.layer.masksToBounds = true
            contentView.layer.cornerRadius = 12
        }
        
        func configure(with tile: LetterTile) {
            letterLabel.text = tile.letter
            
            if tile.isUsed {
                // Used letter - subtle glass effect
                contentView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
                layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
                letterLabel.textColor = .white.withAlphaComponent(0.4)
            } else {
                // Available letter - bright glass effect
                contentView.backgroundColor = UIColor.white.withAlphaComponent(0.9)
                layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
                letterLabel.textColor = .black
            }
        }
    }
    
    // MARK: - Structs/Enums
    struct LetterTile {
        var letter: String
        var isUsed: Bool = false
    }
    
    enum LetterTileState {
        case normal
        case selected
        case correct
        case incorrect
        case hint
    }
    
    // MARK: - UI Setup Helpers
    class UIComponents {
        static func setupLetterCollectionView() -> UICollectionView {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .horizontal
            layout.minimumInteritemSpacing = 5.0
            let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
            collectionView.register(GameBoardManager.LetterSlotCell.self, forCellWithReuseIdentifier: "LetterSlotCell")
            collectionView.isScrollEnabled = false
            collectionView.backgroundColor = .clear
            return collectionView
        }
        
        static func setupKeyboardCollectionView() -> UICollectionView {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .vertical
            layout.minimumInteritemSpacing = 5.0
            let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
            collectionView.register(GameBoardManager.KeyboardCell.self, forCellWithReuseIdentifier: "KeyboardCell")
            return collectionView
        }
    }
    
    // MARK: - Word Constraints
    private let minWordLength = 3
    private let maxWordLength = 20
    private let maxStockLetters = 21
    
    // MARK: - Init
    init(targetWord: String,
         extraLetters: [String],
         collectionView: UICollectionView,
         skipShuffle: Bool = false)
    {
        self.collectionView = collectionView
        self.skipShuffle = skipShuffle
        setupLevel(targetWord: targetWord, extraLetters: extraLetters)
    }
    
    private func setupLevel(targetWord: String, extraLetters: [String]) {
        guard targetWord.count >= minWordLength && targetWord.count <= maxWordLength else {
            print("Invalid word length for targetWord: \(targetWord.count)")
            return
        }
        
        originalTargetWord = targetWord.uppercased()
        currentGuess = Array(repeating: nil, count: originalTargetWord.count)
        guessMapping = Array(repeating: nil, count: originalTargetWord.count)
        frozenSlots.removeAll()
        
        var stock = originalTargetWord.map { String($0) }
        let extraNeeded = maxStockLetters - stock.count
        if extraNeeded > 0, !extraLetters.isEmpty {
            let extra = extraLetters.shuffled().prefix(extraNeeded)
            stock.append(contentsOf: extra)
        }
        
        if !skipShuffle {
            stock.shuffle()
        }
        
        availableLetters = stock.map { LetterTile(letter: $0.uppercased()) }
        initialAvailableLetters = availableLetters
        
        collectionView?.reloadData()
    }
    
    // MARK: - Insert/Remove Letters
    func insertLetter(at tileIndex: Int, into slotIndex: Int) -> Bool {
        guard let collectionView = collectionView,
              slotIndex >= 0 && slotIndex < currentGuess.count,
              availableLetters.indices.contains(tileIndex),
              !availableLetters[tileIndex].isUsed
        else {
            return false
        }
        
        // If slot is frozen (hint letter), don't allow replacement
        if frozenSlots.contains(slotIndex) {
            return false
        }
        
        // If slot already has a letter, remove it first
        if currentGuess[slotIndex] != nil {
            removeLetter(from: slotIndex)
        }
        
        // Mark letter as used
        var tile = availableLetters[tileIndex]
        tile.isUsed = true
        availableLetters[tileIndex] = tile
        
        // Place in guess
        currentGuess[slotIndex] = tile.letter
        guessMapping[slotIndex] = tileIndex
        
        // Check if guess is fully filled now
        if !currentGuess.contains(where: { $0 == nil }) {
            // Grid is full - reload all cells to show proper state
            collectionView.reloadData()
            
            if checkWin() {
                // Win case
                if let vc = findGameViewController() {
                    vc.handleWin()
                }
            } else {
                // Error case - add haptic feedback and simple animation
                let impactFeedback = UINotificationFeedbackGenerator()
                impactFeedback.notificationOccurred(.error)
                
                // Simple shake animation on all non-frozen cells
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if let vc = self.findGameViewController() {
                        let visibleCells = vc.letterCollectionView.visibleCells
                        let nonHintCells = visibleCells.filter { cell in
                            if let indexPath = vc.letterCollectionView.indexPath(for: cell) {
                                return !self.frozenSlots.contains(indexPath.item)
                            }
                            return false
                        }
                        Animations.animateError(for: nonHintCells) {
                            // Animation complete
                        }
                    }
                }
            }
        } else {
            // Grid not full yet - just reload the single cell
            collectionView.reloadItems(at: [IndexPath(item: slotIndex, section: 0)])
        }
        
        return true
    }
    
    func removeLetter(from slotIndex: Int) {
        // If the slot is frozen (hint letter), don’t allow removal.
        if frozenSlots.contains(slotIndex) {
            return
        }
        
        guard let collectionView = collectionView,
              slotIndex >= 0 && slotIndex < currentGuess.count,
              let tileIndex = guessMapping[slotIndex],
              currentGuess[slotIndex] != nil
        else {
            return
        }
        
        // Free up the tile
        currentGuess[slotIndex] = nil
        guessMapping[slotIndex] = nil
        var tile = availableLetters[tileIndex]
        tile.isUsed = false
        availableLetters[tileIndex] = tile
        
        // Animate the slot cell back to empty
        if let cell = collectionView.cellForItem(at: IndexPath(item: slotIndex, section: 0)) as? LetterSlotCell {
            UIView.animate(withDuration: 0.3) {
                cell.contentView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
                cell.letterLabel.text = ""
            } completion: { _ in
                cell.configure(with: "", state: .normal)
                cell.layer.borderWidth = 0
                cell.contentView.layer.masksToBounds = true
            }
        }
        collectionView.reloadItems(at: [IndexPath(item: slotIndex, section: 0)])
        collectionView.reloadData()
        
        // Revert all filled slots to normal
        revertAllFilledSlotsToNormal()
    }
    
    private func revertAllFilledSlotsToNormal() {
        guard let cv = collectionView else { return }
        for index in 0..<currentGuess.count {
            if frozenSlots.contains(index) { continue }
            if let letter = currentGuess[index], !letter.isEmpty {
                if let cell = cv.cellForItem(at: IndexPath(item: index, section: 0)) as? LetterSlotCell {
                    cell.contentView.backgroundColor = .white
                    cell.letterLabel.textColor = .black
                }
            }
        }
    }
    
    // MARK: - Hint System: Remove Letter from Available Stock
    func removeLetterFromAvailable(index: Int) {
        guard index >= 0 && index < availableLetters.count else { return }
        
        let removedLetter = availableLetters[index].letter
        print("🗑️ Removing letter '\(removedLetter)' from available stock at index \(index)")
        
        // Actually remove the letter from the array (not just mark as used)
        availableLetters.remove(at: index)
        
        print("📊 Available letters count: \(availableLetters.count)")
        
        // Reload the keyboard to show the letter is completely gone
        collectionView?.reloadData()
    }
    
    func checkWin() -> Bool {
        guard !currentGuess.contains(where: { $0 == nil }) else { return false }
        return currentGuess.compactMap { $0 }.joined() == originalTargetWord
    }
    
    func resetCurrentGuess() {
        guard let collectionView = collectionView else { return }
        currentGuess = Array(repeating: nil, count: originalTargetWord.count)
        guessMapping = Array(repeating: nil, count: originalTargetWord.count)
        frozenSlots.removeAll()
        
        availableLetters = initialAvailableLetters
        for i in 0..<availableLetters.count {
            var tile = availableLetters[i]
            tile.isUsed = false
            availableLetters[i] = tile
        }
        
        collectionView.reloadData()
    }
    
    private func findGameViewController() -> GameViewController? {
        return collectionView?.window?.rootViewController?.presentedViewController as? GameViewController
    }
    
    // ---------------------------------
    // MARK: - Accessors
    // ---------------------------------
    func getTileIndexForSlot(_ slotIndex: Int) -> Int? {
        return guessMapping[slotIndex]
    }
    
    var targetLetters: [String] {
        return originalTargetWord.map { String($0) }
    }
    
    var currentGuessState: [String?] {
        return currentGuess
    }
    
    var availableLettersState: [LetterTile] {
        return availableLetters
    }
    
    // We no longer have puzzle-based coinCount
    // var coinCount: Int { ... } -- REMOVED
    
    func registerCells(for collectionView: UICollectionView) {
        collectionView.register(LetterSlotCell.self, forCellWithReuseIdentifier: "LetterSlotCell")
        collectionView.register(KeyboardCell.self, forCellWithReuseIdentifier: "KeyboardCell")
    }
    
    func markTileAsUsed(at tileIndex: Int) {
        guard availableLetters.indices.contains(tileIndex) else { return }
        var tile = availableLetters[tileIndex]
        tile.isUsed = true
        availableLetters[tileIndex] = tile
    }
    
    // No setCoinCount(...) method needed now
    
    func restoreGuess(_ guess: [String?], restoredAvailableLetters: [LetterTile], frozenSlots: Set<Int>) {
        guard guess.count == currentGuess.count,
              restoredAvailableLetters.count == availableLetters.count else {
            print("Restore guess error: Counts don't match.")
            return
        }
        availableLetters = restoredAvailableLetters
        initialAvailableLetters = restoredAvailableLetters
        self.frozenSlots = frozenSlots
        guessMapping = Array(repeating: nil, count: currentGuess.count)
        currentGuess = Array(repeating: nil, count: currentGuess.count)
        
        var usedTileIndices = Set<Int>()
        for (slotIndex, letterOpt) in guess.enumerated() {
            guard let letter = letterOpt else { continue }
            if let match = availableLetters.enumerated().first(where: { (idx, tile) in
                tile.letter == letter && tile.isUsed && !usedTileIndices.contains(idx)
            }) {
                guessMapping[slotIndex] = match.0
                usedTileIndices.insert(match.0)
                currentGuess[slotIndex] = letter
            } else {
                print("Restore guess error: Can't match letter \(letter) in puzzle stock.")
            }
        }
        collectionView?.reloadData()
    }
}

// MARK: - Extended Hint Methods
extension GameBoardManager {
    
    /// Remove `count` letters from the keyboard stock that are not needed for the solution.
    /// This no longer checks or modifies any coin count. It's purely puzzle logic.
    func removeIncorrectLetters(count: Int) -> (success: Bool, removedIndices: [Int]) {
        let solutionFrequencies = frequencyMap(for: originalTargetWord)
        var removableIndices: [Int] = []
        
        for (index, tile) in availableLetters.enumerated() {
            if tile.isUsed { continue }
            if !solutionFrequencies.keys.contains(tile.letter) {
                removableIndices.append(index)
                continue
            }
            let letterNeededCount = solutionFrequencies[tile.letter] ?? 0
            let letterCountInStock = availableLetters.filter {
                $0.letter == tile.letter && !$0.isUsed
            }.count
            if letterCountInStock > letterNeededCount {
                removableIndices.append(index)
            }
        }
        
        if removableIndices.count < count {
            return (false, [])
        }
        
        removableIndices.shuffle()
        let chosenIndices = Array(removableIndices.prefix(count))
        
        for idx in chosenIndices {
            var tile = availableLetters[idx]
            tile.isUsed = true
            tile.letter = "" // blank out the letter
            availableLetters[idx] = tile
        }
        
        collectionView?.reloadData()
        onKeyboardUpdateNeeded?()
        
        if checkWin() {
            if let vc = findGameViewController() {
                vc.handleWin()
            }
        }
        return (true, chosenIndices)
    }
    
    func revealLetters(count: Int) -> Int {
        let emptySlots = currentGuess.enumerated()
            .compactMap { $1 == nil ? $0 : nil }
        
        if emptySlots.isEmpty { return 0 }
        
        var revealedCount = 0
        
        for slotIndex in emptySlots.prefix(count) {
            let correctLetter = String(
                originalTargetWord[originalTargetWord.index(originalTargetWord.startIndex, offsetBy: slotIndex)]
            )
            
            if let tileIndex = availableLetters.firstIndex(where: { !$0.isUsed && $0.letter == correctLetter }) {
                var tile = availableLetters[tileIndex]
                tile.isUsed = true
                availableLetters[tileIndex] = tile
                guessMapping[slotIndex] = tileIndex
            }
            
            currentGuess[slotIndex] = correctLetter
            frozenSlots.insert(slotIndex)
            
            if let cell = collectionView?.cellForItem(at: IndexPath(item: slotIndex, section: 0)) as? LetterSlotCell {
                cell.configure(with: correctLetter, state: .hint)
            }
            
            revealedCount += 1
        }
        
        collectionView?.reloadData()
        
        if checkWin() {
            if let vc = findGameViewController() {
                vc.handleWin()
            }
        }
        
        return revealedCount
    }
    
    private func frequencyMap(for word: String) -> [String: Int] {
        var freq: [String: Int] = [:]
        for char in word {
            let letter = String(char)
            freq[letter, default: 0] += 1
        }
        return freq
    }
    
    func prepareRevealLetters(count: Int) -> [(slotIndex: Int, tileIndex: Int, letter: String)] {
        let emptySlots = currentGuess.enumerated().compactMap { $1 == nil ? $0 : nil }
        var revealData: [(slotIndex: Int, tileIndex: Int, letter: String)] = []
        
        for slotIndex in emptySlots.prefix(count) {
            let correctLetter = String(
                originalTargetWord[originalTargetWord.index(originalTargetWord.startIndex, offsetBy: slotIndex)]
            )
            if let tileIndex = availableLetters.firstIndex(where: { !$0.isUsed && $0.letter == correctLetter }) {
                availableLetters[tileIndex].isUsed = true
                currentGuess[slotIndex] = correctLetter
                frozenSlots.insert(slotIndex)
                revealData.append((slotIndex, tileIndex, correctLetter))
            } else {
                print("No tile found for letter \(correctLetter) at slot \(slotIndex)")
            }
        }
        
        return revealData
    }
}
