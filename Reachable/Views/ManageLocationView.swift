//
//  ManageLocationView.swift
//  Reachable
//

import SwiftUI
import ReachKit

struct ManageLocationView: View {
    @ObservedObject var data = RKDatabase.shared

    @State private var loadingID: Int? = nil
    @State private var error: Error? = nil
    @State private var search: String = ""
    @State private var favoriteSheetPresented: Bool = false
    @State private var favoriteSearch: String = ""

    private struct LocationItemView: View {
        @Binding var location: RKApiSchoolConfig.RKSchoolLocation
        @Binding var selectedID: Int?
        @Binding var loadingID: Int?

        var body: some View {
            Button {
                loadingID = location.id
            } label: {
                HStack {
                    Text(location.name)
                        .foregroundColor(.primary)
                    Spacer()
                    if location.id == loadingID {
                        ProgressView()
                    } else if location.id == selectedID {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                    }
                }
            }
        }
    }

    var favoritesLocations: [RKApiSchoolConfig.RKSchoolLocation] {
        guard let schoolConfig = data.data.schoolConfig else {
            return []
        }
        return schoolConfig.locations.filter { location in
            data.data.appConfig.favoriteLocations.contains(location.id)
        }
    }

    var otherLocations: [RKApiSchoolConfig.RKSchoolLocation] {
        guard let schoolConfig = data.data.schoolConfig else {
            return []
        }
        return schoolConfig.locations.filter { location in
            !data.data.appConfig.favoriteLocations.contains(location.id)
        }
    }

    var searchFavoritesLocations: [RKApiSchoolConfig.RKSchoolLocation] {
        if search.isEmpty {
            return favoritesLocations
        }
        return favoritesLocations.filter { location in
            location.name.localizedCaseInsensitiveContains(search)
        }
    }

    var searchOtherLocations: [RKApiSchoolConfig.RKSchoolLocation] {
        if search.isEmpty {
            return otherLocations
        }
        return otherLocations.filter { location in
            location.name.localizedCaseInsensitiveContains(search)
        }
    }

    var manageLocations: [RKApiSchoolConfig.RKSchoolLocation] {
        guard let schoolConfig = data.data.schoolConfig else {
            return []
        }
        if favoriteSearch.isEmpty {
            return schoolConfig.locations
        }
        return schoolConfig.locations.filter { location in
            location.name.localizedCaseInsensitiveContains(favoriteSearch)
        }
    }

    var body: some View {
        VStack {
            if let userProfile = data.data.userContact {
                List {
                    if !searchFavoritesLocations.isEmpty {
                        Section(header: Text("manageLocation.favorites")) {
                            ForEach(searchFavoritesLocations) { location in
                                LocationItemView(
                                    location: .constant(location),
                                    selectedID: .constant(userProfile.locationID),
                                    loadingID: $loadingID)
                            }
                        }
                    }

                    if !searchOtherLocations.isEmpty {
                        Section(header: Text("manageLocation.other")) {
                            ForEach(searchOtherLocations) { location in
                                LocationItemView(
                                    location: .constant(location),
                                    selectedID: .constant(userProfile.locationID),
                                    loadingID: $loadingID)
                            }
                        }
                    }
                }
                #if os(macOS)
                    .listStyle(.bordered)
                #else
                    .listStyle(.insetGrouped)
                #endif
                .searchable(text: $search)

            }
        }
        .frame(maxWidth: .infinity)
        .alert(
            String(
                format: String(localized: "common.errorTitle"),
                error?.localizedDescription ?? ""
            ), isPresented: .constant(error != nil)
        ) {
            Button("common.okay", role: .cancel) {
                error = nil
            }
        }
        .sheet(isPresented: $favoriteSheetPresented) {
            NavigationStack {
                List {
                    ForEach(manageLocations) { location in
                        Button {
                            withAnimation {
                                // If it's not a favorite, favorite it
                                if !data.data.appConfig.favoriteLocations.contains(location.id) {
                                    data.data.appConfig.favoriteLocations.append(location.id)
                                } else {
                                    // If it is a favorite, unfavorite it
                                    data.data.appConfig.favoriteLocations.removeAll {
                                        $0 == location.id
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text(location.name)
                                    .foregroundColor(.primary)
                                Spacer()
                                if data.data.appConfig.favoriteLocations.contains(location.id) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                }
                            }
                        }
                    }
                }
                #if !(os(macOS))
                    .listStyle(.insetGrouped)
                    .searchable(
                        text: $favoriteSearch, placement: .navigationBarDrawer(displayMode: .always)
                    )
                    .navigationTitle("manageLocation.manageFavorite")
                    .navigationBarItems(
                        trailing: Button {
                            favoriteSheetPresented = false
                        } label: {
                            Text("common.done")
                        }
                    )
                    .navigationBarTitleDisplayMode(.inline)
                #endif
            }
        }
        .onChange(of: loadingID) { placeID in
            if let placeID = placeID {
                selectPlace(placeID)
            }
        }
        .navigationTitle("manageLocation.title")
        #if !(os(macOS))
            .navigationBarItems(
                trailing: Button {
                    favoriteSheetPresented = true
                } label: {
                    Label("manageLocation.manageFavorite", systemImage: "star")
                }
            )
        #else
            .toolbar {
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        favoriteSheetPresented = true
                    } label: {
                        Label("manageLocation.manageFavorite", systemImage: "star")
                    }
                }
            }
        #endif

    }

    private func selectPlace(_ placeID: Int) {
        guard let auth = data.data.auth else {
            return
        }

        Task {
            let result = await RKApiUserLocation.setUserLocation(
                auth: auth,
                contactID: auth.contactID,
                locationID: placeID,
                requestID: nil
            )
            DispatchQueue.main.async {
                withAnimation {
                    switch result {
                    case .success:
                        data.data.userContact?.locationID = placeID
                    case .failure(let error):
                        self.error = error
                    }

                    loadingID = nil
                }
            }
        }
    }

    private func filterFavorites(
        locations: [RKApiSchoolConfig.RKSchoolLocation], favorites: [Int], isFavorite: Bool
    ) -> [RKApiSchoolConfig.RKSchoolLocation] {
        locations.filter { location in
            guard isFavorite else {
                return !favorites.contains(location.id)
            }
            return favorites.contains(location.id)
        }
    }
}

#Preview {
    NavigationStack {
        ManageLocationView()
    }
}
