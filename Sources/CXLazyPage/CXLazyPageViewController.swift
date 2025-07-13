//
//  CXLazyPageViewController.swift
//  CXLazyPage
//
//  Created by Cunqi Xiao on 7/7/25.
//

import SwiftUI
import UIKit

public class CXLazyPageViewController<PageContent: View>: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    // MARK: - Constants
    
    /// The maximum number of pages that can be displayed.
    /// this is used to make the collection view fake infinite
    private static var maxPageCount: Int {
        10_0000000
    }

    private static var reuseIdentifier: String {
        "LazyPageViewControllerReuseIdentifier"
    }

    // MARK: - Properties

    /// The anchor page index used to make the starting point of the collection view.
    private var pageAnchor = maxPageCount / 2

    private let context: CXLazyPageContext

    /// The content to be displayed on each page.
    private var pageContent: (Int) -> PageContent

    /// the page index of the currently visible page. this is the single source of
    /// truth for the current page index
    private var currentPageIndex: Int = 0

    /// A closure that is called when the current page index is updated.
    private var onPageIndexUpdate: ((Int) -> Void)

    /// A flag to indicate if the collection view is currently fast scrolling. this usually happens
    /// when the `pageIndex` is changed significantly, this will prevent `pageContent` from being updated
    /// until the scrolling is finished.
    private var isFastScrolling = false

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = context.axis.scrollDirection
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isPagingEnabled = context.isPagingEnabled
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: CXLazyPageViewController.reuseIdentifier)
        return collectionView
    }()

    // MARK: - Initializer
    
    /// Initializes a new instance of `CXLazyPageViewController`.
    /// - Parameters:
    ///   - context: The context that defines the configuration of the lazy page.
    ///   - pageContent: A closure that provides the content for each page based on its index.
    ///   - onPageIndexUpdate: A closure that is called when the current page index is updated.
    public init(context: CXLazyPageContext,
                pageContent: @escaping (Int) -> PageContent,
                onPageIndexUpdate: @escaping (Int) -> Void = { _ in }) {
        self.context = context
        self.pageContent = pageContent
        self.onPageIndexUpdate = onPageIndexUpdate
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()

        // set `curerntPageIndex` to 0 initially
        updateCurrentPageIndex(with: 0)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        /// Ensure the collection view layout is updated to match the current bounds.
        /// avoid calling `collectionView.sizeForItemAt` since it will pre-calculate the size of each item
        /// and we have `10_0000000` items, which will cause performance issues.
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = collectionView.bounds.size
        }

        /// Ensure the collection view is scrolled to the anchor page index before displaying.
        if collectionView.indexPathsForVisibleItems.contains(IndexPath(item: pageAnchor, section: 0)) == false {
            scrollTo(indexPath: IndexPath(item: pageAnchor, section: 0))
        }
    }

    // MARK: - Public methods
    
    /// Scrolls to the specified page index if it is different from the current page index.
    /// - Parameters:
    ///   - pageIndex: The index of the page to scroll to. This index is relative to the `pageAnchor`.
    ///   - animated: A Boolean value indicating whether the scrolling should be animated. Defaults to `true`.
    public func scrollToPageIfNeeded(_ pageIndex: Int, animated: Bool = true) {
        guard pageIndex != currentPageIndex else {
            return
        }
        isFastScrolling = true
        let indexPath = IndexPath(item: pageIndex + pageAnchor, section: 0)
        scrollTo(indexPath: indexPath, animated: animated)
    }

    // MARK: - Private methods

    private func setupCollectionView() {
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func updateCurrentPageIndex(with index: Int) {
        currentPageIndex = index
        onPageIndexUpdate(index)
    }

    private func scrollTo(indexPath: IndexPath, animated: Bool = false) {
        // disable paging temporarily to allow scrolling to a specific item, otherwise scrollToItem won't work.
        // https://akshay-s-somkuwar.medium.com/uicollectionview-scrolltoitem-issue-and-its-fix-xcode-ios-14-and-swift-a886141b459a
        collectionView.isPagingEnabled = false
        collectionView.scrollToItem(at: indexPath, at: context.axis.scrollPosition, animated: animated)
        collectionView.isPagingEnabled = context.isPagingEnabled ? true : false
    }

    // MARK: - UICollectionViewDataSource

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return CXLazyPageViewController.maxPageCount
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CXLazyPageViewController.reuseIdentifier, for: indexPath)

        if !isFastScrolling {
            let pageIndex = indexPath.item - pageAnchor
            cell.contentConfiguration = UIHostingConfiguration {
                pageContent(pageIndex)
            }
            .margins(.all, .zero)
        }

        return cell
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageSize = context.axis == .horizontal ? collectionView.bounds.width : collectionView.bounds.height
        let offset = context.axis == .horizontal ? scrollView.contentOffset.x : scrollView.contentOffset.y

        // Calculate the page index based on the current offset and page size.
        let page = Int((offset + pageSize / 2) / pageSize)
        let pageIndex = page - pageAnchor

        updateCurrentPageIndex(with: pageIndex)

        // if it is decelerating from a fast scroll, we need to reload the data to ensure the displayed content is correct
        if isFastScrolling {
            collectionView.reloadData()
            isFastScrolling = false
        }
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            scrollViewDidEndDecelerating(scrollView)
        }
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        scrollViewDidEndDecelerating(scrollView)
    }
}

extension SwiftUI.Axis {
    var scrollDirection: UICollectionView.ScrollDirection {
        switch self {
        case .horizontal:
            return .horizontal
        case .vertical:
            return .vertical
        }
    }

    var scrollPosition: UICollectionView.ScrollPosition {
        switch self {
        case .horizontal:
            return .centeredHorizontally
        case .vertical:
            return .centeredVertically
        }
    }
}
