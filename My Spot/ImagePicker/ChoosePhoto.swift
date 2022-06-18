//
//  ChoosePhoto.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/27/22.
//

import PhotosUI
import SwiftUI

struct ChoosePhoto: UIViewControllerRepresentable {
    let completion: (_ selectedImage: UIImage) -> Void
    @Environment(\.presentationMode) var presentationMode

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
        
        func picker(_: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            for image in results {
                image.itemProvider.loadObject(ofClass: UIImage.self) { selectedImage, error in
                    if let error = error {
                        print(error.localizedDescription)
                        return
                    }
                    
                    guard let uiImage = selectedImage as? UIImage else {
                        return
                    }
                    
                    self.parent.completion(uiImage)
                }
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
