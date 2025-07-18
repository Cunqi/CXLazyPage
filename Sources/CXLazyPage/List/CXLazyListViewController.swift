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

public class CXLazyListViewController<Content: View>: CXLazyBaseViewController,
    UICollectionViewDelegateFlowLayout
{

    // MARK: Lifecycle

    // MARK: - Initializer

    /// Initializes a new instance of `CXLazyListViewController`.
    /// - Parameters:
    ///   - content: A closure that provides the content for each page based on its index.
    ///   - heightOf: A closure that provides the height for each page based on its index.
    ///   - onPageIndexUpdate: A closure that is called when the current page index is updated.
    public init(
        content: @escaping (Int) -> Content,
        heightOf: @escaping (Int) -> Int,
        onPageIndexUpdate: @escaping (Int) -> Void
    ) {
        self.content = content
        self.heightOf = heightOf
        super.init(onPageIndexUpdate: onPageIndexUpdate)
    }

    // MARK: Public

    override public func viewDidLoad() {
        super.viewDidLoad()

        // Set up the anchor page index to the middle of the initial page count.
        anchorPageIndex = CXLazyListViewController.initialPageCount

        // set `curerntPageIndex` to anchorPageIndex initially
        updateCurrentPageIndex(with: anchorPageIndex)
    }

    override public func viewDidLayoutSubviews() {
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
        let itemHeight = heightOf(items[indexPath.item])
        return CGSize(width: collectionView.bounds.width, height: CGFloat(itemHeight))
    }

    public func scrollViewDidEndDecelerating(_: UIScrollView) {
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

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
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

        viewportTracker.track()
    }

    // MARK: Internal

    override var numberOfItems: Int {
        items.count
    }

    override func setupCollectionViewLayout(layout: UICollectionViewFlowLayout) {
        layout.scrollDirection = .vertical
    }

    override func setupCollectionView(collectionView: UICollectionView) {
        collectionView.isPagingEnabled = false
        collectionView.delegate = self
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
        guard
            let index = items.firstIndex(of: pageIndex),
            currentPageIndex != index
        else {
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
    private var heightOf: (Int) -> Int

    private lazy var viewportTracker = ViewportTracker(
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
