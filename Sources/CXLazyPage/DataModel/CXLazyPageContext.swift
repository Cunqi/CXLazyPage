//
//  CXLazyPageContext.swift
//  CXLazyPage
//
//  Created by Cunqi Xiao on 7/7/25.
//

import SwiftUI

/// A configuration context for lazy-loaded paging views.
/// Use the builder pattern through `CXLazyPageContext.Builder` to create instances.
public struct CXLazyPageContext {
    // MARK: Public

    // MARK: - Builder

    /// A builder class for creating `CXLazyPageContext` instances with customized configuration.
    public class Builder {
        // MARK: Public

        /// Sets the axis along which pages are laid out.
        /// - Parameter axis: The axis (horizontal or vertical) for page layout.
        /// - Returns: The builder instance for method chaining.
        public func axis(_ axis: Axis) -> Self {
            self.axis = axis
            return self
        }

        /// Sets whether paging behavior is enabled.
        /// - Parameter isPagingEnabled: If true, enables paging behavior. Default is true.
        /// - Returns: The builder instance for method chaining.
        public func pagingEnabled(_ isPagingEnabled: Bool) -> Self {
            self.isPagingEnabled = isPagingEnabled
            return self
        }

        /// Sets a fixed height for all items in the page.
        /// - Parameter height: The height in points for each item, or nil for automatic sizing.
        /// - Returns: The builder instance for method chaining.
        public func itemHeight(_ height: CGFloat?) -> Self {
            itemHeight = height
            return self
        }

        /// Sets the viewport tracking configuration.
        /// - Parameter context: The viewport tracker context to configure viewport detection behavior.
        /// - Returns: The builder instance for method chaining.
        public func viewportTrackerContext(_ context: ViewportTrackerContext) -> Self {
            viewportTrackerContext = context
            return self
        }

        public func build() -> CXLazyPageContext {
            CXLazyPageContext(
                axis: axis,
                isPagingEnabled: isPagingEnabled,
                itemHeight: itemHeight,
                viewportTrackerContext: viewportTrackerContext
            )
        }

        // MARK: Private

        private var axis = Axis.horizontal
        private var isPagingEnabled = true
        private var itemHeight: CGFloat?
        private var viewportTrackerContext = ViewportTrackerContext.default
    }

    // MARK: Internal

    /// The axis along which the pages are laid out.
    let axis: Axis

    /// A Boolean value indicating whether paging is enabled.
    let isPagingEnabled: Bool

    /// The height of each item in the page.
    let itemHeight: CGFloat?

    // MARK: - Viewport

    /// The configuration for viewport tracking behavior.
    let viewportTrackerContext: ViewportTrackerContext
}
