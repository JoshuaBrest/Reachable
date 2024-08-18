//
//  ViewBreakpoints.swift
//  Reachable
//

import Foundation

/// The breakpoints for view sizes e.g. changing between tab view and navigation sidebar.
enum ViewBreakpoints {
    /// Breakpoints for widths
    public enum Widths {
        /// A phone would be considered small
        /// This could be the deciding factor for using a tab view or a navigation sidebar
        static let small: Double = 600
        static let medium: Double = 800
        static let large: Double = 1200
    }
}
