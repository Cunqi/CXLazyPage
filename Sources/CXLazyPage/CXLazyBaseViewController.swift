//
//  CXLazyBaseViewController.swift
//  CXLazyPage
//
//  Created by Cunqi Xiao on 7/17/25.
//

import SwiftUI
import UIKit

// MARK: - CXLazyBaseViewController

public class CXLazyBaseViewController: UIViewController {
    // MARK: Lifecycle

    init(context: CXLazyPageContext, onPageIndexUpdate: @escaping (Int) -> Void) {
        self.context = context
        self.onPageIndexUpdate = onPageIndexUpdate
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupAndLayoutConstraints()

        // Set up the anchor page index to the initial page index
        anchorPageIndex = initialPageIndex

        // set `curerntPageIndex` to anchorPageIndex initially
        updateCurrentPageIndex(with: anchorPageIndex)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        onViewDidLayoutSubviews()

        /// Ensure the collection view is scrolled to the anchor page index before displaying.
        let anchorIndexPath = IndexPath(item: anchorPageIndex, section: 0)
        if collectionView.indexPathsForVisibleItems.contains(anchorIndexPath) == false {
            scrollTo(indexPath: anchorIndexPath)
        }
    }

    // MARK: Internal

    static var reuseIdentifier: String { "LazyBaseViewControllerReuseIdentifier" }

    /// the page index of the currently visible page. this is the single source of
    /// truth for the current page index
    var currentPageIndex = 0

    /// the anchor page index used to make the starting point of the collection view
    var anchorPageIndex = 0

    /// A flag to indicate if the collection view is currently fast scrolling. this usually happens
    /// when the `pageIndex` is changed significantly, this will prevent `pageContent` from being updated
    /// until the scrolling is finished.
    var isFastScrolling = false

    /// The context that defines the configuration of the lazy page.
    let context: CXLazyPageContext

    /// A closure that is called when the current page index is updated.
    let onPageIndexUpdate: (Int) -> Void

    private(set) lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = context.axis.scrollDirection

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = flowlayoutDelegate
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.isPagingEnabled = context.isPagingEnabled
        collectionView.register(
            UICollectionViewCell.self,
            forCellWithReuseIdentifier: CXLazyBaseViewController.reuseIdentifier
        )
        return collectionView
    }()

    var numberOfItems: Int {
        .zero
    }

    var initialPageIndex: Int {
        .zero
    }

    var flowlayoutDelegate: UICollectionViewDelegateFlowLayout? {
        nil
    }

    /// called when `viewDidLayoutSubviews` is called, subclasses can override this method to perform
    /// any additional layout or configuration.
    func onViewDidLayoutSubviews() { }

    func scrollToPageIndexIfNeeded(_: Int, animated _: Bool = true) { }

    func scrollTo(indexPath: IndexPath, animated: Bool = false) {
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

    func updateCurrentPageIndex(with pageIndex: Int) {
        guard pageIndex != currentPageIndex else {
            return
        }
        currentPageIndex = pageIndex
        onPageIndexUpdate(pageIndex)
    }

    func configure(cell _: UICollectionViewCell, at _: IndexPath) {
        fatalError("Subclasses must implement this method.")
    }

    /// if it is decelerating from a fast scroll, we need to reload the data to ensure
    /// the displayed content is correct
    func reloadAfterFastScrollIfNeeded() {
        if isFastScrolling {
            isFastScrolling = false
            collectionView.reloadData()
        }
    }

    // MARK: Private

    private func setupAndLayoutConstraints() {
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}

// MARK: UICollectionViewDataSource

extension CXLazyBaseViewController: UICollectionViewDataSource {
    public func numberOfSections(in _: UICollectionView) -> Int {
        1
    }

    public func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        numberOfItems
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CXLazyBaseViewController.reuseIdentifier,
            for: indexPath
        )
        if !isFastScrolling {
            configure(cell: cell, at: indexPath)
        }
        return cell
    }
}

// MARK: UIScrollViewDelegate

extension CXLazyBaseViewController: UIScrollViewDelegate {
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

    public func scrollViewDidEndDecelerating(_: UIScrollView) { }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) { }
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
