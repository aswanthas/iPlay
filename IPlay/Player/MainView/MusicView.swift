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
    
    @State private var animationContent: Bool = true
    @State private var offsetY: CGFloat = 0
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
                        MusicInfoView(expandSheet: $expandSheet, animation: animation)
                            .allowsHitTesting(false)
                            .opacity(animationContent ? 0 : 1)
                        
                    }
                    .matchedGeometryEffect(id: "BACKGROUNDVIEW", in: animation)
                
                LinearGradient(gradient: Gradient(colors: [Color.orange.opacity(0.5), Color.clear]), startPoint: .top, endPoint: .bottom)
                    .frame(height: 300)
                
                VStack(spacing: 15) {
                    HStack {
                        Image(systemName: "chevron.down")
                            .imageScale(.large)
                            .onTapGesture {
                                expandSheet = false
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
                    }
                    .matchedGeometryEffect(id: "SONGCOVER", in: animation)
                    .frame(height: size.width - 50)
                    .padding(.vertical, size.height < 700 ? 30 : 40)
                    .padding(.horizontal)
                }
                .padding(.top, safeArea.top + (safeArea.bottom == 0 ? 10 : 0))
                .padding(.bottom, safeArea.bottom == 0 ? 10 : safeArea.bottom)
                .padding(.horizontal, 15)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.36)) {
                        expandSheet.toggle()
                        animationContent.toggle()
                    }
                }
            }
            .contentShape(Rectangle())
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
