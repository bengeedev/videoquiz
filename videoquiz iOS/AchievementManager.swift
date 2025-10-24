//
//  AchievementManager.swift
//  Chef Quiz - 2025 iOS
//
//  Created by Benjamin Gievis on 07/03/2025.
//

import Foundation
import UIKit

struct Achievement {
    let id: String
    let name: String
    let description: String
    let color: UIColor
    let unlockCondition: AchievementCondition
    var isUnlocked: Bool = false
    var unlockedDate: Date?
}

enum AchievementCondition {
    case levelsCompleted(Int)
    case coinsEarned(Int)
    case hintsUsed(Int)
    case perfectLevels(Int)
    case streak(Int)
}

class AchievementManager {
    static let shared = AchievementManager()
    
    private let userDefaults = UserDefaults.standard
    private let achievementsKey = "ChefQuizAchievements"
    
    // Define all achievements
    private let allAchievements: [Achievement] = [
        Achievement(id: "toque_jaune", name: "Toque Jaune", description: "Complete 5 levels", color: .yellow, unlockCondition: .levelsCompleted(5)),
        Achievement(id: "toque_orange", name: "Toque Orange", description: "Complete 10 levels", color: .orange, unlockCondition: .levelsCompleted(10)),
        Achievement(id: "toque_rouge", name: "Toque Rouge", description: "Complete 15 levels", color: .red, unlockCondition: .levelsCompleted(15)),
        Achievement(id: "toque_bleu_ciel", name: "Toque Bleu Ciel", description: "Complete 20 levels", color: UIColor(red: 0.5, green: 0.8, blue: 1.0, alpha: 1.0), unlockCondition: .levelsCompleted(20)),
        Achievement(id: "toque_bleu_marine", name: "Toque Bleu Marine", description: "Complete 25 levels", color: .blue, unlockCondition: .levelsCompleted(25)),
        Achievement(id: "toque_marron", name: "Toque Marron", description: "Complete 30 levels", color: .brown, unlockCondition: .levelsCompleted(30)),
        Achievement(id: "toque_violette", name: "Toque Violette", description: "Complete 35 levels", color: .purple, unlockCondition: .levelsCompleted(35)),
        Achievement(id: "toque_rose", name: "Toque Rose", description: "Complete 40 levels", color: .systemPink, unlockCondition: .levelsCompleted(40)),
        Achievement(id: "toque_verte", name: "Toque Verte", description: "Complete 45 levels", color: .green, unlockCondition: .levelsCompleted(45)),
        Achievement(id: "toque_grise", name: "Toque Grise", description: "Complete 50 levels", color: .gray, unlockCondition: .levelsCompleted(50)),
        Achievement(id: "toque_noire", name: "Toque Noire", description: "Complete 60 levels", color: .black, unlockCondition: .levelsCompleted(60)),
        Achievement(id: "toque_arc_en_ciel", name: "Toque Arc-en-Ciel", description: "Complete 70 levels", color: UIColor(red: 1.0, green: 0.5, blue: 0.5, alpha: 1.0), unlockCondition: .levelsCompleted(70)),
        Achievement(id: "toque_bronze", name: "Toque Bronze", description: "Earn 1000 coins", color: UIColor(red: 0.8, green: 0.5, blue: 0.2, alpha: 1.0), unlockCondition: .coinsEarned(1000)),
        Achievement(id: "toque_argent", name: "Toque Argent", description: "Earn 2500 coins", color: .lightGray, unlockCondition: .coinsEarned(2500)),
        Achievement(id: "toque_or", name: "Toque Or", description: "Earn 5000 coins", color: .yellow.withAlphaComponent(0.8), unlockCondition: .coinsEarned(5000)),
        Achievement(id: "toque_platine", name: "Toque Platine", description: "Earn 10000 coins", color: UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0), unlockCondition: .coinsEarned(10000)),
        Achievement(id: "toque_emeraude", name: "Toque Emeraude", description: "Earn 15000 coins", color: UIColor(red: 0.0, green: 0.6, blue: 0.4, alpha: 1.0), unlockCondition: .coinsEarned(15000)),
        Achievement(id: "toque_rubis", name: "Toque Rubis", description: "Earn 25000 coins", color: .red.withAlphaComponent(0.8), unlockCondition: .coinsEarned(25000)),
        Achievement(id: "toque_saphir", name: "Toque Saphir", description: "Earn 50000 coins", color: .blue.withAlphaComponent(0.8), unlockCondition: .coinsEarned(50000)),
        Achievement(id: "toque_perle", name: "Toque Perle", description: "Earn 100000 coins", color: .white.withAlphaComponent(0.8), unlockCondition: .coinsEarned(100000)),
        Achievement(id: "toque_titane", name: "Toque Titane", description: "Use 10 hints", color: .gray.withAlphaComponent(0.7), unlockCondition: .hintsUsed(10)),
        Achievement(id: "toque_feu", name: "Toque Feu", description: "Use 25 hints", color: .red.withAlphaComponent(0.7), unlockCondition: .hintsUsed(25)),
        Achievement(id: "toque_cuir", name: "Toque Cuir", description: "Use 50 hints", color: .brown.withAlphaComponent(0.7), unlockCondition: .hintsUsed(50)),
        Achievement(id: "toque_kryptonite", name: "Toque Kryptonite", description: "Complete 5 levels without hints", color: .green.withAlphaComponent(0.7), unlockCondition: .perfectLevels(5)),
        Achievement(id: "toque_diamant", name: "Toque Diamant", description: "Complete 10 levels without hints", color: .cyan.withAlphaComponent(0.8), unlockCondition: .perfectLevels(10))
    ]
    
    private var achievements: [Achievement] = []
    
    private init() {
        loadAchievements()
    }
    
    // MARK: - Public Methods
    
    func getAllAchievements() -> [Achievement] {
        return achievements
    }
    
    func getUnlockedAchievements() -> [Achievement] {
        return achievements.filter { $0.isUnlocked }
    }
    
    func getLockedAchievements() -> [Achievement] {
        return achievements.filter { !$0.isUnlocked }
    }
    
    func checkForNewAchievements(gameStats: GameStats) {
        var hasNewAchievements = false
        
        for i in 0..<achievements.count {
            if !achievements[i].isUnlocked {
                if shouldUnlockAchievement(achievements[i], gameStats: gameStats) {
                    achievements[i].isUnlocked = true
                    achievements[i].unlockedDate = Date()
                    hasNewAchievements = true
                    print("🎉 Achievement unlocked: \(achievements[i].name)")
                }
            }
        }
        
        if hasNewAchievements {
            saveAchievements()
        }
    }
    
    // MARK: - Private Methods
    
    private func shouldUnlockAchievement(_ achievement: Achievement, gameStats: GameStats) -> Bool {
        switch achievement.unlockCondition {
        case .levelsCompleted(let required):
            return gameStats.levelsCompleted >= required
        case .coinsEarned(let required):
            return gameStats.totalCoinsEarned >= required
        case .hintsUsed(let required):
            return gameStats.hintsUsed >= required
        case .perfectLevels(let required):
            return gameStats.perfectLevels >= required
        case .streak(let required):
            return gameStats.currentStreak >= required
        }
    }
    
    private func loadAchievements() {
        if let data = userDefaults.data(forKey: achievementsKey),
           let savedAchievements = try? JSONDecoder().decode([Achievement].self, from: data) {
            achievements = savedAchievements
        } else {
            // First time - initialize with default achievements
            achievements = allAchievements
            saveAchievements()
        }
    }
    
    private func saveAchievements() {
        if let data = try? JSONEncoder().encode(achievements) {
            userDefaults.set(data, forKey: achievementsKey)
            userDefaults.synchronize()
        }
    }
}

