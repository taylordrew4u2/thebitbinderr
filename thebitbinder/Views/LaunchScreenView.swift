//
//  LaunchScreenView.swift
//  thebitbinder
//
//  Created on 12/3/25.
//

import SwiftUI

struct LaunchScreenView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // App Icon/Logo
                Image(systemName: "book.closed")
                    .font(.system(size: 80))
                    .foregroundColor(.black)
                    .overlay(
                        Image(systemName: "pencil")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                            .offset(x: 30, y: 30)
                    )
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                    .opacity(isAnimating ? 1.0 : 0.0)
                
                Text("The BitBinder")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .opacity(isAnimating ? 1.0 : 0.0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
        }
    }
}

// Responsive modifier for different screen sizes
private extension LaunchScreenView {
    var iconSize: CGFloat {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            return 120
        }
        #endif
        return 80
    }
    
    var titleSize: CGFloat {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            return 48
        }
        #endif
        return 32
    }
}

#Preview {
    LaunchScreenView()
}
