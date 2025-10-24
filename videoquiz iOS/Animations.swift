//
//  Animations.swift
//  Chef Quiz - 2025
//
//  Created by Benjamin Gievis on 03/03/2025
//

import UIKit

struct Animations {
    
    // MARK: - Animation Constants
    struct Timing {
        static let fast: TimeInterval = 0.2
        static let normal: TimeInterval = 0.3
        static let slow: TimeInterval = 0.5
        static let springDamping: CGFloat = 0.7
        static let springVelocity: CGFloat = 0.8
    }
    
    private static func animate(
        duration: TimeInterval,
        delay: TimeInterval = 0,
        usingSpringWithDamping damping: CGFloat? = nil,
        initialSpringVelocity velocity: CGFloat? = nil,
        options: UIView.AnimationOptions = .curveEaseInOut,
        animations: @escaping () -> Void,
        completion: ((Bool) -> Void)? = nil
    ) {
        if let damping = damping, let velocity = velocity {
            UIView.animate(
                withDuration: duration,
                delay: delay,
                usingSpringWithDamping: damping,
                initialSpringVelocity: velocity,
                options: options,
                animations: animations,
                completion: completion
            )
        } else {
            UIView.animate(
                withDuration: duration,
                delay: delay,
                options: options,
                animations: animations,
                completion: completion
            )
        }
    }
    
