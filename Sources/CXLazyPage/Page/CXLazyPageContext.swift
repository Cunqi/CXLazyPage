//
//  CXLazyPageContext.swift
//  CXLazyPage
//
//  Created by Cunqi Xiao on 7/7/25.
//

import SwiftUI

public struct CXLazyPageContext {

    // MARK: Public

    // MARK: - Builder

    public class Builder {

        // MARK: Public

        public func axis(_ axis: Axis) -> Self {
            self.axis = axis
            return self
        }

        public func pagingEnabled(_ isPagingEnabled: Bool) -> Self {
            self.isPagingEnabled = isPagingEnabled
            return self
        }

        public func itemHeight(_ height: CGFloat?) -> Self {
            itemHeight = height
            return self
        }

        public func build() -> CXLazyPageContext {
            CXLazyPageContext(
                axis: axis,
                isPagingEnabled: isPagingEnabled,
                itemHeight: itemHeight
            )
        }

        // MARK: Private

        private var axis = Axis.horizontal
        private var isPagingEnabled = true
        private var itemHeight: CGFloat? = nil

    }

    // MARK: Internal

    /// The axis along which the pages are laid out.
    let axis: Axis

    /// A Boolean value indicating whether paging is enabled.
    let isPagingEnabled: Bool

    /// The height of each item in the page.
    let itemHeight: CGFloat?

}
