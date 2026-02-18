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
    @State private var pulseRing = false
    
    var body: some View {
        ZStack {
            // Elegant gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.96, blue: 0.93),
                    Color.white,
                    Color.blue.opacity(0.03)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Animated logo
                ZStack {
                    // Pulsing outer ring
                    Circle()
                        .stroke(Color.blue.opacity(0.1), lineWidth: 2)
                        .frame(width: 160, height: 160)
                        .scaleEffect(pulseRing ? 1.1 : 1.0)
                        .opacity(pulseRing ? 0 : 0.5)
                    
                    // Main circle background
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.12), Color.indigo.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                        .scaleEffect(isAnimating ? 1.0 : 0.8)
                    
                    // Book icon with pencil
                    ZStack {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 56, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .indigo],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Image(systemName: "pencil")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.blue.opacity(0.7))
                            .offset(x: 28, y: 28)
                            .rotationEffect(.degrees(isAnimating ? 0 : -15))
                    }
                }
                .scaleEffect(isAnimating ? 1.0 : 0.5)
                .opacity(isAnimating ? 1.0 : 0.0)
                
                // Title and tagline
                VStack(spacing: 12) {
                    Text("The BitBinder")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primary, .primary.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Your comedy companion")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .opacity(showTitle ? 1.0 : 0.0)
                .offset(y: showTitle ? 0 : 15)
                
                // Elegant loading indicator
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.blue.opacity(0.6))
                            .frame(width: 8, height: 8)
                            .scaleEffect(showTitle ? 1.0 : 0.5)
                            .animation(
                                Animation.easeInOut(duration: 0.5)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.15),
                                value: showTitle
                            )
                    }
                }
                .opacity(showTitle ? 1.0 : 0.0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
                isAnimating = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.35)) {
                showTitle = true
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                pulseRing = true
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
