//
//  NetworkMonitor.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/14/22.
//

/*
 monitors network connection
 */
import Foundation
import Network
 
final class NetworkMonitor: ObservableObject {
    let monitor = NWPathMonitor()
    let queue = DispatchQueue(label: "Monitor")
     
    @Published var hasInternet = true
     
    init() {
        monitor.pathUpdateHandler =  { [weak self] path in
            DispatchQueue.main.async {
                self?.hasInternet = path.status == .satisfied ? true : false
            }
        }
        monitor.start(queue: queue)
    }
}
