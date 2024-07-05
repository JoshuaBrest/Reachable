//
//  ReachLoginSelectView.swift
//  Reachable
//
//  Created by Josh on 6/28/24.
//

import SwiftUI
import ReachKit

struct ReachLoginSelectView: View {
    @State private var search: String = ""
    @State private var isLoading: Bool = false
    @State private var error: Error? = nil
    @State private var searchResults: [RKApiSearchSchools.RKSchool] = []

    public var onSelect: (RKApiSearchSchools.RKSchool) -> Void = { _ in }
    
    private var searchResultsWithIndex: [(Int, RKApiSearchSchools.RKSchool)] {
        Array(zip(searchResults.indices, searchResults))
    }

    var body: some View {
        VStack {
            if isLoading {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Text("reachLoginSelect.loading")
                    }
                }
                .padding()
            } else if let error = error {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red)
                        Text(
                            String(
                                format: String(localized: "reachLoginSelect.error"),
                                error.localizedDescription
                            )
                        )
                        .foregroundColor(.red)
                        Button {
                            loadSeachResults()
                        } label: {
                            Text("reachLoginSelect.retry")
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding()
            } else if !shouldStartSearch() {
                VStack {}
            } else if searchResults.isEmpty {
                VStack {
                    Spacer()
                    Text("reachLoginSelect.noResults")
                        .foregroundColor(.gray)
                }
                .padding()
            } else {
                List(searchResultsWithIndex, id: \.1.id) { idx, result in
                    Button {
                        onSelect(result)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.name)
                                .bold()
                                .foregroundColor(.primary)
                            Text(result.reachDomain)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                }
                .listStyle(.insetGrouped)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(alignment: .leading) {
                TextField("reachLoginSelect.search", text: $search)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .foregroundColor(.secondary)
                    .background(.bar)
                    .cornerRadius(10)
            }
            .padding()
            .background(.ultraThinMaterial)
            .overlay(Divider(), alignment: .top)
        }
        .navigationTitle("reachLoginSelect.title")
        .onChange(of: search) { _ in
            loadSeachResults()
        }
    }

    func shouldStartSearch() -> Bool {
        return search.count >= 3
    }

    func loadSeachResults() {
        let originalSearch = search
        // If search is less than 3 characters, do not search
        if !shouldStartSearch() {
            withAnimation {
                isLoading = false
                error = nil
                searchResults = []
            }
            return
        }
        // Hide all results
        withAnimation {
            isLoading = true
            error = nil
            searchResults = []
        }
        // Async task
        Task {
            // Search
            let data = await RKApiSearchSchools.searchSchools(byName: search)
            // Check if the search query has changed
            if search != originalSearch {
                return
            }
            // Main thread
            DispatchQueue.main.async {
                withAnimation {
                    // Check if the search results have changed
                    isLoading = false
                    // Unwrap result
                    switch data {
                    case .success(let results):
                        print(results)
                        searchResults = results
                        error = nil
                    case .failure(let error):
                        searchResults = []
                        self.error = error
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ReachLoginSelectView(onSelect: { _ in })
    }
}
