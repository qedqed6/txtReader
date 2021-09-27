//
//  ReaderManger.swift
//  txtReader
//
//  Created by peter on 2021/9/26.
//

import Foundation

typealias GetUserPutFilesCompletionClosure = (_ bookModel: [BookModel]?, _ systemSetting: SystemSettingModel) -> Void
typealias GetBookContentCompletionClosure = ((bookModel: BookModel, bookContentModel: BookContentModel)?) -> Void

@objc protocol ReaderMangerDelegate: AnyObject {
    @objc optional func systemSettingDidUpdate(_ setting: Any)
}

class ReaderManger {
    static let share = ReaderManger()
    static let systemSettingUpdateNotificationName = Notification.Name("systemSettingUpdate")
    static let systemSettingUserInfoKey = "setting"
    
    private let queue: DispatchQueue = DispatchQueue(label: "com.qedqed6.readerqueue")
    private let systemSettingFileName = "setting.txt"
    
    private let fileManger: FileManager
    private let userPutFilesURL: URL
    private let appStoreBaseURL: URL
    private let appStoreSystemSettingModlesURL: URL
    private let appStoreBookModelsURL: URL
    private let appStoreBookContentModelsURL: URL
    
    private var systemSetting: SystemSettingModel = SystemSettingModel()
    private var bookModels: [BookModel] = []
    
    var delegate: [ReaderMangerDelegate?] = []
    
    private init() {
        fileManger = FileManager.default
        userPutFilesURL = fileManger.documentDirectoryURL!
        appStoreBaseURL = userPutFilesURL.appendingPathComponent("data", isDirectory: true)
        appStoreSystemSettingModlesURL = appStoreBaseURL.appendingPathComponent("SystemSetting", isDirectory: true)
        appStoreBookModelsURL = appStoreBaseURL.appendingPathComponent("Book", isDirectory: true)
        appStoreBookContentModelsURL = appStoreBaseURL.appendingPathComponent("BookContent", isDirectory: true)

        print("userPutFilesURL: \(userPutFilesURL)")
//        print("appStoreBaseURL: \(appStoreBaseURL)")
//        print("appStoreSystemSettingModlesURL: \(appStoreSystemSettingModlesURL)")
//        print("appStoreBookModelsURL: \(appStoreBookModelsURL)")
//        print("appStoreBookContentModelsURL: \(appStoreBookContentModelsURL)")
        
        self.checkFolders()
    }
    
    func addDelegate() {
        
    }
    
    func getUserPutFiles(completionHanlder: GetUserPutFilesCompletionClosure?) {
        queue.async {
            self.scan()
            completionHanlder?(self.bookModels, self.systemSetting)
        }
    }
    
    func getBookContent(name: String, completionHanlder: GetBookContentCompletionClosure?) {
        queue.async {
            guard var bookModel = (self.bookModels.first { $0.name == name }) else {
                completionHanlder?(nil)
                return
            }

            if let bookContentModel = self.getBookContentModel(name: name) {
                completionHanlder?((bookModel, bookContentModel))
                return
            }
            
            guard let bookContentModel = self.createBookContentModelFile(name: name) else {
                completionHanlder?(nil)
                return
            }
            
            bookModel = self.updateBookModelFile(name: name, totalRows: bookContentModel.content.count)
            completionHanlder?((bookModel, bookContentModel))
        }
    }
    
    func retrieveBookModel(name: String) -> BookModel? {
        var bookModel: BookModel? = nil
        
        queue.sync {
            bookModel = self.bookModels.first { $0.name == name }
        }
        
        return bookModel
    }
    
    func updateBookModel(bookModel: BookModel) {
        queue.sync {
            self.updateBookModelFile(bookModel: bookModel)
        }
    }
    
    func getSystemSetting() -> SystemSettingModel {
        var result = SystemSettingModel()
        
        queue.sync {
            result = self.systemSetting
        }
        
        return result
    }
    
    func updateSystemSetting(systemSetting: SystemSettingModel) {
        queue.async {
            self.systemSetting = systemSetting
            self.saveSyetemSettingModel(syetemSettingModel: systemSetting)
            NotificationCenter.default.post(name: Self.systemSettingUpdateNotificationName, object: nil, userInfo: [Self.systemSettingUserInfoKey: systemSetting])
        }
    }
}

extension ReaderManger {
    private func scan() {
        systemSetting = scanSystemSetting()
        bookModels = scanBookModels()
        scanBookContentModels()
    }
    
