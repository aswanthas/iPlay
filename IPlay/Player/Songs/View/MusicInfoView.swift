//
//  MusicInfoView.swift
//  IPlay
//
//  Created by Aswanth K on 11/07/25.
//

import SwiftUI

struct MusicInfoView: View {
    @Binding var expandSheet: Bool
    var animation: Namespace.ID
    let track: AudioTrack
    let isPlaying: Bool
    let onPlayPause: () -> Void
    let onNext: () -> Void
    let progress: CGFloat // Add this

    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                if !expandSheet {
                    GeometryReader {
                        let size = $0.size
                        Image(.musicSmpl)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size.width, height: size.height)
                            .clipShape(.rect(cornerRadius: 60, style: .continuous))
                        
                        CircleProgressView(progress: progress)
                            .frame(width: size.width, height: size.height)
                    }
                    .matchedGeometryEffect(id: "SONGCOVER", in: animation)
                }
            }
            .frame(width: 55, height: 55)
            
            Text(track.title ?? "Unknown")
                .fontWeight(.semibold)
                .lineLimit(1)
                .padding(.horizontal, 15)
            Spacer()
            
            Button {
                onPlayPause()
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
                    .foregroundStyle(Color.white)
            }
            .padding(.trailing, 8)
            
            Button(action: onNext) {
                Image(systemName: "forward.fill")
                    .font(.title3)
                    .foregroundStyle(Color.white)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal)
        .frame(height: 80)
        .contentShape(.rect(topLeadingRadius: 30, topTrailingRadius: 30))
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
            expandSheet = true
            }
        }
    }
}

#Preview {
    MainView()
}

struct CircleProgressView: View {
    var progress: CGFloat // range: 0.0 to 1.0
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.clear, lineWidth: 4)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.orange, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
