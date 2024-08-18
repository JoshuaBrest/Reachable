//
//  ReachLoginSelectView.swift
//  Reachable
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

    private struct SearchBar: View {
        public var placeholder: LocalizedStringKey
        @Binding public var search: String

        var body: some View {
            TextField(placeholder, text: $search)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(8)
                .padding(.horizontal, 28)
                .background(.bar)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                #if os(macOS)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                        .stroke(.gray.opacity(0.5), lineWidth: 0.5)
                    }
                #endif
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(
                                minWidth: 0, maxWidth: .infinity, alignment: .leading
                            )
                            .padding(.leading, 10)
                    }
                )
        }
    }

    var body: some View {
        GeometryReader { reader in
            VStack(
                alignment: .center,
                spacing: reader.size.width >= ViewBreakpoints.Widths.small ? 16 : 0
            ) {
                if reader.size.width >= ViewBreakpoints.Widths.small {
                    HStack {
                        SearchBar(placeholder: "reachLoginSelect.search", search: $search)
                    }
                    #if os(macOS)
                        .frame(maxWidth: 600)
                        .padding(.horizontal, 21)
                    #endif
                }
                VStack {
                    if isLoading {
                        VStack {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .controlSize(.small)
                                Text("reachLoginSelect.loading")
                            }
                        }
                        .padding()
                    } else if let error = error {
                        VStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.red)
                            Text(
                                String(
                                    format: String(localized: "common.errorTitle"),
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
                        .padding()
                    } else if !shouldStartSearch() {
                        Spacer()
                    } else if searchResults.isEmpty {
                        VStack {
                            Text("reachLoginSelect.noResults")
                                .foregroundColor(.gray)
                        }
                        .padding()
                    } else {
                        Form {
                            ForEach(searchResultsWithIndex, id: \.1.id) { idx, result in
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
                                .buttonStyle(.plain)
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                .formStyle(.grouped)
                            }
                        }
                        .formStyle(.grouped)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(maxHeight: .infinity)
            }
            #if os(macOS)
                .padding()
            #endif
            .frame(
                maxWidth: .infinity, maxHeight: .infinity,
                alignment: .center
            ).safeAreaInset(edge: .bottom, spacing: 0) {
                if reader.size.width < ViewBreakpoints.Widths.small {
                    VStack {
                        SearchBar(placeholder: "reachLoginSelect.search", search: $search)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .overlay(alignment: .top) {
                        Divider()
                    }
                }
            }
            .onChange(of: search) { _ in
                loadSeachResults()
            }
            #if os(macOS)
                .navigationSubtitle("reachLoginSelect.title")
            #else
                .navigationTitle("reachLoginSelect.title")
            #endif
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
        let search = self.search
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
