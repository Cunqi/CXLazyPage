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
    UICollectionViewDelegateFlowLayout
{

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
        self.context = context
        self.content = content
        super.init(onPageIndexUpdate: onPageIndexUpdate)
    }

    // MARK: Public

    public override func viewDidLoad() {
        super.viewDidLoad()

        // set `curerntPageIndex` to 0 initially
        updateCurrentPageIndex(with: .zero)

        /// Set the anchor page index to the middle of the maximum page count.
        anchorPageIndex = CXLazyPageViewController.maxPageCount / 2
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        /// Ensure the collection view layout is updated to match the current bounds.
        /// avoid calling `collectionView.sizeForItemAt` since it will pre-calculate the size of each item
        /// and we have `10_0000000` items, which will cause performance issues.
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let itemHeight = context.itemHeight ?? collectionView.bounds.size.height
            layout.itemSize = CGSize(width: collectionView.bounds.size.width, height: itemHeight)
        }

        /// Ensure the collection view is scrolled to the anchor page index before displaying.
        let anchorIndexPath = IndexPath(item: anchorPageIndex, section: 0)
        if collectionView.indexPathsForVisibleItems.contains(anchorIndexPath) == false {
            scrollTo(indexPath: anchorIndexPath)
        }
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageSize = context.axis == .horizontal
            ? collectionView.bounds.width
            : collectionView.bounds.height
        let offset = context.axis == .horizontal
            ? scrollView.contentOffset.x
            : scrollView.contentOffset.y

        // Calculate the page index based on the current offset and page size.
        let page = Int((offset + pageSize / 2) / pageSize)
        let pageIndex = page - pageAnchor

        updateCurrentPageIndex(with: pageIndex)
        reloadAfterFastScrollIfNeeded()
    }

    public func scrollViewDidEndDragging(
        _ scrollView: UIScrollView,
        willDecelerate decelerate: Bool
    ) {
        if !decelerate {
            scrollViewDidEndDecelerating(scrollView)
        }
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        scrollViewDidEndDecelerating(scrollView)
    }

    // MARK: Internal

    override var numberOfItems: Int {
        CXLazyPageViewController.maxPageCount
    }

    // MARK: - Internal methods

    /// Scrolls to the specified page index if it is different from the current page index.
    /// - Parameters:
    ///   - pageIndex: The index of the page to scroll to. This index is relative to the `pageAnchor`.
    ///   - animated: A Boolean value indicating whether the scrolling should be animated. Defaults to `true`.
    override func scrollToPageIndexIfNeeded(_ pageIndex: Int, animated: Bool = true) {
        guard pageIndex != currentPageIndex else {
            return
        }
        isFastScrolling = true
        let indexPath = IndexPath(item: pageIndex + pageAnchor, section: 0)
        scrollTo(indexPath: indexPath, animated: animated)
    }

    override func setupCollectionViewLayout(layout: UICollectionViewFlowLayout) {
        layout.scrollDirection = context.axis.scrollDirection
    }

    override func setupCollectionView(collectionView: UICollectionView) {
        collectionView.isPagingEnabled = context.isPagingEnabled
        collectionView.delegate = self
    }

    override func configure(cell: UICollectionViewCell, at indexPath: IndexPath) {
        let pageIndex = indexPath.item - pageAnchor
        cell.contentConfiguration = UIHostingConfiguration {
            content(pageIndex)
        }
        .margins(.all, .zero)
    }

    override func scrollTo(indexPath: IndexPath, animated: Bool = false) {
        // disable paging temporarily to allow scrolling to a specific item, otherwise
        // scrollToItem won't work.
        // https://akshay-s-somkuwar.medium.com/uicollectionview-scrolltoitem-issue-and-its-fix-xcode-ios-14-and-swift-a886141b459a
        collectionView.isPagingEnabled = false
        collectionView.scrollToItem(
            at: indexPath,
            at: context.axis.scrollPosition,
            animated: animated
        )
        collectionView.isPagingEnabled = context.isPagingEnabled ? true : false
    }

    // MARK: Private

    // MARK: - Constants

    /// The maximum number of pages that can be displayed.
    /// this is used to make the collection view fake infinite
    private static var maxPageCount: Int { 100_000_000 }

    /// The anchor page index used to make the starting point of the collection view.
    private let pageAnchor = maxPageCount / 2

    private let context: CXLazyPageContext

    /// The content to be displayed on each page.
    private let content: (Int) -> Content
}

extension SwiftUI.Axis {
    fileprivate var scrollDirection: UICollectionView.ScrollDirection {
        switch self {
        case .horizontal:
            .horizontal
        case .vertical:
            .vertical
        }
    }

    fileprivate var scrollPosition: UICollectionView.ScrollPosition {
        switch self {
        case .horizontal:
            .centeredHorizontally
        case .vertical:
            .centeredVertically
        }
    }
}
