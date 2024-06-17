//
//  ViewController.swift
//  DiffableDataSourceDeadlock
//
//  Created by Thomas Heß on 17.06.24.
//

import UIKit

class ViewController: UICollectionViewController {

    private enum SectionIdentifier: Hashable {
        case test
    }

    private enum ItemIdentifier: Hashable {
        case test(UUID)
    }

    private typealias Snapshot = NSDiffableDataSourceSnapshot<SectionIdentifier, ItemIdentifier>
    private typealias SectionSnapshot = NSDiffableDataSourceSectionSnapshot<ItemIdentifier>

    private typealias DataSource = UICollectionViewDiffableDataSource<SectionIdentifier, ItemIdentifier>

    private lazy var dataSource: DataSource = {

        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, UIColor> { cell, _, color in
            cell.contentView.backgroundColor = color
        }

        return DataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, itemIdentifier in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: .red)
        }
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        collectionView.dataSource = dataSource
        collectionView.collectionViewLayout = UICollectionViewCompositionalLayout { [weak self] section, environment -> NSCollectionLayoutSection? in

            // calling `UICollectionViewDiffableDataSource.snapshot(for:)` from the `UICollectionViewCompositionalLayoutSectionProvider` leads to deadlock on iOS 18
            let numberOfItems = self?.dataSource.snapshot(for: .test).items.count ?? 0 // deadlock
            // calling `UICollectionViewDiffableDataSource.snapshot()` causes no issue
//            let numberOfItems = self?.dataSource.snapshot().numberOfItems(inSection: .test) ?? 0 // works

            let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .absolute(100), heightDimension: .absolute(100)))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(100)), repeatingSubitem: item, count: numberOfItems)
            group.interItemSpacing = .fixed(5)
            return .init(group: group)
        }

        var snapshot = Snapshot()
        snapshot.appendSections([.test])
        snapshot.appendItems([.test(UUID()), .test(UUID()), .test(UUID()), .test(UUID())])

        // using the async wrapper `UICollectionViewDiffableDataSource.apply()` on any thread leads to deadlock on iOS 18
        Task { await dataSource.apply(snapshot) } // deadlock
//        Task { @MainActor in await dataSource.apply(snapshot) } // deadlock
        // using `UICollectionViewDiffableDataSource.apply()` with completion handling causes no issue
//        Task { dataSource.apply(snapshot) } // works
//        dataSource.apply(snapshot) // works
    }
}
