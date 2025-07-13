//
//  CXLazyPageContext.swift
//  CXLazyPage
//
//  Created by Cunqi Xiao on 7/7/25.
//

import SwiftUI

public struct CXLazyPageContext {

    // MARK: - Properties

    /// The axis along which the pages are laid out.
    let axis: Axis

    /// A Boolean value indicating whether paging is enabled.
    let isPagingEnabled: Bool

    // MARK: - Builder

    public class Builder {

        // MARK: - Properties

        private var axis: Axis = .horizontal
        private var isPagingEnabled: Bool = true

        public func axis(_ axis: Axis) -> Self {
            self.axis = axis
            return self
        }

        public func pagingEnabled(_ isPagingEnabled: Bool) -> Self {
            self.isPagingEnabled = isPagingEnabled
            return self
        }

        public func build() -> CXLazyPageContext {
            return CXLazyPageContext(axis: axis, isPagingEnabled: isPagingEnabled)
        }
    }
}

