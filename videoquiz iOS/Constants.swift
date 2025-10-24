//
//  Constants.swift
//  Chef Quiz - 2025 iOS
//
//  Created by Benjamin Gievis on 05/03/2025.
//

import UIKit

struct Constants {
    struct Animation {
        static let winAnimationDuration: TimeInterval = 0.3
        static let winSpringDamping: CGFloat = 0.6
        static let winInitialVelocity: CGFloat = 0.5
        static let winReturnDuration: TimeInterval = 0.2
        static let winCompletionDelay: TimeInterval = 0.5
        
        static let errorAnimationDuration: TimeInterval = 0.3
        static let errorCompletionDelay: TimeInterval = 0.35
    }
    
    // Game constants
    static let initialCoins: Int = 100
    static let hintCost: Int = 10
    
    // Layout constants
    static let letterCellSpacing: CGFloat = 5.0
    static let keyboardRows: Int = 3
    static let keyboardColumns: Int = 7
}
