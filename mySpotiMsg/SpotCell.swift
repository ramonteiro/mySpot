//
//  SpotCell.swift
//  mySpotiMsg
//
//  Created by Isaac Paschall on 6/20/22.
//

import UIKit

class SpotCell: UITableViewCell {
    
    var spotImageView = UIImageView()
    var spotTitleLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubview(spotImageView)
        addSubview(spotTitleLabel)
        configureImageView()
        configureTitleView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(spot: msgSpot) {
        spotImageView.image = spot.image
        spotTitleLabel.text = spot.name
    }
    
    func configureImageView() {
        spotImageView.layer.cornerRadius = 10
        spotImageView.clipsToBounds = true
        
        spotImageView.translatesAutoresizingMaskIntoConstraints = false
        spotImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        spotImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12).isActive = true
        spotImageView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        spotImageView.widthAnchor.constraint(equalTo: spotImageView.heightAnchor).isActive = true
    }
    
    func configureTitleView() {
        spotTitleLabel.numberOfLines = 0
        spotTitleLabel.adjustsFontSizeToFitWidth = true
        
        spotTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        spotTitleLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        spotTitleLabel.leadingAnchor.constraint(equalTo: spotImageView.trailingAnchor, constant: 20).isActive = true
        spotTitleLabel.heightAnchor.constraint(equalToConstant: 80).isActive = true
        spotTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12).isActive = true
    }
}
