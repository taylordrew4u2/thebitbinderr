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
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.indigo],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .shadow(color: .blue.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(.trailing, 70)
                .padding(.bottom, 24)
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
            // Warm cream paper background
            LinearGradient(
                colors: [Color(red: 0.98, green: 0.96, blue: 0.93), Color(UIColor.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Lines
            LinedBackground(lineSpacing: lineSpacing, lineColor: Color.blue.opacity(0.1))
                .ignoresSafeArea()
            
            // Left margin line
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.red.opacity(0.25))
                    .frame(width: 1.5)
                    .padding(.leading, 42)
                Spacer()
            }
            .ignoresSafeArea()
            
            TextEditor(text: $text)
                .scrollContentBackground(.hidden)
                .padding(.leading, 52)
                .padding(.trailing, 60) // Extra space for notebook spine
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
