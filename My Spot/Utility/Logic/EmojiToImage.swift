//
//  EmojiToImage.swift
//  My Spot
//
//  Created by Isaac Paschall on 6/18/22.
//

import UIKit

extension String {
    func image() -> Data? {
        let size = CGSize(width: 45, height: 45)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.clear.set()
        let rect = CGRect(origin: .zero, size: size)
        UIRectFill(CGRect(origin: .zero, size: size))
        (self as AnyObject).draw(in: rect, withAttributes: [.font: UIFont.systemFont(ofSize: 40)])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if let imageData = image?.pngData() {
            return imageData
        }
        return nil
    }
}
