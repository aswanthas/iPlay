//
//  MainView.swift
//  IPlay
//
//  Created by Aswanth K on 11/07/25.
//

import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = AudioViewModel()
    @State private var expandSheet: Bool = false
    @Namespace private var animation
    var body: some View {
        TabView {
            Section {
                AudioListView(viewModel: viewModel)
                    .tabItem {
                        Image(systemName: "music.note")
                            .renderingMode(.template)
                            .foregroundStyle(.yellow)
                    }
                
                LibraryView()
                    .tabItem {
                        Image(systemName: "play.rectangle.on.rectangle")
                            .renderingMode(.template)
                    }
            }
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarBackground(.ultraThickMaterial, for: .tabBar)
        }
//        .tint(.white)
        .safeAreaInset(edge: .bottom) {
                CustomBottomSheetview()
        }
        .overlay {
            if expandSheet {
                MusicView(expandSheet: $expandSheet, animation: animation, viewModel: viewModel)
            }
        }
    }
    
    @ViewBuilder
    func CustomBottomSheetview() -> some View {
        ZStack {
            if expandSheet {
                Rectangle()
                    .fill(.clear)
            } else {
                if let currentTrack = viewModel.currentTrack {
                    Rectangle()
                        .fill(.ultraThickMaterial)
                        .overlay {
                            // Music info
                            MusicInfoView(expandSheet: $expandSheet, animation: animation,
                                          track: currentTrack,
                                          isPlaying: viewModel.isPlaying,
                                          onPlayPause: {
                                viewModel.togglePlayback(for: currentTrack)
                            }, onNext: {
                                viewModel.playNextTrack()
                            },progress: CGFloat(viewModel.currentPlayer?.currentTime ?? 0) / CGFloat(viewModel.currentPlayer?.duration ?? 1)
)
                        }
                        .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight]))
                        .matchedGeometryEffect(id: "BACKGROUNDVIEW", in: animation)
                }
            }
        }
        .frame(height: 80)
        .offset(y: -49)
    }
}

#Preview {
    MainView()
}
