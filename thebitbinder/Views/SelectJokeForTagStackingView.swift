//
//  SelectJokeForTagStackingView.swift
//  thebitbinder
//
//  Created by Taylor Drew on 2/1/26.
//

import SwiftUI
import SwiftData

struct SelectJokeForTagStackingView: View {
    @Binding var selectedJokeId: UUID?
    @Query private var jokes: [Joke]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            List {
                ForEach(jokes, id: \.id) { joke in
                    Button(action: {
                        selectedJokeId = joke.id
                        dismiss()
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(joke.title)
                                .font(.headline)
                                .foregroundColor(.black)
                            Text(joke.content)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(2)
                        }
                    }
                }
            }
        }
        .navigationTitle("Select a Joke")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SelectJokeForTagStackingView(selectedJokeId: .constant(nil))
            .modelContainer(for: Joke.self, inMemory: true)
    }
}
