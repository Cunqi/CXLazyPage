//
//  CXLazyList.swift
//  CXLazyPage
//
//  Created by Cunqi Xiao on 7/14/25.
//

import SwiftUI

public struct CXLazyList<Content: View>: UIViewControllerRepresentable {
    // MARK: Lifecycle

    // MARK: - Initializer

    public init(
        viewportTrackerContext: ViewportTrackerContext = .default,
        currentPage: Binding<Int> = .constant(.zero),
        @ViewBuilder content: @escaping (Int) -> Content,
        heightOfPage: @escaping CXLazyListHeightOfPage
    ) {
        _currentPage = currentPage
        self.content = content
        self.heightOfPage = heightOfPage
        context = CXLazyPageContext.Builder()
            .axis(.vertical)
            .pagingEnabled(false)
            .viewportTrackerContext(viewportTrackerContext)
            .build()
    }

    // MARK: Public

    // MARK: - Methods

    public func makeUIViewController(context _: Context) -> CXLazyListViewController<Content> {
        CXLazyListViewController(
            context: context,
            content: content,
            heightOfPage: heightOfPage
        ) { currentPage in
            DispatchQueue.main.async {
                self.currentPage = currentPage
            }
        }
    }

    public func updateUIViewController(
        _ uiViewController: CXLazyListViewController<Content>,
        context _: Context
    ) {
        uiViewController.scrollToPageIndexIfNeeded(currentPage)
    }

    // MARK: Private

    @Binding private var currentPage: Int

    @ViewBuilder private var content: (Int) -> Content

    private var heightOfPage: CXLazyListHeightOfPage

    private let context: CXLazyPageContext
}
