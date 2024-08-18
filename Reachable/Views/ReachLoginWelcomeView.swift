//
//  ReachLoginView.swift
//  Reachable
//

import SwiftUI

struct ReachLoginWelcomeView: View {
    public let onContinue: () -> Void

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 8) {
                #if os(macOS)
                    Text("reachLoginWelcome.title")
                        .font(.title)
                        .bold()
                #endif
                Text("reachLoginWelcome.welcome")
                VStack(alignment: .center) {
                    VStack {
                        GeometryReader { imageGeometry in
                            VStack(alignment: .center) {
                                Image("AppLogo")
                                    .resizable()
                                    .clipShape(
                                        RoundedRectangle(
                                            cornerRadius: min(
                                                imageGeometry.size.height, imageGeometry.size.height
                                            )
                                                * (92 / 412))
                                    )
                                    .aspectRatio(contentMode: .fit)
                                    .shadow(
                                        radius: min(
                                            imageGeometry.size.height, imageGeometry.size.height)
                                            * (92 / 412))
                            }
                            .frame(
                                width: imageGeometry.size.width, height: imageGeometry.size.height,
                                alignment: .center)
                        }
                    }
                    .frame(maxHeight: 256)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding(24)
                HStack {
                    if geometry.size.width > ViewBreakpoints.Widths.small {
                        Spacer()
                    }
                    Button {
                        onContinue()
                    } label: {
                        Text("common.next")
                            .padding(4)
                            .frame(
                                maxWidth: geometry.size.width > ViewBreakpoints.Widths.small
                                    ? nil : .infinity)
                    }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #if os(macOS)
            .padding()
        #else
            .padding(.horizontal)
            .navigationBarTitleDisplayMode(.large)
            .navigationTitle("reachLoginWelcome.title")
        #endif
    }
}

#Preview {
    NavigationStack {
        ReachLoginWelcomeView(onContinue: {})
    }
}
