//
//  Level.swift
//  VideoQuiz iOS
//
//  Created by Benjamin Gievis
//

import Foundation

// Define the Level model
struct Level: Codable {
    let id: Int
    let themeId: String
    let image: String?  // Optional for backward compatibility
    let video: String?  // Video field (PRIMARY - video-first approach)
    let word: String
    let extraLetters: [String]

    // Computed property to get the media type
    var mediaType: MediaType {
        if let video = video, !video.isEmpty {
            return .video(video)
        } else if let image = image, !image.isEmpty {
            return .image(image)
        } else {
            return .placeholder
        }
    }
}

// Media type enum
enum MediaType {
    case image(String)
    case video(String)
    case placeholder
}

// Theme model
struct Theme: Codable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let color: String
    var isUnlocked: Bool
    let unlockRequirement: Int
    var levels: [Level]
    var completionPercentage: Double

    init(id: String, name: String, description: String, icon: String, color: String,
         isUnlocked: Bool, unlockRequirement: Int, levels: [Level] = [], completionPercentage: Double = 0.0) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.color = color
        self.isUnlocked = isUnlocked
        self.unlockRequirement = unlockRequirement
        self.levels = levels
        self.completionPercentage = completionPercentage
    }
}

// Theme configuration model (from themes.json)
struct ThemeConfig: Codable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let color: String
    let isUnlocked: Bool
    let unlockRequirement: Int
}

// Theme data manager
struct ThemeData {

    /// Load all themes with their levels
    static func loadThemes() -> [Theme] {
        // Load theme configs
        guard let configs = loadThemeConfigs() else {
            print("Failed to load theme configs")
            return []
        }

        // Build themes with their levels
        var themes: [Theme] = []
        for config in configs {
            let levels = loadLevelsForTheme(config.id)
            let isUnlocked = checkThemeUnlockStatus(config: config)
            let completion = calculateCompletionPercentage(for: config.id, totalLevels: levels.count)

            let theme = Theme(
                id: config.id,
                name: config.name,
                description: config.description,
                icon: config.icon,
                color: config.color,
                isUnlocked: isUnlocked,
                unlockRequirement: config.unlockRequirement,
                levels: levels,
                completionPercentage: completion
            )
            themes.append(theme)
        }

        return themes
    }

    /// Load theme configurations from themes.json
    private static func loadThemeConfigs() -> [ThemeConfig]? {
        // Try multiple paths to find the JSON file
        var path = Bundle.main.path(forResource: "themes", ofType: "json", inDirectory: "Resources/Themes")

        if path == nil {
            print("⚠️ themes.json not found in Resources/Themes, trying root...")
            path = Bundle.main.path(forResource: "themes", ofType: "json")
        }

        guard let validPath = path else {
            print("❌ ERROR: themes.json not found in bundle!")
            print("Available resources in bundle:")
            if let resourcePath = Bundle.main.resourcePath {
                let fileManager = FileManager.default
                if let files = try? fileManager.contentsOfDirectory(atPath: resourcePath) {
                    print(files.prefix(20))
                }
            }
            return nil
        }

        guard let data = try? Data(contentsOf: URL(fileURLWithPath: validPath)) else {
            print("❌ Failed to read themes.json from: \(validPath)")
            return nil
        }

        do {
            let configs = try JSONDecoder().decode([ThemeConfig].self, from: data)
            print("✅ Successfully loaded \(configs.count) theme configs")
            return configs
        } catch {
            print("❌ Failed to decode themes.json: \(error)")
            return nil
        }
    }

    /// Load levels for a specific theme
    static func loadLevelsForTheme(_ themeId: String) -> [Level] {
        let filename = "\(themeId)_levels"

        // Try multiple paths
        var path = Bundle.main.path(forResource: filename, ofType: "json", inDirectory: "Resources/Levels")

        if path == nil {
            print("⚠️ \(filename).json not found in Resources/Levels, trying root...")
            path = Bundle.main.path(forResource: filename, ofType: "json")
        }

        guard let validPath = path else {
            print("❌ ERROR: \(filename).json not found in bundle!")
            return []
        }

        guard let data = try? Data(contentsOf: URL(fileURLWithPath: validPath)) else {
            print("❌ Failed to read \(filename).json from: \(validPath)")
            return []
        }

        do {
            let levels = try JSONDecoder().decode([Level].self, from: data)
            print("✅ Loaded \(levels.count) levels for theme: \(themeId)")
            return levels
        } catch {
            print("❌ Failed to decode \(filename).json: \(error)")
            return []
        }
    }

    /// Check if theme should be unlocked
    private static func checkThemeUnlockStatus(config: ThemeConfig) -> Bool {
        if config.isUnlocked {
            return true
        }

        let totalCompletedLevels = getTotalCompletedLevels()
        return totalCompletedLevels >= config.unlockRequirement
    }

    /// Get total completed levels across all themes
    private static func getTotalCompletedLevels() -> Int {
        return UserDefaults.standard.integer(forKey: "VideoQuizCompletedLevels")
    }

    /// Calculate completion percentage for a theme
    private static func calculateCompletionPercentage(for themeId: String, totalLevels: Int) -> Double {
        guard totalLevels > 0 else { return 0.0 }

        let completedInTheme = UserDefaults.standard.integer(forKey: "VideoQuizCompletedLevels_\(themeId)")
        return Double(completedInTheme) / Double(totalLevels)
    }

    /// Mark a level as completed in a theme
    static func markLevelCompleted(themeId: String) {
        // Increment total completed levels
        let totalCompleted = UserDefaults.standard.integer(forKey: "VideoQuizCompletedLevels")
        UserDefaults.standard.set(totalCompleted + 1, forKey: "VideoQuizCompletedLevels")

        // Increment theme-specific completed levels
        let themeCompleted = UserDefaults.standard.integer(forKey: "VideoQuizCompletedLevels_\(themeId)")
        UserDefaults.standard.set(themeCompleted + 1, forKey: "VideoQuizCompletedLevels_\(themeId)")

        UserDefaults.standard.synchronize()

        print("✅ Level completed in theme: \(themeId). Total completed: \(totalCompleted + 1)")
    }
}

// Legacy level loader (for backward compatibility)
struct LevelData {
    static func load(for language: String = "en") -> [Level]? {
        return loadLevels(from: "levels_\(language)")
    }

    private static func loadLevels(from filename: String) -> [Level]? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            print("Could not find \(filename).json in bundle")
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let levels = try decoder.decode([Level].self, from: data)
            return levels
        } catch {
            print("Error loading levels: \(error)")
            return nil
        }
    }
}
