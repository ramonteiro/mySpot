import SwiftUI
import MapKit

struct SinglePin: Identifiable {
    let id = UUID()
    var name: String
    var coordinate: CLLocationCoordinate2D
}

struct ViewSingleSpotOnMap: View {
    
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @EnvironmentObject var mapViewModel: MapViewModel
    @State private var map = MKMapView()
    @State private var mapImageToggle = "square.2.stack.3d.top.filled"
    let singlePin: [SinglePin]
    let name: String
    
    var body: some View {
        ZStack {
            MapViewSingleSpot(map: $map, region: MKCoordinateRegion(center: singlePin[0].coordinate, span: DefaultLocations.spanClose))
            locationButton
        }
        .frame(maxHeight: UIScreen.screenHeight * 0.4)
        .onAppear {
            if map.annotations.isEmpty {
                let annotation = MKPointAnnotation()
                annotation.coordinate = singlePin[0].coordinate
                annotation.title = name
                map.addAnnotation(annotation)
            }
        }
    }
    
    private var locationButton: some View {
        HStack {
            Spacer()
            VStack {
                displayLocationButton
                Spacer()
                sateliteButton
            }
            .padding()
        }
    }
    
    private var sateliteButton: some View {
        Button {
            toggleMapType()
        } label: {
            Image(systemName: mapImageToggle)
                .font(.title2)
                .foregroundColor(.white)
                .padding(10)
                .frame(width: 50, height: 50)
                .background { cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex] }
                .clipShape(Circle())
        }
    }
    
    private var displayLocationButton: some View {
        Button {
            map.setRegion(MKCoordinateRegion(center: singlePin[0].coordinate, span: DefaultLocations.spanClose), animated: true)
        } label: {
            Image(systemName: "mappin")
                .font(.title2)
                .foregroundColor(.white)
                .padding(10)
                .frame(width: 50, height: 50)
                .background { cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex] }
                .clipShape(Circle())
        }
    }
    
    private func toggleMapType() {
        if map.mapType == .standard {
            map.mapType = .hybrid
            withAnimation {
                mapImageToggle = "square.2.stack.3d.bottom.filled"
            }
        } else {
            map.mapType = .standard
            withAnimation {
                mapImageToggle = "square.2.stack.3d.top.filled"
            }
        }
    }
}

struct MapViewSingleSpot: UIViewRepresentable {
    
    @EnvironmentObject var mapViewModel: MapViewModel
    @Binding var map: MKMapView
    let region: MKCoordinateRegion
    
    func makeUIView(context: Context) -> some MKMapView {
        let mapView = map
        mapView.showsCompass = false
        mapView.showsUserLocation = mapViewModel.isAuthorized
        mapView.setRegion(region, animated: true)
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        private var preventDoubleTrigger = false
        var parent: MapViewSingleSpot
        
        init(_ parent: MapViewSingleSpot) {
            self.parent = parent
        }
        
        private func deselectAllExcept(_ annotation: MKAnnotation) {
            for annotaionToDeselect in parent.map.selectedAnnotations {
                if annotation.coordinate.latitude != annotaionToDeselect.coordinate.latitude &&
                    annotation.coordinate.longitude != annotaionToDeselect.coordinate.longitude &&
                    annotation.title != annotaionToDeselect.title {
                    parent.map.deselectAnnotation(annotaionToDeselect, animated: true)
                }
            }
        }
    }
}
