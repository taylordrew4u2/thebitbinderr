//
//  LaunchScreenView.swift
//  thebitbinder
//
//  Created on 12/3/25.
//

import SwiftUI

struct LaunchScreenView: View {
    @State private var logoScale: CGFloat = 0.7
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.8
    @State private var ringRotation: Double = 0
    
    private let primaryGradient = [Color(red: 0.3, green: 0.5, blue: 1.0), Color(red: 0.5, green: 0.3, blue: 0.9)]
    
    var body: some View {
        ZStack {
            // Modern gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.97, blue: 1.0),
                    Color.white,
                    Color(red: 0.95, green: 0.96, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Animated logo
                ZStack {
                    // Rotating ring
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [primaryGradient[0].opacity(0.3), primaryGradient[1].opacity(0.1), primaryGradient[0].opacity(0.3)],
                                center: .center
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 140, height: 140)
                        .scaleEffect(ringScale)
                        .rotationEffect(.degrees(ringRotation))
                    
                    // Main logo circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: primaryGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: primaryGradient[0].opacity(0.4), radius: 20, y: 10)
                    
                    // Book icon
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundColor(.white)
                    
                    // Pencil accent
                    Image(systemName: "pencil")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .offset(x: 30, y: 30)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                
                // Title
                VStack(spacing: 8) {
                    Text("The BitBinder")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: primaryGradient,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Your comedy companion")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .opacity(textOpacity)
                
                // Loading dots
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(primaryGradient[0].opacity(0.5))
                            .frame(width: 8, height: 8)
                            .scaleEffect(textOpacity > 0 ? 1 : 0.5)
                            .animation(
                                Animation.easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.15),
                                value: textOpacity
                            )
                    }
                }
                .opacity(textOpacity)
                .padding(.top, 8)
            }
        }
        .onAppear {
            // Logo animation
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            
            // Ring animation
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                ringScale = 1.0
            }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
            
            // Text animation
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                textOpacity = 1.0
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
