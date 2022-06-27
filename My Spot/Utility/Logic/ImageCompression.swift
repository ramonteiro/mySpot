import SwiftUI

class ImageCompression {
    func compress(image: UIImage) -> Data? {
        let resizedImage = image.aspectFittedToHeight(400)
        return resizedImage.jpegData(compressionQuality: 0.5)
    }
}

extension UIImage {
    func aspectFittedToHeight(_ newHeight: CGFloat) -> UIImage {
        let scale = newHeight / self.size.height
        let newWidth = self.size.width * scale
        let newSize = CGSize(width: newWidth, height: newHeight)
        let renderer = UIGraphicsImageRenderer(size: newSize)

        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
