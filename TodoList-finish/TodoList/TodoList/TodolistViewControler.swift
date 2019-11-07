
import UIKit
import RxSwift
import RxCocoa

struct ToDoItem: Equatable, Hashable {
    let title: String
    let done: Bool = false
    
    static let dailyTask: [ToDoItem] = []
}


class TodolistViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var ongoing = [
        ToDoItem(title: "Kerjaan 1"), ToDoItem(title: "Kerjaan 2")
    ]
    
    var done = [
        ToDoItem(title: "Kerjaan 3"), ToDoItem(title: "Kerjaan 4")
    ]
    
    var tableView = UITableView()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
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
        
        let barButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapNextButton))
        navigationItem.rightBarButtonItem = barButton
        
        tableView = UITableView(frame: view.frame)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor.white
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell_todo")
        
        view.addSubview(tableView)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        label.text = section == 0 ? "Ongoing" : "Done"
        label.backgroundColor = UIColor.lightGray
        return label
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return ongoing.count
        }
        return done.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell_todo", for: indexPath)
//        let todolistTitle = self.todolist[indexPath.row].done == false ? self.todolist[indexPath.row].title : ""
        let todolistTitle = indexPath.section == 0 ? ongoing[indexPath.row].title : done[indexPath.row].title
        
        cell.textLabel?.text = todolistTitle
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && editingStyle == UITableViewCell.EditingStyle.delete {
            ongoing.remove(at: indexPath.row)
            tableView.reloadData()
        } else {
            done.remove(at: indexPath.row)
            tableView.reloadData()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            tableView.deselectRow(at: indexPath, animated: true)
            let index = indexPath.row
            done.append(ongoing[index])
            ongoing.remove(at: index)
        } else if indexPath.section == 1 {
            tableView.deselectRow(at: indexPath, animated: true)
            let index = indexPath.row
            ongoing.append(done[index])
            done.remove(at: index)
        }
        
        self.tableView.reloadData()
    }
    
    @objc func didTapNextButton () {
        let alert = UIAlertController(title: "Add Todo", message: "Enter a text", preferredStyle: .alert)
        
        //2. Add the text field. You can configure it however you need.
        alert.addTextField { (textField) in
            textField.placeholder = "Code Review"
        }
        
        // 3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields?[0] // Force unwrapping because we know it exists.
            self.ongoing.append(ToDoItem(title: textField!.text!))
            self.tableView.reloadData()
        }))
        
        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
}

//struct ToDoItem {
//    let title: String
//    let done: Bool
//}
