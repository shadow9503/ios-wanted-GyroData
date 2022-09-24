//
//  ListViewController.swift
//  GyroData
//
//  Created by 유영훈 on 2022/09/20.
//

import UIKit
import CoreData
import CoreMotion

class ListViewController: UIViewController {
    
    private var tableView: UITableView = {
        let tableView = UITableView()
        return tableView
    }()
    var runDataList = [RunDataList]()
    
    lazy var list: [NSManagedObject] = {
        return self.fetch()
    }()
    var container: NSPersistentContainer! //core

//    var coreList = [Run]()
    var editTarget: NSManagedObject?
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        layout()
        addNaviBar()
        addSetuo()
        fetch()
        list = fetch()  // core
        save()
        fetchRun()
    }
    
    
    //코어 데이터
        func fetchRun() {
            let appDelegata = UIApplication.shared.delegate as! AppDelegate  //앱델리게이트 객체 참조
            //        self.container = appDelegata.persistentContainer  //core  관리 객체 켄텍스트 참조
            let context = appDelegata.persistentContainer.viewContext
            do {
                let contact = try context.fetch(Run.fetchRequest()) as! [Run]
                contact.forEach {
                    print($0.timestamp)
                }
            } catch {
                print(error.localizedDescription)
            }
            let hemg = RunDataList(timestamp: "57번오늘", gyro: "57번현중", interval: 5.7)
            let runkEntity = NSEntityDescription.entity(forEntityName: "Run", in: context)
            if let entity = runkEntity {
                let managedObject = NSManagedObject(entity: entity, insertInto: context)
                managedObject.setValue(hemg.interval, forKey: "interval")
                managedObject.setValue(hemg.timestamp, forKey: "timestamp")
                managedObject.setValue(hemg.gyro, forKey: "gyro")
                do {
                    try context.save()
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    
    
    
    
    
    func save() {
        print("save 클릭")
        let person = RunDataList(timestamp: "77번timetest", gyro: "77번gyrotest", interval: 7.8)
        DataManager.shared.saveToContext()
    }
    
    
    
    func addSetuo() {
        runDataList.append(.init(timestamp: "time", gyro: "gyro", interval: 1.1))
    }
    
    func fetch() -> [NSManagedObject] {
        let context = DataManager.shared.context
        var lists = [NSManagedObject]()
        context.performAndWait {
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Run")  //요청 객체 생성
            let sort = NSSortDescriptor(key: "gyro", ascending: true)
            fetchRequest.sortDescriptors = [sort]
            fetchRequest.fetchLimit = 100
            do {
                lists = try context.fetch(fetchRequest)
            } catch {
                fatalError(error.localizedDescription)
            }
        }
        return lists
    }
  
    
    func layout() {  //테이블뷰
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(CustomCell.self, forCellReuseIdentifier: "cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
    }
    
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        //스왑 버튼
        let actions1 = UIContextualAction(style: .normal, title: "Delete", handler: { action, view, completionHaldler in
            completionHaldler(true)
//            DataManager.shared.deleteAllRun()
            print("삭제")
        })
        actions1.backgroundColor = .systemRed
       //딜리트 구현?
        //딜리트올 아니고 딜리트사용
        
        //스왑버튼
        let actions2 = UIContextualAction(style: .normal, title: "Play", handler: { action, view, completionHaldler in
            completionHaldler(true)
            let secondView = ReplayViewController()   
            self.navigationController?.pushViewController(secondView, animated: true)
            print("시작")
        })
        actions2.backgroundColor = .systemGreen
        return UISwipeActionsConfiguration(actions: [actions1, actions2])
    }
    
    private func addNaviBar() {
        title = "목록"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "측정", style: .plain, target: self, action: #selector(add))
        
        //core kx
//        let newEntity = NSEntityDescription.insertNewObject(forEntityName: "Run", into: context)
    }
    @objc func add(_ sender: Any) {
        let secondView = MeasurmentViewController()     // 3번째 화면 푸시
        self.navigationController?.pushViewController(secondView, animated: true)
    }
    
 
}

extension ListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return runDataList.count  //더미
        
//        return coreList.count //core
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! CustomCell
        let list = runDataList[indexPath.row] //더미
        cell.setModel(model: list) //더미
        
//        let recore = coreList[indexPath.row]  // core
//        cell.leftLabel.text = recore.value(forKey: "timestamp") as? String  //core
//        cell.centerLabel.text = recore.value(forKey: "gyro") as? String    //core
//        cell.rightLabel.text = "\(recore.value(forKey: "interval") as? Float)" //core
        return cell
        
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let replayViewController = ReplayViewController()
        self.navigationController?.pushViewController(replayViewController, animated: true)
  
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return view.frame.height / 10
    }
}