    /**
     Check basic folder that app ask it exist.
     If one of each folder doesn't exist, create it.
     Documents/
     Documents/data/
     Documents/data/SystemSetting/
     Documents/data/Book/
     */
    private func checkFolders() {
        do {
            if fileManger.fileNotExists(atPath: appStoreBaseURL.path) {
                try fileManger.createDirectory(at: appStoreBaseURL, withIntermediateDirectories: false, attributes: nil)
            }
            
            if fileManger.fileNotExists(atPath: appStoreSystemSettingModlesURL.path) {
                try fileManger.createDirectory(at: appStoreSystemSettingModlesURL, withIntermediateDirectories: false, attributes: nil)
            }
            
            if fileManger.fileNotExists(atPath: appStoreBookModelsURL.path) {
                try fileManger.createDirectory(at: appStoreBookModelsURL, withIntermediateDirectories: false, attributes: nil)
            }
            
            if fileManger.fileNotExists(atPath: appStoreBookContentModelsURL.path) {
                try fileManger.createDirectory(at: appStoreBookContentModelsURL, withIntermediateDirectories: false, attributes: nil)
            }

        } catch {
            fatalError(error.localizedDescription)
        }
    }
}

/**
 Reader logic of SyetemSettingModel
 */
extension ReaderManger {
    /**
     Scan ststem setting folder, if file doesn't exist, create one.
     */
    private func scanSystemSetting() -> SystemSettingModel {
        if let setting = getSyetemSettingModel() {
            return setting
        }
        
        return createDefaultSyetemSettingModel()
    }
}

/**
 Reader logic of BookContentModel
 */
extension ReaderManger {
    private func scanBookContentModels() {
        removeMismatchBookContentModelsFile()
    }
    
    /**
     Scan user put files folder, if file doesn't exist anymore, delete corresponding BookModels.
     */
    private func removeMismatchBookContentModelsFile() {
        let userPutFilesListURL = fileManger.documentItemURL(userPutFilesURL, isFile: true)
        let appStoreBookContentModelsListURL = fileManger.documentItemURL(appStoreBookContentModelsURL, isFile: true)
        
        let userPutFileNameList = userPutFilesListURL.map { $0.lastPathComponent }
        let appStoreBookContentModelsNameList = appStoreBookContentModelsListURL.map { $0.lastPathComponent }
        
        let willDeleteBookContentModelsNameList = Array(Set(appStoreBookContentModelsNameList).subtracting(Set(userPutFileNameList)))

        fileManger.removeAll(baseURL: appStoreBookContentModelsURL, name: willDeleteBookContentModelsNameList)
    }
    
    private func createBookContentModelFile(name: String) -> BookContentModel? {
        let userPutFilesListURL = fileManger.documentItemURL(userPutFilesURL, isFile: true)

        guard let fileURL = (userPutFilesListURL.first {
            $0.lastPathComponent == name
        }) else {
            return nil
        }
        
        guard let fileData = try? Data(contentsOf: fileURL) else {
            return nil
        }
        
        guard let fileContent = String.decoding(data: fileData) else {
            return nil
        }
        
        /* Split lines by detecting line break character. */
        let content = fileContent.split(omittingEmptySubsequences: false) {
            switch $0 {
            case Character("\n") :
                return true
            case Character("\r\n") :
                return true
            default :
                return false
            }
        }.map {
            String($0)
        }
        
        var chapter: [Int] = []
        
        if content.count > 1 {
            try? content.enumerated().forEach { (index, lineText) in
                let pattern = ".*第.*[章回].*"
                let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
                let matchs = regex.matches(in: lineText, options: .reportProgress, range: NSRange(location: 0, length: lineText.count))
                
                if matchs.count > 0 {
                    chapter.append(index)
                }
            }
        }
        
        let bookContentModel = BookContentModel(name: name, content: content, chapter: chapter)
        saveBookContentModel(bookContentModel: bookContentModel)
        
        return bookContentModel
    }
}

/**
 Reader logic of BookModel
 */
extension ReaderManger {
    private func scanBookModels() -> [BookModel] {
        removeMismatchBookModelsFile()
        addNewBookModelsFile()
        
        let appStoreBookModelsListURL = fileManger.documentItemURL(appStoreBookModelsURL, isFile: true)
        let appStoreBookModelsNameList = appStoreBookModelsListURL.map { $0.lastPathComponent }
        var books: [BookModel] = []
        
        appStoreBookModelsNameList.forEach { name in
            guard let book = getBookModel(name: name) else {
                return
            }
            books.append(book)
        }
        
        return books
    }
    
    /**
     Scan user put files folder, if file doesn't exist anymore, delete corresponding BookModels.
     */
    private func removeMismatchBookModelsFile() {
        let userPutFilesListURL = fileManger.documentItemURL(userPutFilesURL, isFile: true)
        let appStoreBookModelsListURL = fileManger.documentItemURL(appStoreBookModelsURL, isFile: true)
        
        let userPutFileNameList = userPutFilesListURL.map { $0.lastPathComponent }
        let appStoreBookModelsNameList = appStoreBookModelsListURL.map { $0.lastPathComponent }
        
        let willDeleteBookModelsNameList = Array(Set(appStoreBookModelsNameList).subtracting(Set(userPutFileNameList)))

        fileManger.removeAll(baseURL: appStoreBookModelsURL, name: willDeleteBookModelsNameList)
    }
    
