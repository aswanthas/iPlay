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
                        
                        CircleProgressView()
                            .frame(width: size.width, height: size.height)
                    }
                    .matchedGeometryEffect(id: "SONGCOVER", in: animation)
                }
            }
            .frame(width: 55, height: 55)
            Text("Song title")
                .fontWeight(.semibold)
                .lineLimit(1)
                .padding(.horizontal, 15)
            Spacer()
            Button {
                
            } label: {
                Image(systemName: "pause.fill")
                    .font(.title3)
                    .foregroundStyle(.black)
                    .background(.white)
                    .clipShape(Circle())
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
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.clear, lineWidth: 4)
            Circle()
                .trim(from: 0, to: 0.25)
                .stroke(Color.orange, lineWidth: 4)
                .rotationEffect(.degrees(-90))
        }
    }
}
