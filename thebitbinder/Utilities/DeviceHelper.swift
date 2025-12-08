//
//  DeviceHelper.swift
//  thebitbinder
//
//  Created by Taylor Drew on 12/2/25.
//

import SwiftUI

struct DeviceHelper {
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    static var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    static var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }
    
    static var screenHeight: CGFloat {
        UIScreen.main.bounds.height
    }
    
    static var isLandscape: Bool {
        screenWidth > screenHeight
    }
    
    static var isPortrait: Bool {
        !isLandscape
    }
    
    static var isSmallScreen: Bool {
        screenWidth <= 375 // iPhone SE, 12 mini, etc.
    }
    
    static var isLargeScreen: Bool {
        screenWidth >= 428 // iPhone Pro Max, etc.
    }
}

// Environment key for orientation changes
struct OrientationKey: EnvironmentKey {
    static let defaultValue: UIInterfaceOrientation = .portrait
}

extension EnvironmentValues {
    var orientation: UIInterfaceOrientation {
        get { self[OrientationKey.self] }
        set { self[OrientationKey.self] = newValue }
    }
}

// Responsive padding modifier
extension View {
    func responsivePadding() -> some View {
        self.padding(DeviceHelper.isIPad ? 20 : 16)
    }
    
    func responsiveFont(size: CGFloat) -> some View {
        let scale = DeviceHelper.isIPad ? 1.2 : 1.0
        return self.font(.system(size: size * scale))
    }
    
    func adaptiveColumns(minWidth: CGFloat = 300) -> Int {
        let availableWidth = DeviceHelper.screenWidth - 40
        return max(1, Int(availableWidth / minWidth))
    }
}