    /// Enhanced win animation with staggered effects and confetti
    static func animateWin(for cells: [UICollectionViewCell], completion: @escaping () -> Void) {
        // First, add haptic feedback for win
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        let group = DispatchGroup()
        
        // Stagger the animations for a wave effect
        for (index, cell) in cells.enumerated() {
            group.enter()
            let delay = Double(index) * 0.1 // Stagger by 0.1 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                animateWinningCell(cell: cell) {
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            // Add screen-wide confetti after individual cell animations
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                completion()
            }
        }
    }
    
    /// Enhanced individual cell win animation with better effects
    private static func animateWinningCell(cell: UICollectionViewCell, completion: @escaping () -> Void) {
        // Step 1: Immediate color change with glow effect
        if let label = cell.contentView.subviews.first(where: { $0 is UILabel }) as? UILabel {
            label.textColor = .white
            label.text = label.text?.uppercased()
        }
        
        // Add glow effect
        cell.layer.shadowColor = UIColor.green.cgColor
        cell.layer.shadowRadius = 10
        cell.layer.shadowOpacity = 0.8
        cell.layer.shadowOffset = .zero
        
        // Step 2: Scale and color animation
        animate(
            duration: Timing.normal,
            usingSpringWithDamping: Timing.springDamping,
            initialSpringVelocity: Timing.springVelocity
        ) {
            cell.contentView.backgroundColor = .green
            cell.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        } completion: { _ in
            // Step 3: Gentle bounce back
            animate(
                duration: Timing.fast,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0.3
            ) {
                cell.transform = .identity
            } completion: { _ in
                // Step 4: Create sparkle effect
                createSparkleEffect(for: cell)
                
                // Step 5: Final state
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    cell.layer.shadowOpacity = 0.3 // Reduce glow but keep it
                    completion()
                }
            }
        }
    }
    
    /// Creates a sparkle effect around a cell
    private static func createSparkleEffect(for cell: UICollectionViewCell) {
        let sparkleLayer = CAEmitterLayer()
        sparkleLayer.emitterPosition = CGPoint(x: cell.bounds.midX, y: cell.bounds.midY)
        sparkleLayer.emitterSize = CGSize(width: cell.bounds.width * 1.5, height: cell.bounds.height * 1.5)
        sparkleLayer.emitterShape = .circle
        
        let sparkleCell = CAEmitterCell()
        sparkleCell.birthRate = 20
        sparkleCell.lifetime = 1.5
        sparkleCell.velocity = 30
        sparkleCell.velocityRange = 15
        sparkleCell.emissionRange = CGFloat.pi * 2
        sparkleCell.scale = 0.3
        sparkleCell.scaleRange = 0.2
        sparkleCell.scaleSpeed = -0.1
        sparkleCell.contents = starImage()?.cgImage
        sparkleCell.color = UIColor.yellow.cgColor
        sparkleCell.alphaSpeed = -0.5
        
        sparkleLayer.emitterCells = [sparkleCell]
        cell.layer.addSublayer(sparkleLayer)
        
        // Remove sparkles after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            sparkleLayer.removeFromSuperlayer()
        }
    }
    
    /// Creates a star image for sparkles
    private static func starImage() -> UIImage? {
        let size: CGFloat = 8
        let rect = CGRect(x: 0, y: 0, width: size, height: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        
        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(UIColor.yellow.cgColor)
            
            // Draw a simple star shape
            let center = CGPoint(x: size/2, y: size/2)
            let outerRadius: CGFloat = size/2
            let innerRadius: CGFloat = size/4
            
            context.move(to: CGPoint(x: center.x, y: center.y - outerRadius))
            
            for i in 0..<10 {
                let angle = CGFloat(i) * CGFloat.pi / 5 - CGFloat.pi / 2
                let radius = i % 2 == 0 ? outerRadius : innerRadius
                let x = center.x + radius * cos(angle)
                let y = center.y + radius * sin(angle)
                
                if i == 0 {
                    context.move(to: CGPoint(x: x, y: y))
                } else {
                    context.addLine(to: CGPoint(x: x, y: y))
                }
            }
            
            context.closePath()
            context.fillPath()
            
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image
        }
        
        UIGraphicsEndImageContext()
        return nil
    }

    
    /// Helper to generate a simple circle image for the emitter cell.
    private static func circleImage() -> UIImage? {
        let diameter: CGFloat = 10
        let rect = CGRect(x: 0, y: 0, width: diameter, height: diameter)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(UIColor.white.cgColor)
            context.fillEllipse(in: rect)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image
        }
        return nil
    }
    
    /// Enhanced error animation with better visual feedback
    static func animateError(for cells: [UICollectionViewCell], completion: @escaping () -> Void) {
        // Add haptic feedback for error
        let impactFeedback = UINotificationFeedbackGenerator()
        impactFeedback.notificationOccurred(.error)
        
        let group = DispatchGroup()
        
        for (index, cell) in cells.enumerated() {
            group.enter()
            let delay = Double(index) * 0.05 // Small stagger for wave effect
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                animateErrorCell(cell: cell) {
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                completion()
            }
        }
    }
    
    /// Animates an individual cell for error state - completely non-interfering
    private static func animateErrorCell(cell: UICollectionViewCell, completion: @escaping () -> Void) {
        // Error animation that doesn't interfere with background color at all
        // Step 1: Quick scale and shake (only affects transform)
        animate(duration: 0.15) {
            cell.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        } completion: { _ in
            // Step 2: Shake animation
            shake(cell: cell, amplitude: 6.0, repeats: 4)
            
            // Step 3: Scale back to normal
            animate(duration: 0.2) {
                cell.transform = .identity
            } completion: { _ in
                // No flash or overlay - just complete the animation
                completion()
            }
        }
    }
    
    /// Enhanced tile insertion animation
    static func animateTileInsertion(from sourceCell: UICollectionViewCell, to targetCell: UICollectionViewCell, completion: @escaping () -> Void) {
        // Create a snapshot of the source cell
        guard let snapshot = sourceCell.snapshotView(afterScreenUpdates: false) else {
            completion()
            return
        }
        
        // Position snapshot at source location
        snapshot.frame = sourceCell.convert(sourceCell.bounds, to: targetCell.superview!)
        targetCell.superview?.addSubview(snapshot)
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Animate the tile flying to target
        animate(
            duration: Timing.normal,
            usingSpringWithDamping: Timing.springDamping,
            initialSpringVelocity: Timing.springVelocity
        ) {
            snapshot.frame = targetCell.frame
            snapshot.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        } completion: { _ in
            // Remove snapshot and animate target cell
            snapshot.removeFromSuperview()
            
            animate(
                duration: Timing.fast,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0.3
            ) {
                targetCell.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            } completion: { _ in
                animate(duration: Timing.fast) {
                    targetCell.transform = .identity
                } completion: { _ in
                    completion()
                }
            }
        }
    }
    
    /// Enhanced tile removal animation
    static func animateTileRemoval(cell: UICollectionViewCell, completion: @escaping () -> Void) {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        animate(
            duration: Timing.fast,
            usingSpringWithDamping: 0.6,
            initialSpringVelocity: 0.5
        ) {
            cell.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            cell.alpha = 0.5
        } completion: { _ in
            animate(duration: Timing.fast) {
                cell.transform = .identity
                cell.alpha = 1.0
            } completion: { _ in
                completion()
            }
        }
    }
    
    /// Enhanced hint reveal animation
    static func animateHintReveal(cell: UICollectionViewCell, completion: @escaping () -> Void) {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Create a magical sparkle effect
        let sparkleLayer = CAEmitterLayer()
        sparkleLayer.emitterPosition = CGPoint(x: cell.bounds.midX, y: cell.bounds.midY)
        sparkleLayer.emitterSize = cell.bounds.size
        sparkleLayer.emitterShape = .circle
        
        let sparkleCell = CAEmitterCell()
        sparkleCell.birthRate = 15
        sparkleCell.lifetime = 1.0
        sparkleCell.velocity = 20
        sparkleCell.velocityRange = 10
        sparkleCell.emissionRange = CGFloat.pi * 2
        sparkleCell.scale = 0.2
        sparkleCell.scaleRange = 0.1
        sparkleCell.contents = circleImage()?.cgImage
        sparkleCell.color = UIColor.blue.cgColor
        sparkleCell.alphaSpeed = -0.8
        
        sparkleLayer.emitterCells = [sparkleCell]
        cell.layer.addSublayer(sparkleLayer)
        
        // Animate the cell
        animate(
            duration: Timing.normal,
            usingSpringWithDamping: Timing.springDamping,
            initialSpringVelocity: Timing.springVelocity
        ) {
            cell.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
        } completion: { _ in
            animate(duration: Timing.fast) {
                cell.transform = .identity
            } completion: { _ in
                // Remove sparkles
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    sparkleLayer.removeFromSuperlayer()
                    completion()
                }
            }
        }
    }
    
    static func revertToNormal(cell: UICollectionViewCell, completion: (() -> Void)? = nil) {
        animate(duration: Timing.normal) {
            cell.contentView.backgroundColor = .white
            cell.layer.shadowOpacity = 0
        } completion: { _ in
            completion?()
        }
    }
    
    private static func shake(cell: UICollectionViewCell, amplitude: CGFloat, repeats: Float) {
        let shake = CABasicAnimation(keyPath: "position")
        shake.duration = 0.05
        shake.repeatCount = repeats
        shake.autoreverses = true
        let fromPoint = CGPoint(x: cell.center.x - amplitude, y: cell.center.y)
        let toPoint = CGPoint(x: cell.center.x + amplitude, y: cell.center.y)
        shake.fromValue = NSValue(cgPoint: fromPoint)
        shake.toValue = NSValue(cgPoint: toPoint)
        cell.layer.add(shake, forKey: "position")
    }
}
