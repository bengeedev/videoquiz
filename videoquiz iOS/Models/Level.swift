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
    let mediaId: String?  // NEW: For dual video support (e.g., "FOOD_DESSERT_0001")
    let word: String
    let extraLetters: [String]

    // Computed property to get video paths for A and B variants
    var videoPaths: (videoA: String?, videoB: String?) {
        guard let mediaId = mediaId else { return (nil, nil) }

        // Extract theme code from mediaId (e.g., "FOOD_DESSERT_0001" -> "FOOD_DESSERT")
        let parts = mediaId.split(separator: "_")
        guard parts.count >= 3 else { return (nil, nil) }
        let themeCode = parts.dropLast().joined(separator: "_")

        // Try new structure first: Resources/Videos/FOOD_DESSERT/
        var pathA = Bundle.main.path(
            forResource: "\(mediaId)A",
            ofType: "mp4",
            inDirectory: "Resources/Videos/\(themeCode)"
        )
        var pathB = Bundle.main.path(
            forResource: "\(mediaId)B",
            ofType: "mp4",
            inDirectory: "Resources/Videos/\(themeCode)"
        )

        // Fallback to old structure: Resources/Videos/ (root)
        if pathA == nil {
            pathA = Bundle.main.path(forResource: "\(mediaId)A", ofType: "mp4", inDirectory: "Resources/Videos")
        }
        if pathB == nil {
            pathB = Bundle.main.path(forResource: "\(mediaId)B", ofType: "mp4", inDirectory: "Resources/Videos")
        }

        // Final fallback: bundle root
        if pathA == nil {
            pathA = Bundle.main.path(forResource: "\(mediaId)A", ofType: "mp4")
        }
        if pathB == nil {
            pathB = Bundle.main.path(forResource: "\(mediaId)B", ofType: "mp4")
        }

        print("🎬 Looking for dual videos: \(mediaId)")
        print("   Theme code: \(themeCode)")
        print("   Video A path: \(pathA ?? "NOT FOUND")")
        print("   Video B path: \(pathB ?? "NOT FOUND")")

        return (pathA, pathB)
    }

    // Computed property to get the media type
    var mediaType: MediaType {
        // Check for dual video first
        if let mediaId = mediaId {
            let paths = videoPaths
            if paths.videoA != nil && paths.videoB != nil {
                return .dualVideo(mediaId)
            }
        }

        // Fallback to single video
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
    case dualVideo(String)  // NEW: Dual video with A/B variants
    case placeholder
}

// Theme model
struct Theme: Codable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let color: String
    let mainCategory: String?     // Main category: "food", "animals", "science", etc.
    let subTheme: String?         // Sub-theme: "desserts", "chinese", "wild", etc.
    let isNew: Bool               // Show in "New Themes" section
    let isEvent: Bool             // Featured in hero banner
    var isUnlocked: Bool
    let coinPrice: Int            // Coins needed to unlock
    let unlockRequirement: Int
    var levels: [Level]
    var completionPercentage: Double

    init(id: String, name: String, description: String, icon: String, color: String,
         mainCategory: String? = nil, subTheme: String? = nil, isNew: Bool = false, isEvent: Bool = false,
         isUnlocked: Bool, coinPrice: Int = 0, unlockRequirement: Int, levels: [Level] = [], completionPercentage: Double = 0.0) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.color = color
        self.mainCategory = mainCategory
        self.subTheme = subTheme
        self.isNew = isNew
        self.isEvent = isEvent
        self.isUnlocked = isUnlocked
        self.coinPrice = coinPrice
        self.unlockRequirement = unlockRequirement
        self.levels = levels
        self.completionPercentage = completionPercentage
    }
}

// Theme configuration model (from themes.json)
struct ThemeConfig: Codable {
    let id: String
    let themeCode: String?           // Theme code for video lookup (e.g., "FOOD_DESSERT")
    let mainCategory: String?        // Main category: "food", "animals", "science", etc.
    let subTheme: String?            // Sub-theme: "desserts", "chinese", "wild", etc.
    let name: String
    let description: String
    let icon: String
    let color: String
    let isNew: Bool?                 // Show in "New Themes" section
    let isEvent: Bool?               // Featured in hero banner
    let isUnlocked: Bool
    let coinPrice: Int?              // Coin price to unlock (0 = free)
    let unlockRequirement: Int
    let order: Int?                  // Display order
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
                mainCategory: config.mainCategory,
                subTheme: config.subTheme,
                isNew: config.isNew ?? false,
                isEvent: config.isEvent ?? false,
                isUnlocked: isUnlocked,
                coinPrice: config.coinPrice ?? 0,
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
        // Try bundle root first (where Xcode copies files)
        var path = Bundle.main.path(forResource: "themes", ofType: "json")

        // Fallback to old structure: Resources/Themes/
        if path == nil {
            print("⚠️ themes.json not found in bundle root, trying old path...")
            path = Bundle.main.path(forResource: "themes", ofType: "json", inDirectory: "Resources/Themes")
        }

        // Try new structure: Resources/Content/en/
        if path == nil {
            print("⚠️ themes.json not found in Resources/Themes, trying Content/en...")
            path = Bundle.main.path(forResource: "themes", ofType: "json", inDirectory: "Resources/Content/en")
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
        // Try bundle root first (where Xcode copies files): food_dessert.json
        var path = Bundle.main.path(forResource: themeId, ofType: "json")

        // Fallback to old structure: Resources/Levels/food_levels.json
        if path == nil {
            print("⚠️ \(themeId).json not found in bundle root, trying old path...")
            let oldFilename = "\(themeId)_levels"
            path = Bundle.main.path(forResource: oldFilename, ofType: "json", inDirectory: "Resources/Levels")
        }

        // Try new structure: Resources/Content/en/Levels/
        if path == nil {
            let filename = "\(themeId)_levels"
            print("⚠️ \(filename).json not found in Resources/Levels, trying Content/en/Levels...")
            path = Bundle.main.path(forResource: themeId, ofType: "json", inDirectory: "Resources/Content/en/Levels")
        }

        guard let validPath = path else {
            print("❌ ERROR: \(themeId).json not found in bundle!")
            return []
        }

        guard let data = try? Data(contentsOf: URL(fileURLWithPath: validPath)) else {
            print("❌ Failed to read \(themeId).json from: \(validPath)")
            return []
        }

        do {
            let levels = try JSONDecoder().decode([Level].self, from: data)
            print("✅ Loaded \(levels.count) levels for theme: \(themeId)")
            return levels
        } catch {
            print("❌ Failed to decode \(themeId).json: \(error)")
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
