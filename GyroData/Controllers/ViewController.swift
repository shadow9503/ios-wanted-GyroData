//
//  ViewController.swift
//  GyroExample
//
//  Created by KangMingyo on 2022/09/24.
//

import UIKit

class ViewController: UIViewController {
    
    let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .short
        f.locale = Locale(identifier: "ko_kr")
        f.dateFormat = "yyyy/MM/dd HH:mm:ss"
        return f
    }()
    
    lazy var navButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "측정", style: .plain, target: self, action: #selector(add))
        return button
    }()
    
    private var tableView: UITableView = {
        let tableView = UITableView()
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .systemBackground
        self.navigationItem.rightBarButtonItem = self.navButton
        title = "목록"
        configure()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DataManager.shared.fetchSave()
        tableView.reloadData()
    }
    
    @objc func add(_ sender: Any) {
        let secondView = MeasurmentViewController()     // 두번째 화면 푸시
        self.navigationController?.pushViewController(secondView, animated: true)
    }
    
    func configure() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableViewDelegate()
        tableView.register(TableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.rowHeight = 100
        tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
    }

    func tableViewDelegate() {
        tableView.delegate = self
        tableView.dataSource = self
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DataManager.shared.saveList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! TableViewCell
        let target = DataManager.shared.saveList[indexPath.row]
        cell.dateLabel.text = formatter.string(for: target.date)
        cell.nameLabel.text = target.name
        cell.timeLabel.text = String(format: "%.1f", target.time)

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let secondView = ReplayViewController()
        secondView.pageType = "View"
        secondView.data = DataManager.shared.saveList[indexPath.row]
        self.navigationController?.pushViewController(secondView, animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let actions1 = UIContextualAction(style: .normal, title: "Delete", handler: { action, view, completionHaldler in
            completionHaldler(true)
            
        })
        actions1.backgroundColor = .systemRed
    
        let actions2 = UIContextualAction(style: .normal, title: "Play", handler: { action, view, completionHaldler in
            completionHaldler(true)
            let secondView = ReplayViewController()
            secondView.pageType = "Play"
            secondView.data = DataManager.shared.saveList[indexPath.row]
            self.navigationController?.pushViewController(secondView, animated: true)
        })
        actions2.backgroundColor = .systemGreen
        return UISwipeActionsConfiguration(actions: [actions1, actions2])
    }


}