//
//  AppTheme.swift
//  thebitbinder
//
//  Created on 2/18/26.
//

import SwiftUI

// MARK: - App Theme
/// Centralized design system for consistent styling across the app
struct AppTheme {
    
    // MARK: - Colors
    struct Colors {
        // Primary brand colors
        static let primary = Color.blue
        static let secondary = Color.indigo
        static let accent = Color.purple
        
        // Notebook/paper theme
        static let paperBackground = Color(UIColor.systemBackground)
        static let notebookSpine = Color(red: 0.55, green: 0.35, blue: 0.22) // Warm leather brown
        static let notebookSpineLight = Color(red: 0.65, green: 0.45, blue: 0.32)
        static let notebookPaper = Color(red: 0.98, green: 0.96, blue: 0.92) // Cream paper
        static let marginLine = Color.red.opacity(0.25)
        static let ruledLine = Color.blue.opacity(0.1)
        
        // UI colors
        static let cardBackground = Color(UIColor.secondarySystemBackground)
        static let subtleBackground = Color.blue.opacity(0.08)
        static let dimOverlay = Color.black.opacity(0.35)
        
        // Gradients
        static let primaryGradient = LinearGradient(
            colors: [Color.blue, Color.indigo],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let accentGradient = LinearGradient(
            colors: [Color.blue, Color.purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let notebookGradient = LinearGradient(
            colors: [notebookSpine, notebookSpineLight],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        static let warmPaperGradient = LinearGradient(
            colors: [notebookPaper, Color.white],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold)
        static let body = Font.system(size: 17, weight: .regular)
        static let caption = Font.system(size: 13, weight: .regular)
        static let small = Font.system(size: 11, weight: .medium)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct Radius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 10
        static let large: CGFloat = 16
        static let xl: CGFloat = 24
    }
    
    // MARK: - Shadows
    struct Shadows {
        static func soft(color: Color = .black.opacity(0.1)) -> some View {
            EmptyView()
        }
        
        static let cardShadow = (color: Color.black.opacity(0.08), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
        static let floatingShadow = (color: Color.blue.opacity(0.3), radius: CGFloat(12), x: CGFloat(0), y: CGFloat(6))
        static let menuShadow = (color: Color.black.opacity(0.15), radius: CGFloat(20), x: CGFloat(-8), y: CGFloat(0))
    }
}

// MARK: - Reusable View Components

/// Floating action button with consistent styling
struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    var gradient: LinearGradient = AppTheme.Colors.accentGradient
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(gradient)
                .clipShape(Circle())
                .shadow(
                    color: AppTheme.Shadows.floatingShadow.color,
                    radius: AppTheme.Shadows.floatingShadow.radius,
                    x: AppTheme.Shadows.floatingShadow.x,
                    y: AppTheme.Shadows.floatingShadow.y
                )
        }
    }
}

/// Empty state view with consistent styling
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var iconColor: Color = AppTheme.Colors.primary
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: icon)
                    .font(.system(size: 44))
                    .foregroundStyle(iconColor)
            }
            
            VStack(spacing: AppTheme.Spacing.xs) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }
}

/// Icon badge for list items
struct IconBadge: View {
    let icon: String
    var color: Color = AppTheme.Colors.primary
    var size: CGFloat = 44
    var iconSize: CGFloat = 18
    var isCircle: Bool = true
    
    var body: some View {
        ZStack {
            if isCircle {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: size, height: size)
            } else {
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                    .fill(color.opacity(0.12))
                    .frame(width: size, height: size)
            }
            
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundStyle(color)
        }
    }
}

/// Card container with consistent styling
struct CardContainer<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .shadow(
                        color: AppTheme.Shadows.cardShadow.color,
                        radius: AppTheme.Shadows.cardShadow.radius,
                        x: AppTheme.Shadows.cardShadow.x,
                        y: AppTheme.Shadows.cardShadow.y
                    )
            )
    }
}

// MARK: - View Modifiers

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            .shadow(
                color: AppTheme.Shadows.cardShadow.color,
                radius: AppTheme.Shadows.cardShadow.radius,
                x: AppTheme.Shadows.cardShadow.x,
                y: AppTheme.Shadows.cardShadow.y
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
