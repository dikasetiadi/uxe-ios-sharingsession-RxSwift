
import UIKit
import Foundation
import RxSwift
import RxCocoa
import RxDataSources

struct ToDoTask: Equatable, Hashable {
    let title: String
    let done: Bool = false
}

struct SectionTypeTask {
    var header: String
    var items: [Item]
}

extension SectionTypeTask: SectionModelType {
    typealias Item = ToDoTask
    
    init(original: SectionTypeTask, items: [Item]) {
        self = original
        self.items = items
    }
}

class TodolistUsingRXViewController: UIViewController {

    let ongoing: BehaviorRelay<[ToDoTask]> = BehaviorRelay(value: [])
    let done: BehaviorRelay<[ToDoTask]> = BehaviorRelay(value: [])
    
    let sections: BehaviorRelay<[SectionTypeTask]> = BehaviorRelay(value: [
        SectionTypeTask(header: "Ongoing", items: [ToDoTask(title: "ongoing1")]),
        SectionTypeTask(header: "Done", items: [ToDoTask(title: "Done1")]),
    ])
    
    let dataSources = RxTableViewSectionedReloadDataSource<SectionTypeTask>(
        configureCell: { dataSource, tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: ToDoCell.identifierCell, for: indexPath) as! ToDoCell

            cell.textLabel?.text = dataSource[indexPath].title

            return cell
        },
        titleForHeaderInSection: { ds, index in
            return "\(ds.sectionModels[index].header) (\(ds.sectionModels[index].items.count) Task)"
        },
        canEditRowAtIndexPath: { _, _ in
            return true
        }
    )
    
    private let deleteSubject = PublishSubject<IndexPath>()
    private let editTaskSubject = PublishSubject<IndexPath>()
    private let moveTaskSubject = PublishSubject<IndexPath>()

    private var tableView = UITableView()
    private let disposeBag = DisposeBag()
    private var totalTask = 0
    
    private lazy var notifOngoing: UILabel = {
        let viewNotif = UILabel()
        viewNotif.text = "0"
        viewNotif.backgroundColor = .red
        viewNotif.textColor = .white
        viewNotif.layer.cornerRadius = 12
        viewNotif.layer.masksToBounds = true
        viewNotif.textAlignment = .center
        viewNotif.translatesAutoresizingMaskIntoConstraints = false
        
        return viewNotif
    }()
    
    private lazy var notifDone: UILabel = {
        let viewNotif = UILabel()
        viewNotif.text = "0"
        viewNotif.backgroundColor = .blue
        viewNotif.textColor = .white
        viewNotif.layer.cornerRadius = 12
        viewNotif.layer.masksToBounds = true
        viewNotif.textAlignment = .center
        viewNotif.translatesAutoresizingMaskIntoConstraints = false
        
        return viewNotif
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.addArrangedSubview(self.notifOngoing)
        stackView.addArrangedSubview(self.notifDone)
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.isBaselineRelativeArrangement = true
        
        return stackView
    }()
            
    private func setupNavigationView() {
        navigationItem.title = "TodoList - \(totalTask) Task"
        
        if #available(iOS 13.0, *) {
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithOpaqueBackground()
            navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.black]
            navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]
            navBarAppearance.backgroundColor = .white
            navigationController?.navigationBar.standardAppearance = navBarAppearance
            navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        }
        
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let barButton = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
        navigationItem.leftBarButtonItem = barButton
        navigationItem.leftBarButtonItem?
            .rx
            .tap
            .asDriver()
            .drive(onNext: { [weak self] _ in
                self?.didTapNextButton()
            })
            .disposed(by: disposeBag)
        
        NSLayoutConstraint.activate([
            notifOngoing.widthAnchor.constraint(equalToConstant: 24),
            notifOngoing.heightAnchor.constraint(equalToConstant: 24),
            notifDone.widthAnchor.constraint(equalToConstant: 24),
            notifDone.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stackView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationView()
        
        setupTableView()
        setupTableUsingRx()
    }
    
    private func setupTableView() {
        tableView = UITableView(frame: view.frame)
        tableView.backgroundColor = UIColor.white
        
        tableView.register(ToDoCell.self, forCellReuseIdentifier: ToDoCell.identifierCell)
        tableView.tableFooterView = UIView()
        
        view.addSubview(tableView)
    }
    
    ///MARK: Rx Setup
    private func setupTableUsingRx() {
        //set & populate number of rows table
        sections
            .bind(to: tableView.rx.items(dataSource: dataSources))
            .disposed(by: disposeBag)
        
        // set delegate the tableView
        // usually you will code like this
        // yourTableView.delegate = self
        tableView.rx.setDelegate(self).disposed(by: disposeBag)
        
        // set PublishSubject to delete task event listener
        // when we use .onNext() this line of code will be triggered to run
        deleteSubject
            .asDriver(onErrorJustReturn: IndexPath(row: 0, section: 0))
            .drive(onNext: { [sections] deletedIndex in
                var tableData = sections.value
                var sectionData = tableData[deletedIndex.section].items
                sectionData.remove(at: deletedIndex.row)
                tableData[deletedIndex.section].items = sectionData
                
                sections.accept(tableData)
            })
            .disposed(by: disposeBag)
        
        // set PublishSubject to move task event listener
        // when we use .onNext() this line of code will be triggered to run
        moveTaskSubject
            .asDriver(onErrorJustReturn: IndexPath(row: 0, section: 0))
            .drive(onNext: { [sections] movedDataIndex in
                let toMoveIndex = movedDataIndex.section == 0 ? 1 : 0
                var tableData = sections.value
                var sectionDataOld = tableData[movedDataIndex.section].items
                var sectionDataMoved = tableData[toMoveIndex].items
                
                let dataWillMoved = sectionDataOld[movedDataIndex.row]
                sectionDataMoved.append(dataWillMoved)
                sectionDataOld.remove(at: movedDataIndex.row)
                
                tableData[movedDataIndex.section].items = sectionDataOld
                tableData[toMoveIndex].items = sectionDataMoved
                
                sections.accept(tableData)
            })
            .disposed(by: disposeBag)
        
        //we use Rx way to attach onselect Event on tableCell
        tableView.rx.itemSelected.asDriver().drive(onNext: { [weak self] (IndexPath) in
            self?.moveTaskSubject.onNext(IndexPath)
            self?.tableView.reloadData()
        })
        .disposed(by: disposeBag)
         
        // in this code we always watch to any changes to its data
        // so when changes occured, we will trigger next event
        sections
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] data in
                guard let self = self else { return }
                
                let isHiddenNotifOnGoing = data[0].items.count >= 1 ? false : true
                let isHiddenNotifDone = data[1].items.count >= 1 ? false : true
                self.notifOngoing.text = "\(data[0].items.count)"
                self.notifDone.text = "\(data[1].items.count)"

                DispatchQueue.main.async {
                    UIView.animate(withDuration: 0.24) { [weak self] in
                        if isHiddenNotifOnGoing, isHiddenNotifDone {
                            self?.stackView.arrangedSubviews[1].transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
                            self?.stackView.arrangedSubviews[0].transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
                        } else {
                            
                            //done
                            self?.stackView.arrangedSubviews[1].transform = isHiddenNotifDone ? CGAffineTransform(scaleX: 0.01, y: 0.01) : .identity
                            //ongoing
                            self?.stackView.arrangedSubviews[0].transform = isHiddenNotifOnGoing ? CGAffineTransform(scaleX: 0.01, y: 0.01) : .identity
                        }
                    }
                    
                    self.stackView.layoutIfNeeded()
                    self.stackView.setNeedsLayout()
                    self.stackView.setNeedsDisplay()
                    self.navigationItem.rightBarButtonItem?.customView?.layoutIfNeeded()
                }
                                
                self.totalTask = data[0].items.count + data[1].items.count
                self.navigationItem.rx.title.onNext("TodoList - \(self.totalTask) Task")
            })
            .disposed(by: disposeBag)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
        
    @objc func didTapNextButton () {
        let alert = UIAlertController(title: "Add Todo", message: "Enter a text", preferredStyle: .alert)

        //2. Add the text field. You can configure it however you need.
        alert.addTextField { (textField) in
            textField.placeholder = "Code Review"
        }

        // 3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert, weak self] (_) in
            guard let self = self else { return }
            let textField = alert?.textFields?[0]
            
            var sectionData = self.sections.value
            var onGoingSectionData = sectionData[0].items
            if let newText = textField?.text, newText.count > 0 {
                onGoingSectionData.append(ToDoTask(title: newText))
                sectionData[0].items = onGoingSectionData
                
                self.sections.accept(sectionData)
                
                self.tableView.reloadData()
            }
        }))

        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
}

extension TodolistUsingRXViewController: UITableViewDelegate {
    //right side action
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .normal, title: "") { [deleteSubject] cc, _, _ in
            deleteSubject.onNext(indexPath)
        }
        
        deleteAction.image = UIImage(imageLiteralResourceName: "delete")
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    //left side action
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .normal, title: "") { [deleteSubject] cc, _, _ in
            deleteSubject.onNext(indexPath)
        }
        
        deleteAction.image = UIImage(imageLiteralResourceName: "delete")
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

