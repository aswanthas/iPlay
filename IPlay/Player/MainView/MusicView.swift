//
//  MusicView.swift
//  IPlay
//
//  Created by Aswanth K on 12/07/25.
//

import SwiftUI

struct MusicView: View {
    @Binding var expandSheet: Bool
    var animation: Namespace.ID
    @ObservedObject var viewModel: AudioViewModel
    
    @State private var animationContent: Bool = true
    @State private var offsetY: CGFloat = 0
    
    @State private var isSeeking = false
    @State private var seekPosition: TimeInterval = 0
    
    var body: some View {
        GeometryReader {
            let size = $0.size
            let safeArea = $0.safeAreaInsets
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: animationContent ? deviceCornerRadius : 0, style: .continuous)
                    .fill(.ultraThickMaterial)
                    .overlay {
                        Rectangle()
                            .fill(.gray.opacity(0.4))
                            .opacity(animationContent ? 1 : 0)
                    }
                    .overlay(alignment: .top) {
                        if let currentTrack = viewModel.currentTrack {
                            MusicInfoView(expandSheet: $expandSheet, animation: animation,
                                          track: currentTrack,
                                          isPlaying: viewModel.isPlaying,
                                          onPlayPause: {
                                viewModel.togglePlayback(for: currentTrack)
                            }, onNext: {
                                viewModel.playNextTrack()
                            }, progress: CGFloat(viewModel.currentPlayer?.currentTime ?? 0) / CGFloat(viewModel.currentPlayer?.duration ?? 1))
                            .allowsHitTesting(false)
                            .opacity(animationContent ? 0 : 1)
                        }
                        
                    }
                    .matchedGeometryEffect(id: "BACKGROUNDVIEW", in: animation)
                
                LinearGradient(gradient: Gradient(colors: [Color.orange.opacity(0.5), Color.clear]), startPoint: .top, endPoint: .bottom)
                    .frame(height: 300)
                
                VStack(spacing: 15) {
                    HStack {
                        Image(systemName: "chevron.down")
                            .imageScale(.large)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.34)) {
                                    expandSheet = false
                                }
                            }
                        Spacer()
                    }.padding(.horizontal)
                        .padding(.top, 60)
                    
                    GeometryReader {
                        let size = $0.size
                        Image(.musicSmpl)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size.width, height: size.height)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: animationContent ? 30 : 60, style: .continuous))
//                            .rotationEffect(.degrees(viewModel.rotationAngle))
//                            .animation(.linear(duration: 0.02), value: viewModel.rotationAngle)
                    }
                    .matchedGeometryEffect(id: "SONGCOVER", in: animation)
                    .frame(height: size.width - 50)
                    .padding(.vertical, size.height < 700 ? 30 : 40)
                    .padding(.horizontal)
                    
                    playerView(size)
                        .offset(y: animationContent ? 0 : size.height)
                }
                .padding(.top, safeArea.top + (safeArea.bottom == 0 ? 10 : 0))
                .padding(.bottom, safeArea.bottom == 0 ? 10 : safeArea.bottom)
                .padding(.horizontal, 15)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        expandSheet.toggle()
                        animationContent.toggle()
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: animationContent ? deviceCornerRadius : 0, style: .continuous))
            .offset(y: offsetY)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let transitionY = value.translation.height
                        offsetY = (transitionY > 0 ? transitionY : 0)
                    }.onEnded({ value in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if offsetY > size.height * 0.4 {
                                expandSheet = false
                                animationContent = false
                            } else {
                                offsetY = .zero
                            }
                        }
                    })
            )
            .ignoresSafeArea(.container, edges: .all)
        }
        .ignoresSafeArea(.all)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.3)) {
                animationContent = true
            }
        }
    }
    
    @ViewBuilder
    private func playerView(_ mainSize: CGSize) -> some View {
        GeometryReader { geometry in
            let spacing = geometry.size.height * 0.04
            if let track = viewModel.currentTrack,
               let player = viewModel.currentPlayer {
                
                VStack(spacing: spacing, content: {
                    VStack(spacing: spacing, content: {
                        VStack(alignment: .center, spacing: 15) {
                            Text(viewModel.currentTrack?.title ?? "Unknown")
                                .font(.title2)
                                .fontWeight(.semibold)
                         
                            // Seek Slider & Time Labels
                            VStack(spacing: 6) {
                                Slider(
                                    value: Binding(
                                        get: {
                                            isSeeking ? seekPosition : viewModel.playbackTime
                                        },
                                        set: { newValue in
                                            seekPosition = newValue
                                            isSeeking = true
                                        }
                                    ),
                                    in: 0...(viewModel.currentPlayer?.duration ?? 1),
                                    onEditingChanged: { editing in
                                        if !editing {
                                            viewModel.seek(to: seekPosition)
                                            isSeeking = false
                                        }
                                    }
                                )
                                .accentColor(.orange)
                                
                                HStack {
                                    Text(formatTime(viewModel.playbackTime))
                                    Spacer()
                                    Text(formatTime(viewModel.currentPlayer?.duration ?? 0))
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)
                            
                            // Playback controls
                            HStack(spacing: 35) {
                                
                                Button {
                                    // Toggle shuffle logic
                                } label: {
                                    Image(systemName: "shuffle")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                }
                                
                                Button {
                                    viewModel.playPreviousTrack()
                                } label: {
                                    Image(systemName: "backward.fill")
                                        .font(.title)
                                        .foregroundStyle(.white)
                                }
                                
                                Button {
                                    viewModel.togglePlayback(for: track)
                                } label: {
                                    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 54))
                                        .foregroundStyle(.white)
                                }
                                
                                Button {
                                    viewModel.playNextTrack()
                                } label: {
                                    Image(systemName: "forward.fill")
                                        .font(.title)
                                        .foregroundStyle(.white)
                                }
                                
                                Button {
                                    // Toggle repeat logic
                                } label: {
                                    Image(systemName: "repeat")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                }
                            }
                            .padding(.top, 5)
                        }
                    })
                })
            }
        }
    }
}

#Preview {
    MainView()
}

extension View {
    var deviceCornerRadius: CGFloat {
        let key = "_displayCornerRadius"
        if let screen = (UIApplication.shared.connectedScenes.first as?
                         UIWindowScene)?.windows.first?.screen {
            if let cornerRadius = screen.value(forKey: key) as? CGFloat {
                return cornerRadius
            }
            return 0
        }
        return 0
    }
}

private func formatTime(_ time: TimeInterval) -> String {
    let minutes = Int(time) / 60
    let seconds = Int(time) % 60
    return String(format: "%d:%02d", minutes, seconds)
}
