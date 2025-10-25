//
//  AchievementCell.swift
//  Chef Quiz - 2025 iOS
//
//  Created by Benjamin Gievis on 05/03/2025.
//


// AchievementCell.swift
import UIKit

class AchievementCell: UITableViewCell {
    static let reuseIdentifier = "AchievementCell"
    
    private let colorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 10
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let lockOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.gray.withAlphaComponent(0.7)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 10
        return view
    }()
    
    private let lockImage: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "lock.fill"))
        imageView.tintColor = .white
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        contentView.addSubview(colorView)
        colorView.addSubview(titleLabel)
        colorView.addSubview(lockOverlay)
        lockOverlay.addSubview(lockImage)
        
        NSLayoutConstraint.activate([
            colorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            colorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            colorView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            colorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
            
            titleLabel.centerXAnchor.constraint(equalTo: colorView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: colorView.centerYAnchor),
            
            lockOverlay.leadingAnchor.constraint(equalTo: colorView.leadingAnchor),
            lockOverlay.trailingAnchor.constraint(equalTo: colorView.trailingAnchor),
            lockOverlay.topAnchor.constraint(equalTo: colorView.topAnchor),
            lockOverlay.bottomAnchor.constraint(equalTo: colorView.bottomAnchor),
            
            lockImage.centerXAnchor.constraint(equalTo: lockOverlay.centerXAnchor),
            lockImage.centerYAnchor.constraint(equalTo: lockOverlay.centerYAnchor),
            lockImage.widthAnchor.constraint(equalToConstant: 20),
            lockImage.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    func configure(with title: String, color: UIColor, isUnlocked: Bool) {
        colorView.backgroundColor = color
        titleLabel.text = title
        lockOverlay.isHidden = isUnlocked
    }
}