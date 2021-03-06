//
//  PullToRefresh.swift
//  My Spot
//
//  Created by Isaac Paschall on 6/18/22.
//

import SwiftUI

struct PullToRefresh: View {
    
    var coordinateSpaceName: String
    var onRefresh: ()->Void
    
    @State var needRefresh: Bool = false
    
    var body: some View {
        GeometryReader { geo in
            if (geo.frame(in: .named(coordinateSpaceName)).midY > 50) {
                Spacer()
                    .onAppear {
                        needRefresh = true
                    }
            } else if (geo.frame(in: .named(coordinateSpaceName)).maxY < 10) {
                Spacer()
                    .onAppear {
                        if needRefresh {
                            needRefresh = false
                            onRefresh()
                        }
                    }
            }
            loadingViewSpinner
        }
        .padding(.top, -50)
    }
    
    private var loadingViewSpinner: some View {
        HStack {
            Spacer()
            if needRefresh {
                ProgressView()
            } else {
                Image(systemName: "arrow.down")
            }
            Spacer()
        }
    }
}
