//
//  MessagesViewController.swift
//  mySpotiMsg
//
//  Created by Isaac Paschall on 5/25/22.
//

import UIKit
import SwiftUI
import MapKit
import Messages

class MessagesViewController: MSMessagesAppViewController, UITableViewDelegate, UITableViewDataSource {
    
    // Data model: These strings will be the data for the table view cells
    var spots: [msgSpot] = []
    
    // cell reuse id (cells that scroll out of view can be reused)
    let cellReuseIdentifier = "cell"
    
    var tableView = UITableView()
    var noSpotsMessage = UILabel()
    
    var imageView = UIImageView()
    weak var snapshotter: MKMapSnapshotter?
    
    var spotLocationCoord: CLLocationCoordinate2D?
    var spotLocationName: String?
    var spotLocationLocationName: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - UI
    
    func configureTableView() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 100
        tableView.register(SpotCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        tableView.pin(to: view)
        if spots.count == 0 {
            view.addSubview(noSpotsMessage)
            noSpotsMessage.text = "No Spots Here Yet!".localized()
            noSpotsMessage.textAlignment = .center
            noSpotsMessage.pin(to: tableView)
            noSpotsMessage.layer.zPosition = 100
            noSpotsMessage.center.x = view.center.x
            noSpotsMessage.center.y = view.center.y
        }
    }
    