// MARK: - GameStats Structure
struct GameStats {
    let levelsCompleted: Int
    let totalCoinsEarned: Int
    let hintsUsed: Int
    let perfectLevels: Int
    let currentStreak: Int
}

// MARK: - Achievement Codable Extension
extension Achievement: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name, description, color, unlockCondition, isUnlocked, unlockedDate
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        
        // Decode color as RGB components
        let colorData = try container.decode([CGFloat].self, forKey: .color)
        color = UIColor(red: colorData[0], green: colorData[1], blue: colorData[2], alpha: colorData[3])
        
        unlockCondition = try container.decode(AchievementCondition.self, forKey: .unlockCondition)
        isUnlocked = try container.decode(Bool.self, forKey: .isUnlocked)
        unlockedDate = try container.decodeIfPresent(Date.self, forKey: .unlockedDate)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        
        // Encode color as RGB components
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        try container.encode([red, green, blue, alpha], forKey: .color)
        
        try container.encode(unlockCondition, forKey: .unlockCondition)
        try container.encode(isUnlocked, forKey: .isUnlocked)
        try container.encodeIfPresent(unlockedDate, forKey: .unlockedDate)
    }
}

// MARK: - AchievementCondition Codable Extension
extension AchievementCondition: Codable {
    enum CodingKeys: String, CodingKey {
        case type, value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        let value = try container.decode(Int.self, forKey: .value)
        
        switch type {
        case "levelsCompleted":
            self = .levelsCompleted(value)
        case "coinsEarned":
            self = .coinsEarned(value)
        case "hintsUsed":
            self = .hintsUsed(value)
        case "perfectLevels":
            self = .perfectLevels(value)
        case "streak":
            self = .streak(value)
        default:
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unknown achievement condition type"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .levelsCompleted(let value):
            try container.encode("levelsCompleted", forKey: .type)
            try container.encode(value, forKey: .value)
        case .coinsEarned(let value):
            try container.encode("coinsEarned", forKey: .type)
            try container.encode(value, forKey: .value)
        case .hintsUsed(let value):
            try container.encode("hintsUsed", forKey: .type)
            try container.encode(value, forKey: .value)
        case .perfectLevels(let value):
            try container.encode("perfectLevels", forKey: .type)
            try container.encode(value, forKey: .value)
        case .streak(let value):
            try container.encode("streak", forKey: .type)
            try container.encode(value, forKey: .value)
        }
    }
}