//
//  SingleRowCollectionView.swift
//
//  Created by Maros Seleng on 10/05/16.
//

import RxCocoa
import RxSwift

open class SingleRowCollectionView<CELL: UIView>: ViewBase<TableViewState<CELL.StateType>> where CELL: Component {
    private typealias MODEL = CELL.StateType
    
    open var modelSelected: ControlEvent<MODEL> {
        return collectionView.rx.modelSelected(MODEL.self)
    }
    
    open override var edgesForExtendedLayout: UIRectEdge {
        return .all
    }
    
    open let collectionView: UICollectionView
    open let collectionViewLayout = UICollectionViewFlowLayout()
    private let emptyLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    
    private let cellFactory: () -> CELL
    
    public init(
        cellFactory: @escaping () -> CELL,
        itemSize: CGSize = CGSize.zero,
        estimatedItemSize: CGSize = CGSize.zero,
        minimumLineSpacing: CGFloat = 0,
        horizontalInsets: CGFloat = 0,
        scrollDirection: UICollectionViewScrollDirection = .horizontal)
    {
        self.collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: collectionViewLayout)
        self.cellFactory = cellFactory
        
        super.init()
        
        collectionViewLayout.itemSize = itemSize
        collectionViewLayout.estimatedItemSize = estimatedItemSize
        collectionViewLayout.minimumLineSpacing = minimumLineSpacing
        collectionViewLayout.scrollDirection = scrollDirection
        
        collectionView.backgroundColor = UIColor.clear
        collectionView.contentInset = UIEdgeInsets(top: 0, left: horizontalInsets, bottom: 0, right: horizontalInsets)
        collectionView.register(RxCollectionViewCell<CELL>.self, forCellWithReuseIdentifier: "Cell")
        
        ReactantConfiguration.global.emptyListLabelStyle(emptyLabel)
    }
    
    open override func loadView() {
        children(
            collectionView,
            emptyLabel,
            loadingIndicator
        )
        
        loadingIndicator.hidesWhenStopped = true
    }
    
    open override func render() {
        var items: [MODEL] = []
        var loading: Bool = false
        var emptyMessage: String = ""
        
        switch componentState {
        case .items(let models):
            items = models
        case .empty(let message):
            emptyMessage = message
        case .loading:
            loading = true
        }
        
        emptyLabel.text = emptyMessage
        
        if loading {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
        
        
        Observable.just(items)
            .bindTo(collectionView.rx.items(cellIdentifier: "Cell", cellType: RxCollectionViewCell<CELL>.self)) { [cellFactory] _, model, cell in
                cell.cachedContentOrCreated(factory: cellFactory).setComponentState(model)
            }
            .addDisposableTo(stateDisposeBag)
        
        collectionView.rx.itemSelected
            .subscribe(onNext: { [collectionView] in
                collectionView.deselectItem(at: $0, animated: true)
            })
            .addDisposableTo(stateDisposeBag)
        
        setNeedsLayout()
    }
    
    open override func updateConstraints() {
        super.updateConstraints()
        
        collectionView.snp.remakeConstraints { make in
            make.edges.equalTo(self)
        }
        
        emptyLabel.snp.remakeConstraints { make in
            make.center.equalTo(self)
        }
        
        loadingIndicator.snp.remakeConstraints { make in
            make.center.equalTo(self)
        }
    }
}
