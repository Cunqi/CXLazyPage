//
//  CXLazyPageViewController.swift
//  CXLazyPage
//
//  Created by Cunqi Xiao on 7/7/25.
//

import SwiftUI
import UIKit

// MARK: - CXLazyPageViewController

public class CXLazyPageViewController<Content: View>: CXLazyBaseViewController,
    UICollectionViewDelegateFlowLayout {
    // MARK: Lifecycle

    // MARK: - Initializer

    /// Initializes a new instance of `CXLazyPageViewController`.
    /// - Parameters:
    ///   - context: The context that defines the configuration of the lazy page.
    ///   - content: A closure that provides the content for each page based on its index.
    ///   - onPageIndexUpdate: A closure that is called when the current page index is updated.
    public init(
        context: CXLazyPageContext,
        content: @escaping (Int) -> Content,
        onPageIndexUpdate: @escaping (Int) -> Void
    ) {
        self.content = content
        super.init(context: context, onPageIndexUpdate: onPageIndexUpdate)
    }

    // MARK: Public

    // MARK: - UICollectionViewDelegateFlowLayout

    public override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageSize = context.axis == .horizontal
            ? collectionView.bounds.width
            : collectionView.bounds.height
        let offset = context.axis == .horizontal
            ? scrollView.contentOffset.x
            : scrollView.contentOffset.y

        // Calculate the page index based on the current offset and page size.
        let pageIndex = Int((offset + pageSize / 2) / pageSize)

        updateCurrentPageIndex(with: pageIndex)
        reloadAfterFastScrollIfNeeded()
    }

    // MARK: Internal

    override var numberOfItems: Int {
        CXLazyPageViewController.maxPageCount
    }

    override var initialPageIndex: Int {
        CXLazyPageViewController.maxPageCount / 2
    }

    override var flowlayoutDelegate: (any UICollectionViewDelegateFlowLayout)? {
        self
    }

    override func updateCurrentPageIndex(with pageIndex: Int) {
        guard pageIndex != currentPageIndex else {
            return
        }
        currentPageIndex = pageIndex
        onPageIndexUpdate(pageIndex - anchorPageIndex)
    }

    // MARK: - Internal methods

    override func onViewDidLayoutSubviews() {
        /// Ensure the collection view layout is updated to match the current bounds.
        /// avoid calling `collectionView.sizeForItemAt` since it will pre-calculate the size of each item
        /// and we have `10_0000000` items, which will cause performance issues.
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let itemHeight = context.itemHeight ?? collectionView.bounds.size.height
            layout.itemSize = CGSize(width: collectionView.bounds.size.width, height: itemHeight)
        }
    }

    /// Scrolls to the specified page index if it is different from the current page index.
    /// - Parameters:
    ///   - pageIndex: The index of the page to scroll to. This index is relative to the `pageAnchor`.
    ///   - animated: A Boolean value indicating whether the scrolling should be animated. Defaults to `true`.
    override func scrollToPageIndexIfNeeded(_ pageIndex: Int, animated: Bool = true) {
        guard pageIndex + anchorPageIndex != currentPageIndex else {
            return
        }
        isFastScrolling = true
        let indexPath = IndexPath(item: pageIndex + anchorPageIndex, section: 0)
        scrollTo(indexPath: indexPath, animated: animated)
    }

    override func configure(cell: UICollectionViewCell, at indexPath: IndexPath) {
        let pageIndex = indexPath.item - anchorPageIndex
        cell.contentConfiguration = UIHostingConfiguration {
            content(pageIndex)
        }
        .margins(.all, .zero)
    }

    // MARK: Private

    // MARK: - Constants

    /// The maximum number of pages that can be displayed.
    /// this is used to make the collection view fake infinite
    private static var maxPageCount: Int { 100_000_000 }

    /// The content to be displayed on each page.
    private let content: (Int) -> Content
}
