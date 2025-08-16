//
//  CXLazyListViewController.swift
//  CXLazyPage
//
//  Created by Cunqi Xiao on 7/14/25.
//

import Combine
import SwiftUI
import UIKit

// MARK: - CXLazyListViewController

public typealias CXLazyListHeightOfPage = (Int, CGFloat) -> CGFloat

public class CXLazyListViewController<Content: View>: CXLazyBaseViewController,
    UICollectionViewDelegateFlowLayout {
    // MARK: Lifecycle

    // MARK: - Initializer

    /// Initializes a new instance of `CXLazyListViewController`.
    /// - Parameters:
    ///   - context: The context that defines the configuration of the lazy page.
    ///   - content: A closure that provides the content for each page based on its index.
    ///   - heightOfPage: A closure that provides the height for each page based on its index.
    ///   - onPageIndexUpdate: A closure that is called when the current page index is updated.
    public init(
        context: CXLazyPageContext,
        content: @escaping (Int) -> Content,
        heightOfPage: @escaping CXLazyListHeightOfPage,
        onPageIndexUpdate: @escaping (Int) -> Void
    ) {
        self.content = content
        self.heightOfPage = heightOfPage
        super.init(context: context, onPageIndexUpdate: onPageIndexUpdate)
    }

    // MARK: Public

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Ensure the collection view is scrolled to the anchor page index before displaying.
        let anchorIndexPath = IndexPath(item: anchorPageIndex, section: 0)
        if collectionView.indexPathsForVisibleItems.contains(anchorIndexPath) == false {
            scrollTo(indexPath: anchorIndexPath)
        }

        viewportTracker.attachTrackerOverlay()
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    public func collectionView(
        _ collectionView: UICollectionView,
        layout _: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(
            width: collectionView.bounds.width,
            height: heightOfPage(items[indexPath.item], collectionView.bounds.width))
    }

    public override func scrollViewDidEndDecelerating(_: UIScrollView) {
        reloadAfterFastScrollIfNeeded()
    }

    public override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let scrollViewHeight = scrollView.bounds.height

        guard contentHeight > .zero else {
            return
        }

        if offsetY > contentHeight - scrollViewHeight - CXLazyListViewController.bottomBuffer {
            loadMoreDataIfNeeded(reversed: false)
        } else if offsetY < CXLazyListViewController.topBuffer {
            loadMoreDataIfNeeded(reversed: true)
        }

        viewportTracker.track(isFastScrolling)
    }

    // MARK: Internal

    override var numberOfItems: Int {
        items.count
    }

    override var initialPageIndex: Int {
        CXLazyListViewController.initialPageCount
    }

    override var flowlayoutDelegate: UICollectionViewDelegateFlowLayout? {
        self
    }

    override func configure(cell: UICollectionViewCell, at indexPath: IndexPath) {
        cell.contentConfiguration = UIHostingConfiguration {
            content(items[indexPath.item])
        }
        .margins(.all, .zero)
    }

    override func updateCurrentPageIndex(with pageIndex: Int) {
        guard pageIndex != currentPageIndex else {
            return
        }
        currentPageIndex = pageIndex
        onPageIndexUpdate(items[pageIndex])
    }

    override func scrollTo(indexPath: IndexPath, animated: Bool = false) {
        collectionView.scrollToItem(
            at: indexPath,
            at: .top,
            animated: animated
        )
    }

    override func scrollToPageIndexIfNeeded(_ pageIndex: Int, animated _: Bool = true) {
        guard let index = items.firstIndex(of: pageIndex), currentPageIndex != index else {
            return
        }
        isFastScrolling = true
        scrollTo(indexPath: IndexPath(item: index, section: 0), animated: true)
    }

    // MARK: Private

    // MARK: - Constants

    /// The initial number of items to display.
    private static var initialPageCount: Int { 24 }

    /// The number of items to load at a time.
    private static var chunkSize: Int { 12 }

    /// The buffer at the bottom of the collection view. this is used to trigger the loading of more data.
    private static var bottomBuffer: CGFloat { 100.0 }

    /// The buffer at the top of the collection view. this is used to trigger the loading of more data.
    private static var topBuffer: CGFloat { 400.0 }

    /// The page offset for the anchor page.
    private var items: [Int] = (-initialPageCount ..< initialPageCount).map { $0 }

    /// A flag to indicate if the collection view is currently loading more data.
    private var isLoading = false

    /// The content to be displayed on each page.
    private var content: (Int) -> Content

    /// The height of each page.
    private var heightOfPage: CXLazyListHeightOfPage

    private lazy var viewportTracker = ViewportTracker(
        context: context.viewportTrackerContext,
        collectionView: collectionView,
        onViewportUpdate: { [weak self, items] viewport in
            self?.updateCurrentPageIndex(with: viewport.indexPath.item)
        }
    )

    // MARK: - Private methods

    private func loadMoreDataIfNeeded(reversed: Bool) {
        guard !isLoading else {
            return
        }

        isLoading = true
        let oldContentHeight = collectionView.contentSize.height
        if reversed, let first = items.first {
            let chunk = (first - CXLazyListViewController.chunkSize ..< first).map { $0 }
            UIView.performWithoutAnimation {
                collectionView.performBatchUpdates({
                    items.insert(contentsOf: chunk, at: 0)
                    anchorPageIndex += CXLazyListViewController.chunkSize

                    let indexPaths = chunk.indices.map {
                        IndexPath(item: $0, section: 0)
                    }
                    collectionView.insertItems(at: indexPaths)
                }, completion: { _ in
                    self.collectionView.layoutIfNeeded()

                    let newContentHeight = self.collectionView.contentSize.height
                    let delta = newContentHeight - oldContentHeight

                    self.collectionView.contentOffset.y += delta
                    self.isLoading = false
                })
            }
        } else if let last = items.last {
            let chunk = (last + 1 ..< last + CXLazyListViewController.chunkSize).map { $0 }
            items.append(contentsOf: chunk)
            collectionView.reloadData()
        }

        isLoading = false
    }
}
