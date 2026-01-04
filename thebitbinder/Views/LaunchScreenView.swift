//
//  LaunchScreenView.swift
//  thebitbinder
//
//  Created on 12/3/25.
//

import SwiftUI

struct LaunchScreenView: View {
    @State private var isAnimating = false
    @State private var showTitle = false
    
    var body: some View {
        ZStack {
            // Clean gradient background
            LinearGradient(
                colors: [Color.blue.opacity(0.05), Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Modern logo
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 140, height: 140)
                        .scaleEffect(isAnimating ? 1.0 : 0.8)
                    
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 60, weight: .medium))
                        .foregroundStyle(.blue)
                        .overlay(alignment: .bottomTrailing) {
                            Image(systemName: "pencil")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(.blue.opacity(0.7))
                                .offset(x: 10, y: 10)
                        }
                }
                .scaleEffect(isAnimating ? 1.0 : 0.5)
                .opacity(isAnimating ? 1.0 : 0.0)
                
                VStack(spacing: 8) {
                    Text("The BitBinder")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Text("Your comedy companion")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .opacity(showTitle ? 1.0 : 0.0)
                .offset(y: showTitle ? 0 : 10)
                
                // Minimal loading indicator
                ProgressView()
                    .tint(.blue)
                    .scaleEffect(1.2)
                    .opacity(showTitle ? 1.0 : 0.0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isAnimating = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                showTitle = true
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