    // number of rows in table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return spots.count
    }
    
    // create a cell for each table view row
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: SpotCell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as! SpotCell
        let spot = spots[indexPath.row]
        cell.set(spot: spot)
        cell.selectionStyle = .none
        return cell
    }
    
    // method to run when table view cell is tapped
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let entry = spots[indexPath.row]
        
        let layout = MSMessageTemplateLayout()
        layout.caption = entry.name
        layout.subcaption = (entry.locationName.isEmpty ? "My Spot" : entry.locationName)
        layout.image = entry.image
        let message = MSMessage()
        var urlComponents = URLComponents()
        urlComponents.queryItems = [URLQueryItem(name: "name", value: "\(entry.name)"), URLQueryItem(name: "x", value: "\(entry.x)"), URLQueryItem(name: "y", value: "\(entry.y)"), URLQueryItem(name: "location", value: "\(entry.locationName)")]
        message.url = urlComponents.url
        let liveLayout = MSMessageLiveLayout(alternateLayout: layout)
        message.layout = liveLayout
        if (self.activeConversation != nil) {
            self.activeConversation?.insert(message, completionHandler: nil)
        } else {
            print("No convo")
        }
    }
    
    func configureTranscriptView(url: URL?) {
        guard let url = url else { return }
        spotLocationCoord = CLLocationCoordinate2D(latitude: Double(url.valueOf("x") ?? "47.6153") ?? 47.6153, longitude: Double(url.valueOf("y") ?? "-122.33") ?? -122.33)
        spotLocationName = url.valueOf("name")
        spotLocationLocationName = url.valueOf("location")
        view.addSubview(imageView)
        view.addSubview(createPin())
        view.addSubview(createBanner())
        view.addSubview(createSubBanner())
        imageView.frame = view.frame
        imageView.pin(to: view)
        if let spotLocationCoord = spotLocationCoord {
            takeSnapshot(of: spotLocationCoord)
        }
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap))
        view.addGestureRecognizer(tapGesture)
    }
    
    func createPin() -> UIView {
        let pinImage = UIImageView(image: UIImage(systemName: "mappin"))
        pinImage.tintColor = UIColor(myColor())
        pinImage.layer.zPosition = 100
        pinImage.frame = CGRect(x: 217/2 - 15, y: 217/2 - 20, width: 30, height: 40)
        return pinImage
    }
    
    func createBanner() -> UIView {
        let nameLabel = UILabel()
        nameLabel.text = spotLocationName ?? "My Spot"
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 0
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.textColor = .white
        nameLabel.backgroundColor = UIColor(myColor())
        nameLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        nameLabel.frame = CGRect(x: 0, y: 217 - 40, width: 217, height: 25)
        nameLabel.layer.zPosition = 200
        return nameLabel
    }
    
    func myColor() -> Color {
        let systemColorArray: [Color] = [.red,.green,.pink,.blue,.indigo,.mint,.orange,.purple,.teal,.yellow, .gray]
        return (!(UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.valueExists(forKey: "colora") ?? false) ? .red :
                    ((UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.integer(forKey: "colorIndex") ?? 0) != systemColorArray.count - 1) ? systemColorArray[UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.integer(forKey: "colorIndex") ?? 0] : Color(uiColor: UIColor(red: (UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.double(forKey: "colorr") ?? 0), green: (UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.double(forKey: "colorg") ?? 0), blue: (UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.double(forKey: "colorb") ?? 0), alpha: (UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.double(forKey: "colora") ?? 0))))
    }
    
    func createSubBanner() -> UIView {
        let nameLabel = UILabel()
        nameLabel.text = spotLocationLocationName ?? "?"
        nameLabel.textAlignment = .center
        nameLabel.textColor = .white
        nameLabel.numberOfLines = 0
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.backgroundColor = UIColor(myColor())
        nameLabel.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
        nameLabel.frame = CGRect(x: 0, y: 217 - 15, width: 217, height: 15)
        nameLabel.layer.zPosition = 300
        return nameLabel
    }
    
    @objc func didTap() {
        guard let location = spotLocationCoord else { return }
        guard let name = spotLocationName else { return }
        let routeMeTo = MKMapItem(placemark: MKPlacemark(coordinate: location))
        routeMeTo.name = name
        routeMeTo.openInMaps(launchOptions: nil)
    }
    
    override func contentSizeThatFits(_ size: CGSize) -> CGSize {
        if presentationStyle != .compact && presentationStyle != .expanded {
            let contentHeight: CGFloat = 217.0
            return CGSize(width: contentHeight, height: contentHeight)
        } else {
            return size
        }
    }
    
    func takeSnapshot(of location: CLLocationCoordinate2D) {
        snapshotter?.cancel()
        
        let options = MKMapSnapshotter.Options()
        
        options.region = MKCoordinateRegion(center: location, span: DefaultLocations.spanSuperClose)
        options.mapType = .standard
        options.showsBuildings = true
        options.size = CGSize(width: 217, height: 217)
        
        let snapshotter = MKMapSnapshotter(options: options)
        
        snapshotter.start() { snapshot, _ in
            self.imageView.image = snapshot?.image
        }
        
        self.snapshotter = snapshotter
    }
    
    // MARK: - Data Handling
    func syncFromAppGroups() {
        let userDefaults = UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")
        if let spotCount = userDefaults?.integer(forKey: "spotCount") {
            if spotCount != spots.count {
                guard let xArr: [Double] = userDefaults?.object(forKey: "spotXs") as? [Double] else { return }
                guard let yArr: [Double] = userDefaults?.object(forKey: "spotYs") as? [Double] else { return }
                guard let nameArr: [String] = userDefaults?.object(forKey: "spotNames") as? [String] else { return }
                guard let locationNameArr: [String] = userDefaults?.object(forKey: "spotLocationName") as? [String] else { return }
                guard let imgArr: [Data] = userDefaults?.object(forKey: "spotImgs") as? [Data] else { return }
                for i in imgArr.indices {
                    let decoded = try! PropertyListDecoder().decode(Data.self, from: imgArr[i])
                    let image = UIImage(data: decoded)!
                    let x = xArr[i]
                    let y = yArr[i]
                    let name = nameArr[i]
                    let newSpot = msgSpot(name: name, image: image, x: x, y: y, locationName: (locationNameArr[i].isEmpty ? "My Spot" : locationNameArr[i]))
                    spots.append(newSpot)
                }
            }
        }
    }
    
    // MARK: - Conversation Handling
    
    override func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation)
        syncFromAppGroups()
        updatePresentation(for: conversation)
    }
    
    func updatePresentation(for conversation: MSConversation) {
        if let url = conversation.selectedMessage?.url {
            presentViewController(for: url, with: presentationStyle)
        } else {
            presentViewController(for: nil, with: presentationStyle)
        }
    }
    
    func presentViewController(for url: URL?, with presentationStyle: MSMessagesAppPresentationStyle) {
        removeAllChildViewControllers()
        
        switch presentationStyle {
        case .compact:
            configureTableView()
        case .expanded:
            configureTableView()
        case .transcript:
            configureTranscriptView(url: url)
        @unknown default:
            configureTableView()
        }
    }
    
    func removeAllChildViewControllers() {
        for view in self.view.subviews {
            view.removeFromSuperview()
        }
    }
    
    override func didResignActive(with conversation: MSConversation) {
        // Called when the extension is about to move from the active to inactive state.
        // This will happen when the user dismisses the extension, changes to a different
        // conversation or quits Messages.
        
        // Use this method to release shared resources, save user data, invalidate timers,
        // and store enough state information to restore your extension to its current state
        // in case it is terminated later.
    }
    
    
    
    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        // Called when a message arrives that was generated by another instance of this
        // extension on a remote device.
        
        // Use this method to trigger UI updates in response to the message.
    }
    
    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user taps the send button.
    }
    
    override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user deletes the message without sending it.
        
        // Use this to clean up state related to the deleted message.
    }
    
    override func willTransition(to newPresentationStyle: MSMessagesAppPresentationStyle) {
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called after the extension transitions to a new presentation style.
        
        // Use this method to finalize any behaviors associated with the change in presentation style.
    }
}
