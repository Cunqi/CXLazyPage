//
//  CXLazyPage.swift
//  CXLazyPage
//
//  Created by Cunqi Xiao on 7/7/25.
//

import SwiftUI

public struct CXLazyPage<PageContent: View>: UIViewControllerRepresentable {

    // MARK: Lifecycle

    // MARK: - Initializer

    public init(
        axis: Axis = .horizontal,
        isPagingEnabled: Bool = true,
        itemHeight: CGFloat? = nil,
        currentPage: Binding<Int> = .constant(0),
        @ViewBuilder pageContent: @escaping (Int) -> PageContent
    ) {
        context = CXLazyPageContext.Builder()
            .axis(axis)
            .pagingEnabled(isPagingEnabled)
            .itemHeight(itemHeight)
            .build()
        self.pageContent = pageContent
        _currentPage = currentPage
    }

    // MARK: Public

    // MARK: - Methods

    public func makeUIViewController(context _: Context) -> CXLazyPageViewController<PageContent> {
        CXLazyPageViewController(context: context, pageContent: pageContent) { currentPage in
            DispatchQueue.main.async {
                self.currentPage = currentPage
            }
        }
    }

    public func updateUIViewController(_ uiViewController: CXLazyPageViewController<PageContent>, context _: Context) {
        uiViewController.scrollToPageIfNeeded(currentPage)
    }

    // MARK: Internal

    @Binding var currentPage: Int

    // MARK: Private

    private let context: CXLazyPageContext

    @ViewBuilder private var pageContent: (Int) -> PageContent

}
