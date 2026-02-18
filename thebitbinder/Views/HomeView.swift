import SwiftUI

struct HomeView: View {
    @State private var notepadText: String = ""
    @State private var showingAIChat = false
    private let notepadKey = "notepadText"

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                LinedNotepad(text: $notepadText)
                    .ignoresSafeArea(edges: .bottom)
                
                // AI Chat floating button
                Button {
                    showingAIChat = true
                } label: {
                    Image(systemName: "sparkles")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
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

struct LinedNotepad: View {
    @Binding var text: String
    private let lineSpacing: CGFloat = 32

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Subtle paper texture background
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            // Lines
            LinedBackground(lineSpacing: lineSpacing, lineColor: Color.blue.opacity(0.08))
                .ignoresSafeArea()
            
            // Left margin line
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.red.opacity(0.2))
                    .frame(width: 1)
                    .padding(.leading, 40)
                Spacer()
            }
            .ignoresSafeArea()
            
            TextEditor(text: $text)
                .scrollContentBackground(.hidden)
                .padding(.leading, 50)
                .padding(.trailing, 16)
                .padding(.vertical, 20)
                .font(.system(size: 17, design: .default))
                .lineSpacing(lineSpacing - 17)
                .background(Color.clear)
        }
    }
}

struct LinedBackground: View {
    let lineSpacing: CGFloat
    let lineColor: Color

    var body: some View {
        Canvas { context, size in
            var y: CGFloat = lineSpacing
            while y <= size.height {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(lineColor), lineWidth: 1)
                y += lineSpacing
            }
        }
    }
}

#Preview {
    HomeView()
}
