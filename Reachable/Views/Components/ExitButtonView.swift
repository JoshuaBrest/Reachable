//
//  ExitButtonView.swift
//  Reachable
//

import SwiftUI

struct ExitButtonView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Image(systemName: "xmark")
            .resizable()
            .scaledToFit()
            .font(Font.body.weight(.bold))
            .scaleEffect(0.416)
            .foregroundColor(Color(white: colorScheme == .dark ? 0.62 : 0.51))
            .background(
                Circle()
                    .fill(Color(white: colorScheme == .dark ? 0.19 : 0.93))
            )
            .frame(width: 24, height: 24)
    }
}

#Preview {
    ExitButtonView()
        .padding()
}
