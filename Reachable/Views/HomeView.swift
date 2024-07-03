//
//  HomeView.swift
//  Reachable
//
//  Created by Josh on 6/28/24.
//

import SwiftUI
import ReachKit

struct HomeView: View {
    @State private var loadingID: Int? = nil
    @State private var error: Error? = nil

    @ObservedObject var data = RKDatabase.shared

    var favoriteLocations: [RKApiSchoolConfig.RKSchoolLocation] {
        guard let schoolConfig = data.data.schoolConfig else {
            return []
        }
        return schoolConfig.locations.filter { location in
            data.data.appConfig.favoriteLocations.contains(location.id)
        }
    }

    private struct FavoriteLocationButtonView: View {
        @Binding var location: RKApiSchoolConfig.RKSchoolLocation
        @Binding var selectedID: Int?
        @Binding var loadingID: Int?

        var body: some View {
            Button {
                loadingID = location.id
            } label: {
                HStack {
                    Text(location.name)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Spacer()
                    if location.id == loadingID {
                        ProgressView()
                    } else if location.id == selectedID {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                    }
                }
                .padding(8)
            }
            .buttonStyle(.bordered)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 16) {
                    NavigationLink {
                        ManageLocationView()
                    } label: {
                        HStack {
                            Text("manageLocation.title")
                                .bold()
                                .font(.title3)
                            Image(systemName: "chevron.right")
                        }
                    }
                    if let userContact = data.data.userContact,
                        let schoolConfig = data.data.schoolConfig,
                        let location = schoolConfig.locations.first(where: {
                            $0.id == userContact.locationID
                        })
                    {
                        HStack(spacing: 16) {
                            Circle()
                                .foregroundColor(.green)
                                .shadow(color: .green, radius: 4)
                                .frame(width: 8, height: 8)
                            Text(location.name)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Material.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    if favoriteLocations.count == 0 {
                        Text("home.manageLocation.noFavorites")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(32)
                    } else {
                        // Maybe a 2 by (n) grid?
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(favoriteLocations.prefix(favoriteLocations.count / 2)) {
                                    location in
                                    FavoriteLocationButtonView(
                                        location: .constant(location),
                                        selectedID: .constant(data.data.userContact?.locationID),
                                        loadingID: $loadingID
                                    )
                                }
                            }
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(favoriteLocations.suffix(favoriteLocations.count / 2)) {
                                    location in
                                    FavoriteLocationButtonView(
                                        location: .constant(location),
                                        selectedID: .constant(data.data.userContact?.locationID),
                                        loadingID: $loadingID
                                    )
                                }
                            }
                        }
                    }
                }
                Spacer()
                Text("home.notComplete")
                    .bold()
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .frame(maxWidth: .infinity)
        .alert(
            String(
                format: String(localized: "home.error"),
                error?.localizedDescription ?? ""
            ), isPresented: .constant(error != nil)
        ) {
            Button("common.okay", role: .cancel) {
                error = nil
            }
        }
        .navigationTitle(
            String(
                format: String(localized: "home.hello"),
                data.data.userContact?.preferredName ?? data.data.userContact?.firstName ?? "...")
        )
        .overlay(alignment: .topTrailing) {
            if let userContact = data.data.userContact, let config = data.data.schoolConfig,
                let pfp = userContact.profilePictureID
            {
                VStack {
                    // PFP using async image
                    AsyncImage(url: config.reach.storageBase.appendingPathComponent("_300_" + pfp))
                    { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipShape(Circle())
                    } placeholder: {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipShape(Circle())
                    }
                }
                .frame(width: 40, height: 40)
                .background(.thinMaterial)
                .clipShape(Circle())
                .padding(.trailing, 20)
                .offset(x: 0, y: -50)

            }
        }
        .onAppear {
            loadData()
            loadContacts()
        }
        .onChange(of: loadingID) { placeId in
            if let placeId = placeId {
                selectPlace(placeId)
            }
        }
    }

    private func loadData() {
        guard let auth = data.data.auth else {
            return
        }

        withAnimation {
            error = nil
        }

        Task {
            let reachConfig = await RKApiSchoolConfig.getSchoolConfig(
                auth: auth
            )
            DispatchQueue.main.async {
                withAnimation {
                    switch reachConfig {
                    case .success(let config):
                        data.data.schoolConfig = config
                    case .failure(let error):
                        self.error = error
                    }
                }
            }
        }
    }

    private func loadContacts() {
        guard let auth = data.data.auth else {
            return
        }

        Task {
            let data = await RKApiUserContacts.getUserContacts(
                auth: auth
            )
            // Try to find the user's contact where user id matches
            DispatchQueue.main.async {
                withAnimation {
                    switch data {
                    case .success(let contacts):
                        self.data.data.userContact = contacts.first {
                            $0.contactID == auth.contactID
                        }
                    case .failure(let error):
                        self.error = error
                    }
                }
            }
        }
    }

    private func selectPlace(_ placeId: Int) {
        guard let auth = data.data.auth else {
            return
        }

        Task {
            let result = await RKApiUserLocation.setUserLocation(
                auth: auth,
                contactId: auth.contactID,
                locationId: placeId,
                requestId: nil
            )
            DispatchQueue.main.async {
                withAnimation {
                    switch result {
                    case .success:
                        data.data.userContact?.locationID = placeId
                    case .failure(let error):
                        print(error)
                    }
                    loadingID = nil
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
