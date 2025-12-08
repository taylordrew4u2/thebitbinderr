import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Display the app icon
            Image("AppIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .cornerRadius(50)
                .shadow(radius: 10)
            
            Spacer()
        }
        .navigationTitle("Home")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
}

#Preview {
    HomeView()
}
