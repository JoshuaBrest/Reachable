//
//  ReachLoginView.swift
//  Reachable
//
//  Created by Josh on 6/28/24.
//

import SwiftUI
import ReachKit

struct ReachLoginView: View {
    @State private var selectedReach: RKApiSearchSchools.RKSchool? = nil
    @State private var presented: Bool = false

    var body: some View {
        NavigationStack {
            ReachLoginSelectView(onSelect: { result in
                selectedReach = result
            })
            .navigationDestination(isPresented: $presented) {
                if let reach = selectedReach {
                    ReachLoginDetailsView(reach: reach)
                }
            }
        }
        .onChange(of: selectedReach) { value in
            presented = value != nil
        }
        .onChange(of: presented) { value in
            if !value {
                selectedReach = nil
            }
        }
    }
}

#Preview {
    ReachLoginView()
}
