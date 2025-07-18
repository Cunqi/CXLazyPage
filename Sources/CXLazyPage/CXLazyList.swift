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
        @ViewBuilder content: @escaping (Int) -> Content,
        heightOf: @escaping (Int) -> Int
    ) {
        self.content = content
        self.heightOf = heightOf
    }

    // MARK: Public

    // MARK: - Methods

    public func makeUIViewController(context _: Context) -> CXLazyListViewController<Content> {
        CXLazyListViewController(content: content, heightOf: heightOf) { _ in
        }
    }

    public func updateUIViewController(_: CXLazyListViewController<Content>, context _: Context) { }

    // MARK: Private

    @ViewBuilder private let content: (Int) -> Content

    private var heightOf: (Int) -> Int

}
