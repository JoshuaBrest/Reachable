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

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()
            if isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("reachLoginSelect.loading")
                }
            } else if let error = error {
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
            } else if !shouldStartSearch() {
                VStack {}
            } else if searchResults.isEmpty {
                Text("reachLoginSelect.noResults")
                    .foregroundColor(.gray)
            } else {
                List(searchResults, id: \.id) { result in
                    Button {
                        onSelect(result)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.name)
                                .bold()
                            Text(result.reachDomain)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                    }
                    .cornerRadius(10)
                    .listRowInsets(EdgeInsets())
                }
                .listStyle(PlainListStyle())
                .frame(maxHeight: .infinity)
            }
            TextField("reachLoginSelect.search", text: $search)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .foregroundColor(.secondary)
                .background(.thickMaterial)
                .cornerRadius(10)
                .padding(.bottom, 20)
                .onChange(of: search) { _ in
                    loadSeachResults()
                }
        }
        .navigationTitle("reachLoginSelect.title")
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
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
                        searchResults = results.reversed()
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
    ReachLoginSelectView()
}
