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

    init(onPageIndexUpdate: @escaping (Int) -> Void) {
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
        setupCollectionViewLayout()
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

    /// A closure that is called when the current page index is updated.
    let onPageIndexUpdate: (Int) -> Void

    private(set) lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        setupCollectionViewLayout(layout: layout)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(
            UICollectionViewCell.self,
            forCellWithReuseIdentifier: CXLazyBaseViewController.reuseIdentifier
        )
        setupCollectionView(collectionView: collectionView)
        return collectionView
    }()

    var numberOfItems: Int {
        .zero
    }

    func scrollToPageIndexIfNeeded(_: Int, animated _: Bool = true) { }

    func scrollTo(indexPath _: IndexPath, animated _: Bool = true) { }

    func updateCurrentPageIndex(with pageIndex: Int) {
        guard pageIndex != currentPageIndex else {
            return
        }
        currentPageIndex = pageIndex
        onPageIndexUpdate(pageIndex)
    }

    func setupCollectionViewLayout(layout _: UICollectionViewFlowLayout) { }

    func setupCollectionView(collectionView _: UICollectionView) { }

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

    private func setupCollectionViewLayout() {
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
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
