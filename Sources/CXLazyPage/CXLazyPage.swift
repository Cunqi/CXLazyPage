//
//  CXLazyPage.swift
//  CXLazyPage
//
//  Created by Cunqi Xiao on 7/7/25.
//

import SwiftUI

public struct CXLazyPage<PageContent: View>: UIViewControllerRepresentable {

    // MARK: - Properties

    @Binding var currentPage: Int
    private let context: CXLazyPageContext

    @ViewBuilder
    private var pageContent: (Int) -> PageContent

    // MARK: - Initializer

    public init(axis: Axis = .horizontal,
                currentPage: Binding<Int> = .constant(0),
                @ViewBuilder pageContent: @escaping (Int) -> PageContent) {
        self.context = CXLazyPageContext.Builder()
            .axis(axis)
            .pagingEnabled(true)
            .build()
        self.pageContent = pageContent
        self._currentPage = currentPage
    }

    // MARK: - Methods

    public func makeUIViewController(context: Context) -> CXLazyPageViewController<PageContent> {
        CXLazyPageViewController(context: self.context, pageContent: pageContent) { currentPage in
            DispatchQueue.main.async {
                self.currentPage = currentPage
            }
        }
    }

    public func updateUIViewController(_ uiViewController: CXLazyPageViewController<PageContent>, context: Context) {
        uiViewController.scrollToPageIfNeeded(currentPage)
    }
}
