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
            AudioListView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "music.note")
                        .renderingMode(.template)
                        .foregroundStyle(.yellow)
                }
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarBackground(.ultraThickMaterial, for: .tabBar)
            LibraryView()
                .tabItem {
                    Image(systemName: "book.fill")
                        .renderingMode(.template)
                }
        }
        .tint(.white)
        .safeAreaInset(edge: .bottom) {
            CustomBottomSheetview()
        }
        .overlay {
            if expandSheet {
                MusicView(expandSheet: $expandSheet, animation: animation)
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
                Rectangle()
                    .fill(.ultraThickMaterial)
                    .overlay {
                        // Music info
                        MusicInfoView(expandSheet: $expandSheet, animation: animation)
                    }
                    .matchedGeometryEffect(id: "BACKGROUNDVIEW", in: animation)
            }
        }
        .frame(height: 80)
        .offset(y: -49)
    }
}

#Preview {
    MainView()
}
