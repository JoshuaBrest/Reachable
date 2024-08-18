//
//  ReachLoginView.swift
//  Reachable
//

import SwiftUI
import ReachKit

struct ReachLoginView: View {
    #if os(macOS)
        private static var moveAndFadeNext: AnyTransition {
            AnyTransition.asymmetric(
                insertion: .offset(x: 32).combined(with: .opacity),
                removal: .offset(x: -32).combined(with: .opacity)
            )
        }
        private static var moveAndFadeBack: AnyTransition {
            AnyTransition.asymmetric(
                insertion: .offset(x: -32).combined(with: .opacity),
                removal: .offset(x: 32).combined(with: .opacity)
            )
        }
    #endif

    @State private var finishedWelcome: Bool = false
    @State private var selectedReach: RKApiSearchSchools.RKSchool? = nil
    #if os(macOS)
        @State private var transitionMovingBack: Bool = false
    #else
        @State private var presented: Bool = false
    #endif
    var body: some View {
        Group {
            #if os(macOS)
                VStack {
                    if !finishedWelcome {
                        ReachLoginWelcomeView(onContinue: {
                            transitionMovingBack = false
                            withAnimation {
                                finishedWelcome = true
                            }
                        })
                        .transition(
                            transitionMovingBack
                                ? ReachLoginView.moveAndFadeBack : ReachLoginView.moveAndFadeNext
                        )
                        .frame(maxWidth: ViewBreakpoints.Widths.medium, maxHeight: .infinity)
                    }
                    if finishedWelcome && selectedReach == nil {
                        ReachLoginSelectView(onSelect: { result in
                            transitionMovingBack = false
                            withAnimation {
                                selectedReach = result
                            }
                        })
                        .toolbar {
                            ToolbarItem(placement: .navigation) {
                                Button {
                                    transitionMovingBack = true
                                    withAnimation {
                                        finishedWelcome = false
                                    }
                                } label: {
                                    Label("common.back", systemImage: "chevron.left")
                                }
                            }
                        }
                        .transition(
                            transitionMovingBack
                                ? ReachLoginView.moveAndFadeBack : ReachLoginView.moveAndFadeNext
                        )
                        .frame(maxWidth: ViewBreakpoints.Widths.medium, maxHeight: .infinity)
                    }
                    if finishedWelcome, let reach = selectedReach {
                        ReachLoginDetailsView(reach: reach)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .transition(
                                transitionMovingBack
                                    ? ReachLoginView.moveAndFadeBack
                                    : ReachLoginView.moveAndFadeNext
                            )
                            .toolbar {
                                ToolbarItem(placement: .navigation) {
                                    Button {
                                        transitionMovingBack = true
                                        withAnimation {
                                            selectedReach = nil
                                        }
                                    } label: {
                                        Label("common.back", systemImage: "chevron.left")
                                    }
                                }
                            }
                    }
                }
            #else
                NavigationStack {
                    ReachLoginWelcomeView(onContinue: {
                        withAnimation {
                            finishedWelcome = true
                        }
                    }).navigationDestination(isPresented: $finishedWelcome) {
                        ReachLoginSelectView(onSelect: { result in
                            selectedReach = result
                        })
                        .frame(maxWidth: ViewBreakpoints.Widths.medium, maxHeight: .infinity)
                        .navigationDestination(isPresented: $presented) {
                            if let reach = selectedReach {
                                ReachLoginDetailsView(reach: reach)
                            }
                        }
                    }
                }
                .onChange(of: selectedReach) { _ in
                    presented = selectedReach != nil
                }
                .onChange(of: presented) { _ in
                    if presented {
                        return
                    }
                    selectedReach = nil
                }
            #endif
        }
        .navigationTitle("reachLogin.title")
        #if os(macOS)
            .toolbar {
                VStack {}
            }
        #endif
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ReachLoginView()
}
