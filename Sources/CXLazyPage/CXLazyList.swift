//
//  CXLazyList.swift
//  CXLazyPage
//
//  Created by Cunqi Xiao on 7/14/25.
//

import SwiftUI

public struct CXLazyList<ListContent: View>: UIViewControllerRepresentable {

    // MARK: - Properties

    @ViewBuilder
    private var listContent: (Int) -> ListContent

    private var heightOf: (Int) -> Int

    // MARK: - Initializer

    public init(@ViewBuilder listContent: @escaping (Int) -> ListContent,
                heightOf: @escaping (Int) -> Int) {
        self.listContent = listContent
        self.heightOf = heightOf
    }

    // MARK: - Methods

    public func makeUIViewController(context: Context) -> CXLazyListViewController<ListContent> {
        CXLazyListViewController(listContent: listContent, heightOf: heightOf)
    }

    public func updateUIViewController(_ uiViewController: CXLazyListViewController<ListContent>, context: Context) {
    }
}
