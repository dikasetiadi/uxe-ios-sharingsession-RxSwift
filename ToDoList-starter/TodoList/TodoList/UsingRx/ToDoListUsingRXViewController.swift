
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
    
    private var tableView = UITableView()
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
        navigationItem.title = "TodoList"
        
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
        
        tableView.delegate = self
        tableView.dataSource = self
        
        view.addSubview(tableView)
    }
    
    ///MARK: Rx Setup
    private func setupTableUsingRx() {
        
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
            
            if let newText = textField?.text, newText.count > 0 {
                
            }
        }))

        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
}

extension TodolistUsingRXViewController: UITableViewDelegate {
    //right side action
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .normal, title: "") { _,_,_ in
            print(indexPath)
        }
        
        deleteAction.image = UIImage(imageLiteralResourceName: "delete")
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    //left side action
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .normal, title: "") { _,_,_ in
            print(indexPath)
        }
        
        deleteAction.image = UIImage(imageLiteralResourceName: "delete")
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

extension TodolistUsingRXViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ToDoCell.identifierCell, for: indexPath) as! ToDoCell
        
        return cell
    }
}

