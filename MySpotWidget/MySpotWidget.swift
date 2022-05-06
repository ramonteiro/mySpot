//
//  MySpotWidget.swift
//  MySpotWidget
//
//  Created by Isaac Paschall on 5/4/22.
//

import WidgetKit
import SwiftUI
import CoreLocation
import CloudKit

struct Spot: Identifiable, Codable {
    var id = UUID()
    let spotid: String
    let name: String
    let customLocation: Bool
    let locationName: String
    let image: Data
    let x: Double
    let y: Double
}

struct SpotEntry: TimelineEntry {
    let date = Date()
    let locationName: String
    let userx: Double
    let usery: Double
    let spot: [Spot]
}

struct Provider: TimelineProvider {
    
    var cloudViewModel = CloudKitViewModel()
    var mapViewModel = WidgetLocationManager()
    let emptySpot = SpotEntry(locationName: "Coconino County",userx: 33.71447172967623, usery: -112.29073153451222, spot: [
        Spot(spotid: "", name: "Antelope Canyon", customLocation: false, locationName: "Grand Canyon", image: (UIImage(named: "atelopeCanyon")?.jpegData(compressionQuality: 0.9))!, x: 36.8619, y: -111.3743),
        Spot(spotid: "", name: "South Rim Trail", customLocation: false, locationName: "Grand Canyon", image: (UIImage(named: "southRim")?.jpegData(compressionQuality: 0.9))!, x: 36.056198, y: -112.125198),
        Spot(spotid: "", name: "Havasu Falls", customLocation: false, locationName: "Grand Canyon", image: (UIImage(named: "havasuFalls")?.jpegData(compressionQuality: 0.9))!, x: 36.2552, y: -112.6979),
        Spot(spotid: "", name: "Fire Point", customLocation: false, locationName: "Grand Canyon", image: (UIImage(named: "firePoint")?.jpegData(compressionQuality: 0.9))!, x: 36.3558152, y: -112.3615679)
    ])
    
    func placeholder(in context: Context) -> SpotEntry {
        let entry = emptySpot
        return entry
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SpotEntry) -> Void) {
        if context.isPreview {
            completion(emptySpot)
        } else {
            mapViewModel.fetchLocation { location in
                getPlacmarkOfLocation(location: location) { locationName in
                    cloudViewModel.fetchSpotPublic(userLocation: location, resultLimit: 4) { (result) in
                        switch result {
                        case .success(let entry):
                            completion(SpotEntry(locationName: locationName, userx: location.coordinate.latitude, usery: location.coordinate.longitude, spot: entry))
                        case .failure(let error):
                            print("snapshot Error: \(error)")
                            completion(emptySpot)
                        }
                    }
                }
            }
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SpotEntry>) -> Void) {
        mapViewModel.fetchLocation { location in
            getPlacmarkOfLocation(location: location) { locationName in
                cloudViewModel.fetchSpotPublic(userLocation: location, resultLimit: 4) { (result) in
                    switch result {
                    case .success(let entry):
                        let entry = SpotEntry(locationName: locationName, userx: location.coordinate.latitude, usery: location.coordinate.longitude, spot: entry)
                        let timeline = Timeline(entries: [entry], policy: .atEnd)
                        completion(timeline)
                    case .failure(let error):
                        print("TimeLine Error: \(error)")
                        let timeline = Timeline(entries: [emptySpot], policy: .after(Date().addingTimeInterval(60 * 2)))
                        completion(timeline)
                    }
                }
            }
        }
    }
    
    func getPlacmarkOfLocation(location: CLLocation, completionHandler: @escaping (String) -> Void) {
        let geo = CLGeocoder()
        geo.reverseGeocodeLocation(location) { (placemarker, error) in
            if error == nil {
                let place = placemarker?[0]
                if let sublocal = place?.subLocality {
                    completionHandler(sublocal)
                } else if let local = place?.locality {
                    completionHandler(local)
                } else if let state = place?.administrativeArea {
                    completionHandler(state)
                } else if let country = place?.country {
                    completionHandler(country)
                } else if let ocean = place?.ocean {
                    completionHandler(ocean)
                } else {
                    completionHandler("")
                }
            } else {
                completionHandler("")
            }
        }
    }
}

class WidgetLocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    var locationManager: CLLocationManager?
    private var handler: ((CLLocation) -> Void)?

    override init() {
        super.init()
        DispatchQueue.main.async {
            self.locationManager = CLLocationManager()
            self.locationManager!.delegate = self
            if self.locationManager!.authorizationStatus == .notDetermined {
                self.locationManager!.requestWhenInUseAuthorization()
            }
        }
    }
    
    func fetchLocation(handler: @escaping (CLLocation) -> Void) {
        self.handler = handler
        self.locationManager!.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.handler!(locations.last!)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
}

class CloudKitViewModel: ObservableObject {
    
    let desiredKeys = ["name", "location", "locationName", "customLocation", "image", "userID"]
    
    init() { }
    
    func fetchSpotPublic(userLocation: CLLocation, resultLimit: Int, completion: @escaping (Result<[Spot], Error>) -> ()) {
        var predicate = NSPredicate(value: true)
        if let userid = UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.string(forKey: "userid") {
            predicate = NSPredicate(format: "userID != %@", userid)
        }
        let query = CKQuery(recordType: "Spots", predicate: predicate)
        let distance = CKLocationSortDescriptor(key: "location", relativeLocation: userLocation)
        let creation = NSSortDescriptor(key: "creationDate", ascending: false)
        query.sortDescriptors = [distance, creation]
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.resultsLimit = resultLimit
        var returnedSpots: [Spot] = []
        queryOperation.recordMatchedBlock = { (recordID, result) in
            switch result {
            case .success(let record):
                guard let name = record["name"] as? String else { return }
                guard let image = record["image"] as? CKAsset else { return }
                var customLocation = 0
                if let customLocationChecked = record["customLocation"] as? Int {
                    customLocation = customLocationChecked
                }
                var isCustomLocation = false
                if customLocation == 0 {
                    isCustomLocation = true
                }
                var locationName = ""
                if let locationNameCheck = record["locationName"] as? String {
                    locationName = locationNameCheck
                }
                guard let imageData = try? Data(contentsOf: image.fileURL!) else { return }
                guard let location = record["location"] as? CLLocation else { return }
                let x = location.coordinate.latitude
                let y = location.coordinate.longitude
                returnedSpots.append(Spot(spotid: record.recordID.recordName,name: name, customLocation: isCustomLocation, locationName: locationName, image: imageData, x: x, y: y))
            case .failure(let error):
                print("\(error)")
                completion(.failure(error))
            }
        }
        queryOperation.queryResultBlock = { result in
            print("returned result: \(result)")
            completion(.success(returnedSpots))
        }
        addOperation(operation: queryOperation)
    }
    
    func addOperation(operation: CKDatabaseOperation) {
        CKContainer(identifier: "iCloud.com.isaacpaschall.My-Spot").publicCloudDatabase.add(operation)
    }
}

struct WidgetEntryView: View {
    let entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    @ViewBuilder
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            LargeWidgetView(entry: entry)
        }
    }
}

struct LargeWidgetView: View {
    let entry: Provider.Entry
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.black : Color.white)
            VStack(spacing: 5) {
                WidgetHeader(locationName: "Near ".localized() + entry.locationName)
                    .padding(.vertical, 5)
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        WidgetTile(spot: entry.spot[0], userx: entry.userx, usery: entry.usery)
                            .padding([.horizontal, .bottom], 5)
                        WidgetTile(spot: entry.spot[1], userx: entry.userx, usery: entry.usery)
                            .padding([.horizontal, .bottom], 5)
                    }
                    HStack(spacing: 0) {
                        WidgetTile(spot: entry.spot[2], userx: entry.userx, usery: entry.usery)
                            .padding([.horizontal, .bottom], 5)
                        WidgetTile(spot: entry.spot[3], userx: entry.userx, usery: entry.usery)
                            .padding([.horizontal, .bottom], 5)
                    }
                }
            }
        }
    }
}

struct MediumWidgetView: View {
    let entry: Provider.Entry
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.black : Color.white)
            VStack(spacing: 5) {
                WidgetHeader(locationName: "Near ".localized() + entry.locationName)
                    .padding(.vertical, 5)
                HStack(spacing: 0) {
                    WidgetTile(spot: entry.spot[0], userx: entry.userx, usery: entry.usery)
                        .padding([.horizontal, .bottom], 5)
                    WidgetTile(spot: entry.spot[1], userx: entry.userx, usery: entry.usery)
                        .padding([.horizontal, .bottom], 5)
                }
            }
        }
    }
}

