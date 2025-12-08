//
//  AdaptiveLayout.swift
//  thebitbinder
//
//  Created by Taylor Drew on 12/2/25.
//

import SwiftUI

// Adaptive grid layout
struct AdaptiveGrid<Content: View>: View {
    let spacing: CGFloat
    let content: Content
    
    @State private var columns: Int = 1
    
    init(spacing: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            let columnCount = calculateColumns(for: geometry.size.width)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnCount), spacing: spacing) {
                content
            }
            .onChange(of: geometry.size.width) { oldValue, newValue in
                columns = calculateColumns(for: newValue)
            }
        }
    }
    
    private func calculateColumns(for width: CGFloat) -> Int {
        if DeviceHelper.isIPad {
            if width > 1000 {
                return 3
            } else if width > 700 {
                return 2
            }
        }
        return 1
    }
}

// Adaptive stack that switches between VStack and HStack based on available space
struct AdaptiveStack<Content: View>: View {
    let horizontalAlignment: HorizontalAlignment
    let verticalAlignment: VerticalAlignment
    let spacing: CGFloat
    let content: Content
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    init(
        horizontalAlignment: HorizontalAlignment = .center,
        verticalAlignment: VerticalAlignment = .center,
        spacing: CGFloat = 8,
        @ViewBuilder content: () -> Content
    ) {
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        Group {
            if horizontalSizeClass == .compact || DeviceHelper.isIPhone {
                VStack(alignment: horizontalAlignment, spacing: spacing) {
                    content
                }
            } else {
                HStack(alignment: verticalAlignment, spacing: spacing) {
                    content
                }
            }
        }
    }
}

// Responsive font sizes
struct ResponsiveFontModifier: ViewModifier {
    let baseSize: CGFloat
    
    func body(content: Content) -> some View {
        let scaleFactor: CGFloat = {
            if DeviceHelper.isIPad {
                return 1.15
            } else if DeviceHelper.isSmallScreen {
                return 0.95
            } else {
                return 1.0
            }
        }()
        
        return content
            .font(.system(size: baseSize * scaleFactor))
    }
}

extension View {
    func responsiveFont(_ baseSize: CGFloat) -> some View {
        self.modifier(ResponsiveFontModifier(baseSize: baseSize))
    }
}

// Dynamic spacing based on screen size
extension View {
    func dynamicPadding() -> some View {
        self.padding(DeviceHelper.isIPad ? 20 : (DeviceHelper.isSmallScreen ? 12 : 16))
    }
    
    func dynamicSpacing() -> CGFloat {
        DeviceHelper.isIPad ? 20 : (DeviceHelper.isSmallScreen ? 12 : 16)
    }
}

// Safe area insets helper
struct SafeAreaInsetsKey: EnvironmentKey {
    static var defaultValue: EdgeInsets = EdgeInsets()
}

extension EnvironmentValues {
    var safeAreaInsets: EdgeInsets {
        get { self[SafeAreaInsetsKey.self] }
        set { self[SafeAreaInsetsKey.self] = newValue }
    }
}

// Orientation-aware view modifier
struct OrientationAwareModifier: ViewModifier {
    @State private var orientation = UIDevice.current.orientation
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                orientation = UIDevice.current.orientation
            }
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                orientation = UIDevice.current.orientation
            }
            .environment(\.orientation, UIInterfaceOrientation(from: orientation))
    }
}

extension UIInterfaceOrientation {
    init(from deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
        case .portrait:
            self = .portrait
        case .portraitUpsideDown:
            self = .portraitUpsideDown
        case .landscapeLeft:
            self = .landscapeLeft
        case .landscapeRight:
            self = .landscapeRight
        default:
            self = .portrait
        }
    }
}

extension View {
    func orientationAware() -> some View {
        self.modifier(OrientationAwareModifier())
    }
}
