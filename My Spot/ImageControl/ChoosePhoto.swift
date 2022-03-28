//
//  ChoosePhoto.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/27/22.
//

import PhotosUI
import SwiftUI

struct ChoosePhoto: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var didCancel: Bool

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {

    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ChoosePhoto

        init(_ parent: ChoosePhoto) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            if let provider = results.first?.itemProvider {
                if provider.canLoadObject(ofClass: UIImage.self) {
                    provider.loadObject(ofClass: UIImage.self) { image, _ in
                        self.parent.image = image as? UIImage
                    }
                } else {
                    parent.didCancel = true
                }
            } else {
                parent.didCancel = true
            }
        }
    }
}