struct SmallWidgetView: View {
    let entry: Provider.Entry
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.black : Color.white)
            VStack(spacing: 5) {
                WidgetHeader(locationName: entry.locationName)
                    .padding(.vertical, 5)
                HStack(spacing: 0) {
                    WidgetTile(spot: entry.spot[0], userx: entry.userx, usery: entry.usery)
                        .padding([.horizontal, .bottom], 5)
                }
            }
        }
        .widgetURL(URL(string: "myspot://" + (entry.spot[0].spotid))!)
    }
}

struct WidgetHeader: View {
    
    let locationName: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Text(locationName)
                .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                .font(.system(size: 14))
                .fontWeight(.bold)
                .lineLimit(1)
                .padding(.leading, 15)
            Spacer()
            Image(uiImage: UIImage(named: "logo.png")!)
                .resizable()
                .frame(width: 20, height: 20)
                .scaledToFit()
                .padding(.trailing, 15)
        }
    }
}

struct WidgetTile: View {
    
    let spot: Spot
    let userx: Double
    let usery: Double
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                HStack(spacing: 0) {
                    Link(destination: URL(string: "myspot://" + (spot.spotid))!) {
                        Image(uiImage: (UIImage(data: spot.image) ?? UIImage(systemName: "exclamationmark.triangle"))!)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                    }
                }
                VStack(alignment: .leading, spacing: 0) {
                    if (!(spot.locationName.isEmpty)) {
                        HStack {
                            locationName
                            Spacer()
                        }
                        HStack {
                            distanceAway
                            Spacer()
                        }
                    } else {
                        HStack {
                            distanceAway
                            Spacer()
                        }
                    }
                    Spacer()
                    Text(spot.name)
                        .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                        .font(.system(size: 16))
                        .fontWeight(.bold)
                        .padding(.bottom, 10)
                        .lineLimit(1)
                        .frame(width: geo.size.width)
                        .background(.ultraThinMaterial)
                }
                .frame(width: geo.size.width)
            }
            .cornerRadius(20)
        }
    }
    
    private var locationName: some View {
        HStack(spacing: 5) {
            Image(systemName: (!spot.customLocation ? "mappin" : "figure.wave"))
                .font(.system(size: 12))
                .foregroundColor(.white)
                .lineLimit(1)
                .shadow(color: .black, radius: 0.4)
            Text(spot.locationName)
                .font(.system(size: 12))
                .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                .lineLimit(1)
                .shadow(color: .black, radius: 0.4)
        }
        .padding(.leading, 10)
    }
    
    private var distanceAway: some View {
        Text(calculateDistance(x: spot.x, y: spot.y))
            .foregroundColor(.white)
            .font(.system(size: 12))
            .lineLimit(1)
            .shadow(radius: 4)
            .padding(.leading, 10)
            .shadow(color: .black, radius: 0.4)
    }
    
    private func calculateDistance(x: Double, y: Double) -> String {
        let userLocation = CLLocation(latitude: userx, longitude: usery)
        let spotLocation = CLLocation(latitude: x, longitude: y)
        let distanceInMeters = userLocation.distance(from: spotLocation)
        if isMetric() {
            let distanceDouble = distanceInMeters / 1000
            if distanceDouble >= 99 {
                return "99+ km"
            }
            if distanceDouble >= 10 {
                return String(Int(distanceDouble)) + " km"
            }
            return String(format: "%.1f", distanceDouble) + " km"
        } else {
            let distanceDouble = distanceInMeters / 1609.344
            if distanceDouble >= 99 {
                return "99+ mi"
            }
            if distanceDouble >= 10 {
                return String(Int(distanceDouble)) + " mi"
            }
            return String(format: "%.1f", distanceDouble) + " mi"
        }
        
    }
    
    private func isMetric() -> Bool {
        return ((Locale.current as NSLocale).object(forKey: NSLocale.Key.usesMetricSystem) as? Bool) ?? true
    }
    
}

@main
struct WidgetMain: Widget {
    private let kind = "MySpotWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Spots Near Me")
        .description("Shows Spots Closest To You")
        .supportedFamilies([.systemLarge, .systemSmall, .systemMedium])
    }
}

extension String {
    func localized() -> String {
        return NSLocalizedString(self, tableName: "Localizable", bundle: .main, value: self, comment: self)
    }
}
