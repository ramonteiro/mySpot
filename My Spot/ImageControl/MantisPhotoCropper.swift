//
//  MantisPhotoCropper.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/27/22.
//

import SwiftUI
import Mantis

struct MantisPhotoCropper: UIViewControllerRepresentable {
    
    typealias Coordinator = MantisPhotoCropperCoordinator
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @Binding var selectedImage: UIImage?
    
    func makeCoordinator() -> MantisPhotoCropperCoordinator {
        return MantisPhotoCropperCoordinator(self)
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<MantisPhotoCropper>) -> Mantis.CropViewController {
        var config = Mantis.Config()
        config.presetFixedRatioType = .alwaysUsingOnePresetFixedRatio(ratio: 1.0)
        config.showRotationDial = false
        if let image = selectedImage {
            let editor = Mantis.cropViewController(image: image, config: config)
            editor.delegate = context.coordinator
            return editor
        }
        cloudViewModel.isErrorMessage = "Unable To Load Image".localized()
        cloudViewModel.isErrorMessageDetails = "This error is unknown. Please try again.".localized()
        cloudViewModel.isError.toggle()
        let editor = Mantis.cropViewController(image: defaultImages.errorImage!, config: config)
        editor.delegate = context.coordinator
        return editor
    }
}

class MantisPhotoCropperCoordinator: NSObject, CropViewControllerDelegate {
    
    var parent: MantisPhotoCropper
    
    init(_ parent:MantisPhotoCropper) {
        self.parent = parent
    }
    
    func cropViewControllerDidCrop(_ cropViewController: CropViewController, cropped: UIImage, transformation: Transformation, cropInfo: CropInfo) {
        parent.selectedImage = cropped
        parent.presentationMode.wrappedValue.dismiss()
    }
    
    func cropViewControllerDidFailToCrop(_ cropViewController: CropViewController, original: UIImage) {
        
    }
    
    func cropViewControllerDidCancel(_ cropViewController: CropViewController, original: UIImage) {
        parent.selectedImage = nil
        parent.presentationMode.wrappedValue.dismiss()
    }
    
    func cropViewControllerDidBeginResize(_ cropViewController: CropViewController) {
        
    }
    
    func cropViewControllerDidEndResize(_ cropViewController: CropViewController, original: UIImage, cropInfo: CropInfo) {
        
    }
    
    
}
