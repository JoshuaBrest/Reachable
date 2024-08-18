//
//  ReachLoginDetailsView.swift
//  Reachable
//

import SwiftUI
import ReachKit
import WebKit

struct ReachLoginDetailsView: View {
    let reach: RKApiSearchSchools.RKSchool
    @State private var reachDetails: RKApiAuthSchoolData.RKSchoolData? = nil
    @State private var error: Error? = nil
    @State private var isLoading: Bool = false
    @State private var webviewTitle: String? = nil
    @State private var samlShowing: Bool = false
    @State private var blackbaudShowing: Bool = false

    @ObservedObject var data = RKDatabase.shared

    @Environment(\.colorScheme) var colorScheme

    private struct SchoolHeaderView: View {
        public var name: String
        public var emblemURL: URL?
        public var tall: Bool

        private var image: some View {
            Group {
                if let emblem = emblemURL {
                    AsyncImage(url: emblem) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        EmptyView()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Image(systemName: "graduationcap.fill")
                        .resizable()
                        .padding(8)
                }
            }
            .padding(10)
            .frame(width: 72, height: 72)
            #if os(macOS)
                .background(.bar)
            #else
                .background(.thickMaterial)
            #endif
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }

        var body: some View {
            if tall {
                VStack(spacing: 8) {
                    image
                    Text(
                        String(
                            format: String(localized: "reachLoginDetails.schoolLogin"),
                            name)
                    )
                    .multilineTextAlignment(.center)
                    .font(.title2)
                    .bold()
                }
            } else {
                HStack(spacing: 16) {
                    image
                    Text(
                        String(
                            format: String(localized: "reachLoginDetails.schoolLogin"),
                            name)
                    )
                    .multilineTextAlignment(.leading)
                    .font(.title2)
                    .bold()
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                if let reach = reachDetails {
                    HStack {
                        VStack(
                            alignment: geometry.size.width >= ViewBreakpoints.Widths.small
                                ? .center : .leading,
                            spacing: 16
                        ) {
                            if geometry.size.width < ViewBreakpoints.Widths.small {
                                Spacer()
                            }
                            SchoolHeaderView(
                                name: reach.schoolName, emblemURL: reach.schoolEmblem,
                                tall: geometry.size.width >= ViewBreakpoints.Widths.small
                            )
                            .frame(maxWidth: .infinity)
                            if reach.samlData != nil {
                                Button {
                                    samlShowing = true
                                } label: {
                                    Text("reachLoginDetails.samlLogin")
                                        .padding(4)
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            if reach.blackbaudData != nil {
                                Button {
                                    blackbaudShowing = true
                                } label: {
                                    Text("reachLoginDetails.blackbaudLogin")
                                        .padding(4)
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            if reach.samlData == nil && reach.blackbaudData == nil {
                                Text("reachLoginDetails.noLogin")
                            }
                        }
                        .frame(
                            maxWidth: geometry.size.width >= ViewBreakpoints.Widths.small
                                ? 384 : .infinity,
                            maxHeight: .infinity,
                            alignment: geometry.size.width >= ViewBreakpoints.Widths.small
                                ? .center : .leading
                        )
                        .padding()
                    }
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .center
                    )
                    .background {
                        if let backgroundURL = reach.loginBackground {
                            AsyncImage(url: backgroundURL) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .blur(radius: 10, opaque: true)
                                    .overlay(
                                        colorScheme == .dark
                                            ? Color.black.opacity(0.6) : Color.white.opacity(0.6),
                                        ignoresSafeAreaEdges: .all)
                            } placeholder: {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                            .frame(
                                maxWidth: .infinity,
                                maxHeight: .infinity
                            )
                            .ignoresSafeArea()
                        }
                    }
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
            .onAppear {
                loadDetails(reach)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            #if os(macOS)
                .navigationSubtitle("reachLoginDetails.title")
            #else
                .navigationTitle("reachLoginDetails.title")
            #endif
        }
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
        .sheet(isPresented: $samlShowing) {
            if let saml = reachDetails?.samlData {
                VStack {
                    HStack(alignment: .center) {
                        Text(createWebViewTitle("reachLoginDetails.webViewSAMLTitle"))
                            .bold()
                        Spacer()
                        ExitButtonView()
                            .onTapGesture {
                                samlShowing = false
                            }
                    }
                    .padding()
                    .frame(alignment: .center)
                    ReachCoordinatedLoginModel.CordinatableLoginView(
                        title: $webviewTitle,
                        context: ReachCoordinatedSAMLLoginModel(
                            reach: reach.reachDomain,
                            samlIDPURL: saml.idpURL),
                        authCallback: { result in
                            samlShowing = false
                            let resultData: String
                            switch result {
                            case .success(let tokenData):
                                resultData = tokenData.token
                            case .failure(let errorData):
                                error = errorData
                                return
                            }

                            Task {
                                let result = await RKApiAuthLoginSAML.preformLogin(
                                    reach: reach.reachDomain, token: resultData)
                                switch result {
                                case .success(let res):
                                    switch res {
                                    case .success(let auth):
                                        data.data.auth = auth
                                    case .failure(let fail):
                                        error = fail
                                    }
                                case .failure(let fail):
                                    error = fail
                                }
                            }
                        }
                    )
                }
                #if os(macOS)
                    .frame(width: 600, height: 600)
                #endif
            }
        }
        .sheet(isPresented: $blackbaudShowing) {
            if let blackbaud = reachDetails?.blackbaudData {
                VStack {
                    HStack(alignment: .center) {
                        Text(createWebViewTitle("reachLoginDetails.webViewBlackbaudTitle"))
                            .bold()
                        Spacer()
                        ExitButtonView()
                            .onTapGesture {
                                blackbaudShowing = false
                            }
                    }
                    .padding()
                    ReachCoordinatedLoginModel.CordinatableLoginView(
                        title: $webviewTitle,
                        context: ReachCoordinatedBlackbaudLoginModel(
                            reach: reach.reachDomain,
                            samlIDPURL: blackbaud.ssoURL),
                        authCallback: { result in
                            blackbaudShowing = false
                            let resultData: String
                            switch result {
                            case .success(let tokenData):
                                resultData = tokenData.token
                            case .failure(let errorData):
                                error = errorData
                                return
                            }

                            Task {
                                let result = await RKApiAuthLoginBlackbaud.preformLogin(
                                    reach: reach.reachDomain, token: resultData)
                                switch result {
                                case .success(let res):
                                    switch res {
                                    case .success(let auth):
                                        data.data.auth = auth
                                    case .failure(let fail):
                                        error = fail
                                    }
                                case .failure(let fail):
                                    error = fail
                                }
                            }
                        }
                    )
                }
                #if os(macOS)
                    .frame(width: 600, height: 600)
                #endif
            }
        }
    }

    private func loadDetails(_ reach: RKApiSearchSchools.RKSchool) {
        withAnimation {
            isLoading = true
            error = nil
        }

        Task {
            // Fetch school details
            let result = await RKApiAuthSchoolData.getSchoolDetails(reach: reach.reachDomain)

            DispatchQueue.main.async {
                withAnimation {
                    switch result {
                    case .success(let details):
                        withAnimation {
                            reachDetails = details
                            isLoading = false
                        }
                    case .failure(let error):
                        withAnimation {
                            self.error = error
                            isLoading = false
                        }
                    }
                }
            }
        }
        return
    }

    private func createWebViewTitle(_ template: LocalizedStringResource) -> String {
        if let webviewTitle = webviewTitle {
            return String(format: String(localized: template), webviewTitle)
        }

        return String(localized: "reachLoginDetails.webViewLoading")
    }
}

#Preview {
    ReachLoginDetailsView(reach: RKApiSearchSchools.RKSchool.example)
}
