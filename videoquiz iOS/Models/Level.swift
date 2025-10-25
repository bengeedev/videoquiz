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
    let image: String?  // Optional for backward compatibility
    let video: String?  // New video field
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

// This struct handles loading levels from JSON
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