    /**
     Scan user put files folder, if file be add by user, add corresponding BookModels.
     */
    private func addNewBookModelsFile() {
        let userPutFilesListURL = fileManger.documentItemURL(userPutFilesURL, isFile: true)
        let appStoreBookModelsListURL = fileManger.documentItemURL(appStoreBookModelsURL, isFile: true)
        
        let userPutFileNameList = userPutFilesListURL.map { $0.lastPathComponent }
        let appStoreBookModelsNameList = appStoreBookModelsListURL.map { $0.lastPathComponent }
        
        let willAddBookModelsNameList = Array(Set(userPutFileNameList).subtracting(Set(appStoreBookModelsNameList)))
        
        willAddBookModelsNameList.forEach { createDefaultBookModel(name: $0) }
    }
    
    private func updateBookModelFile(name: String, totalRows: Int) -> BookModel  {
        if var bookModel = getBookModel(name: name) {
            bookModel.totalRows = totalRows
            saveBookModel(bookModel: bookModel)
            return bookModel
        }
        
        fatalError("\(#function), \(#line): BookModelFile \(name) should exist!")
    }
    
    private func updateBookModelFile(bookModel: BookModel) {
        if let _ = getBookModel(name: bookModel.name) {
            saveBookModel(bookModel: bookModel)
            return
        }
        
        fatalError("\(#function), \(#line): BookModelFile \(bookModel.name) should exist!")
    }
}

/**
 SyetemSettingModel basis operate
 */
extension ReaderManger {
    /**
     Get whole property of SyetemSettingModel from json file.
     */
    private func getSyetemSettingModel() -> SystemSettingModel? {
        let url = appStoreSystemSettingModlesURL.appendingPathComponent(systemSettingFileName)
        if fileManger.fileNotExists(atPath: url.path) {
            return nil
        }

        guard let data = try? Data(contentsOf: url) else {
            return nil
        }

        return try? JSONDecoder().decode(SystemSettingModel.self, from: data)
    }
    
    /**
     Create and save BookModel into json file, it had the name and with initial value property.
     */
    private func createDefaultSyetemSettingModel() -> SystemSettingModel {
        let setting = SystemSettingModel()
        
        self.saveSyetemSettingModel(syetemSettingModel: setting)
        
        return setting
    }
    
    /**
     Save whole property of SyetemSettingModel into json file.
     */
    private func saveSyetemSettingModel(syetemSettingModel: SystemSettingModel) {
        let url = appStoreSystemSettingModlesURL.appendingPathComponent(systemSettingFileName)

        do {
            let data = try JSONEncoder().encode(syetemSettingModel)
            try data.write(to: url)
        } catch {
            print(error)
        }
    }
}

/**
 BookContentModel basis operate
 */
extension ReaderManger {
    /**
     Get whole property of BookContentModel from json file.
     */
    private func getBookContentModel(name: String) -> BookContentModel? {
        let url = appStoreBookContentModelsURL.appendingPathComponent(name)
        if fileManger.fileNotExists(atPath: url.path) {
            return nil
        }

        guard let data = try? Data(contentsOf: url) else {
            return nil
        }

        return try? JSONDecoder().decode(BookContentModel.self, from: data)
    }
    
    /**
     Save whole property of BookContentModel into json file.
     */
    private func saveBookContentModel(bookContentModel: BookContentModel) {
        let url = appStoreBookContentModelsURL.appendingPathComponent(bookContentModel.name)

        do {
            let data = try JSONEncoder().encode(bookContentModel)
            try data.write(to: url)
        } catch {
            print(error)
        }
    }
}

/**
 BookModel basis operate
 */
extension ReaderManger {
    /**
     Get whole property of BookModel from json file.
     */
    private func getBookModel(name: String) -> BookModel? {
        let url = appStoreBookModelsURL.appendingPathComponent(name)
        if fileManger.fileNotExists(atPath: url.path) {
            return nil
        }

        guard let data = try? Data(contentsOf: url) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(BookModel.self, from: data)
        } catch {
            print(error)
        }
        
        return nil
    }
    
    /**
     Create and save BookModel into json file, initial with name and date.
     */
    private func createDefaultBookModel(name: String) {
        saveBookModel(bookModel: BookModel(name: name))
    }
    
    /**
     Save whole property of BookModel into json file.
     */
    private func saveBookModel(bookModel: BookModel) {
        let url = appStoreBookModelsURL.appendingPathComponent(bookModel.name)

        do {
            let data = try JSONEncoder().encode(bookModel)
            try data.write(to: url)
        } catch {
            print(error)
        }
    }
}
