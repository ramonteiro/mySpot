//
//  DetailView.swift
//  mySpot
//
//  Created by Isaac Paschall on 2/28/22.
//

/*
 DetailView:
 navigation link for each spot from core data item in list in root view
 */

import SwiftUI
import MapKit

struct DetailView: View {
    
    var fromPlaylist: Bool
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var networkViewModel: NetworkMonitor
    @ObservedObject var spot:Spot
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var tabController: TabController
    @State private var showingEditSheet = false
    @State private var scope:String = "Private"
    @State private var tags: [String] = []
    @State private var showingImage = false
    
    var body: some View {
        if (checkExists()) {
            displaySpot
                .onChange(of: tabController.playlistPopToRoot) { _ in
                    if (fromPlaylist) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .onChange(of: tabController.spotPopToRoot) { _ in
                    if (!fromPlaylist) {
                        presentationMode.wrappedValue.dismiss()
                    }
            }
        }
    }
    
    private func checkExists() -> Bool {
        guard let _ = spot.name else {return false}
        guard let _ = spot.locationName else {return false}
        guard let _ = spot.date else {return false}
        guard let _ = spot.details else {return false}
        guard let _ = spot.founder else {return false}
        return true
    }
    
    private var displaySpot: some View {
        ZStack {
            if (isExisting()) {
                ZStack {
                    VStack {
                        Image(uiImage: spot.image!)
                            .resizable()
                            .scaledToFit()
                            .offset(y: -100)
                        Spacer()
                    }
                    detailSheet
                    HStack {
                        Button {
                            withAnimation {
                                showingImage.toggle()
                            }
                        } label: {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 15, weight: .regular))
                                .padding(5)
                                .foregroundColor(.white)
                        }
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .offset(x: 20, y: -80)
                        Spacer()
                        Button {
                            showingEditSheet = true
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 30, weight: .regular))
                                .padding(15)
                                .foregroundColor(.white)
                        }
                        .background(
                            Circle()
                                .foregroundColor(.accentColor)
                                .shadow(color: .black, radius: 5)
                        )
                        .offset(x: -20, y: -60)
                        .sheet(isPresented: $showingEditSheet) {
                            SpotEditSheet(spot: spot)
                        }
                        .disabled(!networkViewModel.hasInternet && spot.isPublic && !cloudViewModel.isSignedInToiCloud)
                    }
                    HStack {
                        VStack {
                            Button {
                                presentationMode.wrappedValue.dismiss()
                            } label: {
                                Image(systemName: "arrow.left")
                                    .foregroundColor(.white)
                                    .font(.system(size: 30, weight: .regular))
                                    .padding(15)
                                    .shadow(color: .black, radius: 5)
                            }
                            .offset(y: 30)
                            Spacer()
                        }
                        Spacer()
                    }
                    if (showingImage) {
                        ImagePopUp(showingImage: $showingImage, image: spot.image!)
                            .transition(.scale)
                    }
                }
                .ignoresSafeArea(.all, edges: .top)
                .onAppear {
                    tags = spot.tags?.components(separatedBy: ", ") ?? []
                    if (spot.isPublic) {
                        scope = "Public"
                    } else {
                        scope = "Private"
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .edgesIgnoringSafeArea(.top)
    }
    
    private var detailSheet: some View {
        ScrollView(showsIndicators: false) {
            
            
            HStack {
                Image(systemName: "mappin")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(Color.gray)
                Text("\(spot.locationName ?? "")")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(Color.gray)
                    .padding(.leading, 1)
                Spacer()
            }
            .padding([.top, .leading, .trailing], 30)
            
            
            HStack {
                Text("\(spot.name!)")
                    .font(.system(size: 45, weight: .heavy))
                Spacer()
            }
            .padding(.leading, 30)
            .padding(.trailing, 5)
            
            HStack {
                Text("By: \(spot.founder!)")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(Color.gray)
                Spacer()
                Text("\(spot.date!)")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(Color.gray)
            }
            .padding([.leading, .trailing], 30)
            
            if (!(spot.tags?.isEmpty ?? true)) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 12, weight: .regular))
                                .lineLimit(2)
                                .foregroundColor(.white)
                                .padding(5)
                                .background(.tint)
                                .cornerRadius(5)
                        }
                    }
                }
                .padding([.leading, .trailing], 30)
                .offset(y: 5)
            }
            HStack(spacing: 5) {
                Text(spot.details!)
                Spacer()
            }
            .padding(.top, 10)
            .padding([.leading, .trailing], 30)
            
            ViewSingleSpotOnMap(singlePin: [SinglePin(name: spot.name!, coordinate: CLLocationCoordinate2D(latitude: spot.x, longitude: spot.y))])
                .aspectRatio(contentMode: .fit)
                .cornerRadius(15)
                .padding([.leading, .trailing], 30)
            
            Button {
                let routeMeTo = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: spot.x, longitude: spot.y)))
                routeMeTo.name = spot.name!
                routeMeTo.openInMaps(launchOptions: nil)
            } label: {
                Text("Take Me To \(spot.name!)")
                    .padding(.horizontal)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 10)
            .padding([.leading, .trailing], 30)
            
            HStack {
                Image(systemName: "globe")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(Color.gray)
                Text("\(scope)")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(Color.gray)
            }
            .padding(.bottom, (100 * UIScreen.screenWidth)/375)
        }
        .frame(maxWidth: .infinity)
        .frame(height: (500 * UIScreen.screenWidth)/375)
        .background(
            RoundedRectangle(cornerRadius: 40)
                .foregroundColor(Color(UIColor.secondarySystemBackground))
                .shadow(color: .black, radius: 5)
        )
        .offset(y: (200 * UIScreen.screenWidth)/375)
    }
    
    private func isExisting() -> Bool {
        if let _ = spot.name {
            return true
        } else {
            return false
        }
    }
}
