//
//  GameViewModel.swift
//  VideoQuiz iOS
//
//  Created by Benjamin Gievis
//

import UIKit

extension Notification.Name {
    static let coinsUpdated = Notification.Name("coinsUpdated")
}

class GameViewModel {
    private(set) var gameBoardManager: GameBoardManager?
    private var levels: [Level] = []
    private var currentLevelIndex = 0
    
    // Game statistics for achievements
    private var gameStats: GameStats {
        return GameStats(
            levelsCompleted: UserDefaults.standard.integer(forKey: "ChefQuizLevelsCompleted"),
            totalCoinsEarned: UserDefaults.standard.integer(forKey: "ChefQuizTotalCoinsEarned"),
            hintsUsed: UserDefaults.standard.integer(forKey: "ChefQuizHintsUsed"),
            perfectLevels: UserDefaults.standard.integer(forKey: "ChefQuizPerfectLevels"),
            currentStreak: UserDefaults.standard.integer(forKey: "ChefQuizCurrentStreak")
        )
    }
    
    // We'll store a "restoredState" here after loading from UserDefaults for puzzle-specific data
    private var restoredState: PersistedGameState?
    
    // -------------------------------------------
    // MARK: - Global Coins (Separate from Puzzle)
    // -------------------------------------------
    
    /// We keep our global coin balance in UserDefaults,
    /// under a unique key, e.g. "ChefQuizGlobalCoins".
    private var globalCoins: Int {
        get {
            let coins = UserDefaults.standard.integer(forKey: "ChefQuizGlobalCoins")
            // If coins haven't been set yet (first launch), initialize with default amount
            if coins == 0 && !UserDefaults.standard.bool(forKey: "ChefQuizCoinsInitialized") {
                UserDefaults.standard.set(true, forKey: "ChefQuizCoinsInitialized")
                UserDefaults.standard.set(Constants.initialCoins, forKey: "ChefQuizGlobalCoins")
                UserDefaults.standard.synchronize()
                return Constants.initialCoins
            }
            return coins
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "ChefQuizGlobalCoins")
            UserDefaults.standard.synchronize()
        }
    }
    
    /// Public accessor so UI can read the current global coins
    var coins: Int {
        return globalCoins
    }
    
    // -------------------------------------------
    // MARK: - Puzzle Accessors
    // -------------------------------------------
    var currentGuess: [String?] {
        return gameBoardManager?.currentGuessState ?? []
    }
    
    var availableLetters: [GameBoardManager.LetterTile] {
        return gameBoardManager?.availableLettersState ?? []
    }
    
    var targetLetters: [String] {
        return gameBoardManager?.targetLetters ?? []
    }
    
    /// Human-friendly level number
    var completedLevel: Int {
        return currentLevelIndex + 1
    }
    
    var currentLevelImage: String? {
        return levels[safe: currentLevelIndex]?.image
    }
    
    var currentLevelMedia: MediaType {
        return levels[safe: currentLevelIndex]?.mediaType ?? .placeholder
    }
    
    // ---------------------------------
    // MARK: - Loading Levels & State
    // ---------------------------------
    func loadLevels(for language: String = "en") {
        if let loadedLevels = LevelData.load(for: language) {
            levels = loadedLevels
        } else {
            print("Failed to load levels for language \(language).")
        }

        // Load puzzle-based state (but not coins, since coins are now global)
        loadPuzzleState()

        if currentLevelIndex >= levels.count {
            currentLevelIndex = max(levels.count - 1, 0)
        }
    }

    /// Load levels from a selected theme
    func loadLevelsForTheme(_ theme: Theme) {
        levels = theme.levels
        currentLevelIndex = 0 // Start from first level of theme

        print("📚 Loaded \(levels.count) levels for theme: \(theme.name)")

        // Load puzzle-based state
        loadPuzzleState()

        if currentLevelIndex >= levels.count {
            currentLevelIndex = max(levels.count - 1, 0)
        }
    }
    
    func loadCurrentLevel(with collectionView: UICollectionView) {
        guard currentLevelIndex < levels.count else {
            print("No more levels available!")
            return
        }
        let level = levels[currentLevelIndex]
        print("Loading level '\(level.word)' with image '\(level.image)'")
        
        if let restored = restoredState,
           restored.targetWord.uppercased() == level.word.uppercased() {
            // We have a puzzle state that matches this word
            gameBoardManager = GameBoardManager(
                targetWord: level.word,
                extraLetters: level.extraLetters,
                collectionView: collectionView,
                skipShuffle: true
            )
            gameBoardManager?.restoreGuess(
                restored.currentGuess,
                restoredAvailableLetters: restored.availableLetters.map {
                    GameBoardManager.LetterTile(letter: $0.letter, isUsed: $0.isUsed)
                },
                frozenSlots: Set(restored.frozenSlots)
            )
            restoredState = nil
        } else {
            // Fresh puzzle
            gameBoardManager = GameBoardManager(
                targetWord: level.word,
                extraLetters: level.extraLetters,
                collectionView: collectionView,
                skipShuffle: false
            )
        }
    }
    
    // ---------------------------------
    // MARK: - Basic Puzzle Mechanics
    // ---------------------------------
    func insertLetterAtExactIndex(_ tileIndex: Int, intoSlot slotIndex: Int) -> Bool {
        return gameBoardManager?.insertLetter(at: tileIndex, into: slotIndex) ?? false
    }
    
    func removeLetterFromSlot(_ slotIndex: Int) {
        gameBoardManager?.removeLetter(from: slotIndex)
    }
    
    func getTileIndexForSlot(_ slotIndex: Int) -> Int? {
        return gameBoardManager?.getTileIndexForSlot(slotIndex)
    }
    
    func checkWin() -> Bool {
        return gameBoardManager?.checkWin() ?? false
    }
    
    func resetCurrentGuess() {
        gameBoardManager?.resetCurrentGuess()
    }
    
    func isSlotFrozen(_ slotIndex: Int) -> Bool {
        return gameBoardManager?.frozenSlots.contains(slotIndex) ?? false
    }
    
    // ---------------------------------
    // MARK: - Level Progression
    // ---------------------------------
    func advanceToNextLevel() {
        currentLevelIndex += 1
        if currentLevelIndex >= levels.count {
            currentLevelIndex = max(levels.count - 1, 0)
            print("Reached final level or no levels remain.")
        }
        savePuzzleState()
    }
    
    // ---------------------------------
    // MARK: - Puzzle Persisted State
    // ---------------------------------
    /// Now we no longer store coinCount in puzzle data.
    private struct PersistedGameState: Codable {
        var currentLevelIndex: Int
        var targetWord: String
        var currentGuess: [String?]
        var availableLetters: [PersistedLetterTile]
        var frozenSlots: [Int]
    }
    
    private struct PersistedLetterTile: Codable {
        let letter: String
        let isUsed: Bool
    }
    
    func savePuzzleState() {
        guard let manager = gameBoardManager else { return }
        
        let puzzleState = PersistedGameState(
            currentLevelIndex: currentLevelIndex,
            targetWord: manager.originalTargetWord,
            currentGuess: manager.currentGuessState,
            availableLetters: manager.availableLettersState.map {
                PersistedLetterTile(letter: $0.letter, isUsed: $0.isUsed)
            },
            frozenSlots: Array(manager.frozenSlots)
        )
        
        do {
            let data = try JSONEncoder().encode(puzzleState)
            UserDefaults.standard.set(data, forKey: "ChefQuizPuzzleState")
            UserDefaults.standard.synchronize()
        } catch {
            print("Failed to save puzzle state: \(error)")
        }
    }
    
    private func loadPuzzleState() {
        let defaults = UserDefaults.standard
        guard let data = defaults.data(forKey: "ChefQuizPuzzleState") else {
            return
        }
        
        do {
            let loadedState = try JSONDecoder().decode(PersistedGameState.self, from: data)
            self.restoredState = loadedState
            self.currentLevelIndex = loadedState.currentLevelIndex
            print("Loaded puzzle state for level: \(loadedState.currentLevelIndex)")
        } catch {
            print("Failed to load puzzle state: \(error)")
        }
    }
    
    // -------------------------------------
    // MARK: - Hint & Coin Utility Methods
    // -------------------------------------
    
    /// Feature 1: Remove Incorrect Letters (Rebuilt)
    func tryRemoveIncorrectLetters(amount: Int, cost: Int) -> (success: Bool, removedIndices: [Int]) {
        // Check coins
        guard coins >= cost else { 
            print("❌ Not enough coins: \(coins) < \(cost)")
            return (false, []) 
        }
        
        // Check if removal is possible
        guard canRemoveIncorrectLetters(amount: amount) else { 
            print("❌ Cannot remove \(amount) incorrect letters")
            return (false, []) 
        }
        
        guard let manager = gameBoardManager else { return (false, []) }
        
        // Find incorrect letters
        let availableLetters = manager.availableLettersState
        let targetWord = manager.originalTargetWord
        var incorrectIndices: [Int] = []
        
        for (index, tile) in availableLetters.enumerated() {
            if !tile.isUsed && !targetWord.contains(tile.letter) {
                incorrectIndices.append(index)
            }
        }
        
        // Select random letters to remove
        let shuffledIndices = incorrectIndices.shuffled()
        let toRemove = Array(shuffledIndices.prefix(amount))
        
        print("🎯 Removing incorrect letters at indices: \(toRemove)")
        
        // Deduct coins
        addCoins(-cost)
        
        // Remove letters from available letters (remove from highest index first to avoid index shifting)
        let sortedIndices = toRemove.sorted(by: >)
        for index in sortedIndices {
            manager.removeLetterFromAvailable(index: index)
        }
        
        return (true, toRemove)
    }
    
    /// Same approach for reveal:
    func tryRevealLetters(amount: Int, cost: Int) -> Bool {
        guard let manager = gameBoardManager else { return false }
        if globalCoins < cost { return false }
        
        let revealed = manager.revealLetters(count: amount)
        if revealed > 0 {
            globalCoins -= cost
            savePuzzleState()
            return true
        }
        return false
    }
    
    /// Skip level
    func trySkipLevel(cost: Int) -> Bool {
        guard let _ = gameBoardManager else { return false }
        if globalCoins < cost { return false }
        
        globalCoins -= cost
        advanceToNextLevel()
        return true
    }
    
    // Add coins globally
    func addGlobalCoins(_ amount: Int) {
        globalCoins += amount
        // No need to update puzzle state for this,
        // but if you want to re-save the puzzle state, call:
        savePuzzleState()
    }
    
    func addCoins(_ amount: Int) {
        // If you have a 'globalCoins' property:
        globalCoins += amount
        // Track total coins earned for achievements
        let currentTotal = UserDefaults.standard.integer(forKey: "ChefQuizTotalCoinsEarned")
        UserDefaults.standard.set(currentTotal + amount, forKey: "ChefQuizTotalCoinsEarned")
        UserDefaults.standard.synchronize()
        
        // Check for achievements
        AchievementManager.shared.checkForNewAchievements(gameStats: gameStats)
        
        // Notify UI of coin change
        NotificationCenter.default.post(name: .coinsUpdated, object: nil, userInfo: ["coins": globalCoins])
        
        // Then persist
        savePuzzleState() // or saveGameState(), depending on your design
    }
    
    // For reveal letters with animation
    func tryRevealLettersAnimated(amount: Int, cost: Int) -> [(slotIndex: Int, tileIndex: Int, letter: String)]? {
        guard let manager = gameBoardManager else { return nil }
        if globalCoins < cost { return nil }
        
        globalCoins -= cost
        let data = manager.prepareRevealLetters(count: amount)
        savePuzzleState()
        return data.isEmpty ? nil : data
    }
    
    // We can add "canRemoveIncorrectLetters" or "canRevealLetters" checks
    // but they just check puzzle states and globalCoins, if desired.
    
    // MARK: - Achievement Tracking Methods
    
    func trackLevelCompletion(usedHints: Bool = false) {
        // Track levels completed
        let currentLevels = UserDefaults.standard.integer(forKey: "ChefQuizLevelsCompleted")
        UserDefaults.standard.set(currentLevels + 1, forKey: "ChefQuizLevelsCompleted")

        // Track perfect levels (completed without hints)
        if !usedHints {
            let currentPerfect = UserDefaults.standard.integer(forKey: "ChefQuizPerfectLevels")
            UserDefaults.standard.set(currentPerfect + 1, forKey: "ChefQuizPerfectLevels")
        }

        // Update current streak
        let currentStreak = UserDefaults.standard.integer(forKey: "ChefQuizCurrentStreak")
        UserDefaults.standard.set(currentStreak + 1, forKey: "ChefQuizCurrentStreak")

        // Track theme-specific completion
        if currentLevelIndex < levels.count {
            let currentLevel = levels[currentLevelIndex]
            ThemeData.markLevelCompleted(themeId: currentLevel.themeId)
        }

        UserDefaults.standard.synchronize()

        // Check for achievements
        AchievementManager.shared.checkForNewAchievements(gameStats: gameStats)
    }
    
    func trackHintUsage() {
        let currentHints = UserDefaults.standard.integer(forKey: "ChefQuizHintsUsed")
        UserDefaults.standard.set(currentHints + 1, forKey: "ChefQuizHintsUsed")
        UserDefaults.standard.synchronize()
        
        // Check for achievements
        AchievementManager.shared.checkForNewAchievements(gameStats: gameStats)
    }
    
    func resetStreak() {
        UserDefaults.standard.set(0, forKey: "ChefQuizCurrentStreak")
        UserDefaults.standard.synchronize()
    }
    
    // MARK: - Hint Availability Methods
    
    // MARK: - Feature 1: Remove Incorrect Letters (Rebuilt)
    func canRemoveIncorrectLetters(amount: Int) -> Bool {
        guard let manager = gameBoardManager else { return false }
        
        // Simple approach: count letters that are NOT in the target word
        let availableLetters = manager.availableLettersState
        let targetWord = manager.originalTargetWord
        
        let incorrectCount = availableLetters.filter { tile in
            !tile.isUsed && !targetWord.contains(tile.letter)
        }.count
        
        print("🔍 Can remove \(amount) letters? Available incorrect: \(incorrectCount)")
        return incorrectCount >= amount
    }
    
    
    func canRevealLetters(amount: Int) -> Bool {
        guard let manager = gameBoardManager else { return false }
        let emptySlots = manager.currentGuessState.filter { $0 == nil }.count
        return emptySlots >= amount
    }
    
    private func frequencyMap(for word: String) -> [String: Int] {
        var freq: [String: Int] = [:]
        for char in word {
            let letter = String(char)
            freq[letter, default: 0] += 1
        }
        return freq
    }
}

// MARK: - New Method to Fix Save Error
extension GameViewModel {
    /// This method exposes a saveGameState() function to be called from the UI.
    func saveGameState() {
        savePuzzleState()
    }
}

// Helper subscript
extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

