//
//  CXLazyListViewController.swift
//  CXLazyPage
//
//  Created by Cunqi Xiao on 7/14/25.
//

import SwiftUI
import UIKit

public class CXLazyListViewController<ListContent: View>: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    // MARK: - Constants

    /// The initial number of items to display.
    private static var initialPageCount: Int { 24 }

    /// The number of items to load at a time.
    private static var chunkSize: Int { 12 }

    /// The buffer at the bottom of the collection view. this is used to trigger the loading of more data.
    private static var bottomBuffer: CGFloat { 100.0 }

    /// The buffer at the top of the collection view. this is used to trigger the loading of more data.
    private static var topBuffer: CGFloat { 400.0 }

    private static var reuseIdentifier: String { "LazyListViewControllerReuseIdentifier" }

    // MARK: - Properties

    /// The page offset for the anchor page.
    private var items: [Int] = (-initialPageCount ..< initialPageCount).map { $0 }

    /// The anchor page index used to make the starting point of the collection view.
    /// this should always point to the middle of the collection view.
    private var anchorPageIndex = initialPageCount

    /// A flag to indicate if the collection view is currently loading more data.
    private var isLoading = false

    /// The content to be displayed on each page.
    private var listContent: (Int) -> ListContent

    /// The height of each page.
    private var heightOf: (Int) -> Int

    /// A closure that is called when the current page index is updated.
    private var onPageIndexUpdate: (Int) -> Void

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isPagingEnabled = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: CXLazyListViewController.reuseIdentifier)
        return collectionView
    }()

    // MARK: - Initializer

    /// Initializes a new instance of `CXLazyListViewController`.
    /// - Parameters:
    ///   - listContent: A closure that provides the content for each page based on its index.
    ///   - heightOf: A closure that provides the height for each page based on its index.
    ///   - onPageIndexUpdate: A closure that is called when the current page index is updated.
    public init(listContent: @escaping (Int) -> ListContent,
                heightOf: @escaping (Int) -> Int,
                onPageIndexUpdate: @escaping (Int) -> Void = { _ in })
    {
        self.listContent = listContent
        self.heightOf = heightOf
        self.onPageIndexUpdate = onPageIndexUpdate
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        /// Ensure the collection view is scrolled to the anchor page index before displaying.
        if collectionView.indexPathsForVisibleItems.contains(IndexPath(item: anchorPageIndex, section: 0)) == false {
            collectionView.scrollToItem(at: IndexPath(item: anchorPageIndex, section: 0), at: .top, animated: false)
        }
    }

    // MARK: - Public methods

    // MARK: - Private methods

    private func setupCollectionView() {
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    // MARK: - UICollectionViewDataSource

    public func numberOfSections(in _: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        return items.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CXLazyListViewController.reuseIdentifier, for: indexPath)
        cell.contentConfiguration = UIHostingConfiguration {
            listContent(items[indexPath.item])
        }
        .margins(.all, .zero)
        return cell
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    public func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemHeight = heightOf(items[indexPath.item])
        return CGSize(width: collectionView.bounds.width, height: CGFloat(itemHeight))
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
    }

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
