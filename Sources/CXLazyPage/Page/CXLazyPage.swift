//
//  CXLazyPage.swift
//  CXLazyPage
//
//  Created by Cunqi Xiao on 7/7/25.
//

import SwiftUI

public struct CXLazyPage<Content: View>: UIViewControllerRepresentable {

    // MARK: Lifecycle

    // MARK: - Initializer

    public init(
        axis: Axis = .horizontal,
        isPagingEnabled: Bool = true,
        itemHeight: CGFloat? = nil,
        currentPage: Binding<Int> = .constant(0),
        @ViewBuilder content: @escaping (Int) -> Content
    ) {
        context = CXLazyPageContext.Builder()
            .axis(axis)
            .pagingEnabled(isPagingEnabled)
            .itemHeight(itemHeight)
            .build()
        self.content = content
        _currentPage = currentPage
    }

    // MARK: Public

    // MARK: - Methods

    public func makeUIViewController(context _: Context) -> CXLazyPageViewController<Content> {
        CXLazyPageViewController(context: context, content: content) { currentPage in
            DispatchQueue.main.async {
                self.currentPage = currentPage
            }
        }
    }

    public func updateUIViewController(
        _ uiViewController: CXLazyPageViewController<Content>,
        context _: Context
    ) {
        uiViewController.scrollToPageIndexIfNeeded(currentPage)
    }

    // MARK: Internal

    @Binding var currentPage: Int

    // MARK: Private

    private let context: CXLazyPageContext

    @ViewBuilder private let content: (Int) -> Content

}
