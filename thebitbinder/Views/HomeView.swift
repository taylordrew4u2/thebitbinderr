import SwiftUI

struct HomeView: View {
    @State private var notepadText: String = ""
    @State private var showingAIChat = false
    private let notepadKey = "notepadText"

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                // Modern notepad
                ModernNotepad(text: $notepadText)
                    .ignoresSafeArea(edges: .bottom)
                
                // AI Chat floating button
                Button {
                    showingAIChat = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 60, height: 60)
                        
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.4, green: 0.3, blue: 1.0), Color(red: 0.6, green: 0.2, blue: 0.9)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 54, height: 54)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .shadow(color: Color(red: 0.5, green: 0.3, blue: 1.0).opacity(0.5), radius: 12, x: 0, y: 6)
                }
                .padding(.trailing, 80)
                .padding(.bottom, 30)
            }
            .navigationTitle("Notepad")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if let saved = UserDefaults.standard.string(forKey: notepadKey) {
                    notepadText = saved
                }
            }
            .onChange(of: notepadText) { _, newValue in
                UserDefaults.standard.set(newValue, forKey: notepadKey)
            }
            .sheet(isPresented: $showingAIChat) {
                AIChatView()
            }
        }
    }
}

struct ModernNotepad: View {
    @Binding var text: String
    private let lineSpacing: CGFloat = 34

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Clean gradient background
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.99, blue: 0.96),
                    Color(red: 0.98, green: 0.97, blue: 0.94)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Subtle lines
            ModernLinedBackground(lineSpacing: lineSpacing)
                .ignoresSafeArea()
            
            // Left margin accent
            HStack(spacing: 0) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.red.opacity(0.3), Color.red.opacity(0.15)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 2)
                    .padding(.leading, 44)
                Spacer()
            }
            .ignoresSafeArea()
            
            // Text editor
            TextEditor(text: $text)
                .scrollContentBackground(.hidden)
                .padding(.leading, 56)
                .padding(.trailing, 70)
                .padding(.vertical, 20)
                .font(.system(size: 17, design: .default))
                .lineSpacing(lineSpacing - 17)
                .background(Color.clear)
        }
    }
}

struct ModernLinedBackground: View {
    let lineSpacing: CGFloat

    var body: some View {
        Canvas { context, size in
            var y: CGFloat = lineSpacing
            while y <= size.height {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(Color.blue.opacity(0.08)), lineWidth: 1)
                y += lineSpacing
            }
        }
    }
}

#Preview {
    HomeView()
}
