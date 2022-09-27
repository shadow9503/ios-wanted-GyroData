//
//  DataManager.swift
//  GyroExample
//
//  Created by KangMingyo on 2022/09/24.
//

import Foundation
import CoreData

class DataManager {
    //인스턴스를 저장할 타입프로퍼티 추가
    static let shared = DataManager()
    private init() {
    }
    //context사용
    var mainContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    //Sava를 저장할 배열 선언후 배열 초기화
    var saveList = [Save]()
    
    //데이터를 데이터베이스에서 읽어온다 패치리퀴스트를 만들어야한다
    func fetchSave() {
        let request: NSFetchRequest<Save> = Save.fetchRequest()
        request.fetchLimit = 10
        request.fetchOffset = saveList.count
        //날짜를 내림차순 sort
        let sortByDateDesc = NSSortDescriptor(key: "date", ascending: false)
        request.sortDescriptors = [sortByDateDesc]
        //데이터 호출
        do {
            saveList.append(contentsOf: try mainContext.fetch(request))
        } catch {
            print(error)
        }
    }
    //테이블뷰가 savaList배열에 저장되어 있는 sava를 표시하도록
    //부분Delete 구현
    func deleteRun(object: Save) -> Bool {
        self.mainContext.delete(object)
        self.saveMainContext()
        do {
            try mainContext.save()
            return true
        } catch {
            return false
        }
    }
    func saveMainContext() {
        mainContext.perform {
            if self.mainContext.hasChanges {
                do {
                    try self.mainContext.save()
                } catch {
                    print(error)
                }
            }
        }
        saveContext()
    }
    
    func addNewSave(_ name: String?, _ time: Float?, _ xData: [Float], yData: [Float], zData: [Float]) {
        //데이터베이스의 sav를 저장하는데필요한 비어있는 인스턴스생성
        let newSave = Save(context: mainContext)
        //값 입력
        newSave.name = name
        newSave.date = Date()//날짜
        newSave.time = time ?? 0.00
        newSave.xData = xData as NSObject
        newSave.yData = yData as NSObject
        newSave.zData = zData as NSObject
        saveList.insert(newSave, at: 0)
        saveContext()
    }
    
    func deleteReview(_ save: Save?) {
        if let save = save {
            mainContext.delete(save)
            saveContext()
        }
    }
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "GyroExample")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    //컨텍스트를 저장하는 메소드
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

