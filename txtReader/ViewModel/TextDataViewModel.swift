//
//  TextDataListViewModel.swift
//  txtReader
//
//  Created by peter on 2021/9/23.
//

import Foundation

let textDataViewModel = TextDataViewModel()

class TextDataViewModel {
    struct TextInformation {
        let name: String
        var row: Int
        var percent: Double
    }
    
    private var textStateModel: [TextStateModel] = []
 
    private let fileManger: FileManager
    private let fileStoreBaseURL: URL
    private let textDataEncodingStoreBaseURL: URL
    private let textDataStateModelBaseURL: URL
    private let queue: DispatchQueue
    
    init() {
        fileManger = FileManager.default
        fileStoreBaseURL = fileManger.documentDirectoryURL!
        textDataEncodingStoreBaseURL = fileStoreBaseURL.appendingPathComponent("cache", isDirectory: true)
        textDataStateModelBaseURL = fileStoreBaseURL.appendingPathComponent("state", isDirectory: true)
        
        do {
            if fileManger.fileNotExists(atPath: textDataEncodingStoreBaseURL.path) {
                try fileManger.createDirectory(at: textDataEncodingStoreBaseURL, withIntermediateDirectories: false, attributes: nil)
            }
            
            if fileManger.fileNotExists(atPath: textDataStateModelBaseURL.path) {
                try fileManger.createDirectory(at: textDataStateModelBaseURL, withIntermediateDirectories: false, attributes: nil)
            }
        } catch {
            fatalError(error.localizedDescription)
        }
        
        queue = DispatchQueue(label: "com.qedqed6.queue")
    }
    
    func getTextState(completionHanlder: (([TextInformation]) -> Void)?) {
        queue.async {
            self.removeMismatchFile()
            self.addNewTextStateModel()
            
            var textInformation: [TextInformation] = []
            
            self.textStateModel = self.getAllTextStateModel()
            self.textStateModel.forEach {
                var percent: Double = 0
                if $0.totalRows != 0 {
                    percent = Double($0.row * 100) / Double($0.totalRows)
                }

                textInformation.append(TextInformation(name: $0.name, row: $0.row, percent: percent))
            }
            
            completionHanlder?(textInformation)
        }
    }
    
    func saveRowState(name: String, row: Int, totalRow: Int, completionHanlder: ((Int?) -> Void)?) {
        queue.async {
            guard var state = (self.textStateModel.first { $0.name == name }) else {
                completionHanlder?(nil)
                return
            }
            state.row = row
            state.totalRows = totalRow
            
            print("save state: \(state)")
            self.saveTextStateModel(textStateModel: state)
            completionHanlder?(state.row)
        }
    }
    
    func getContent(name: String, completionHanlder: @escaping (_ content: [String]?, _ row: Int) -> Void) {
        queue.async {
            // Find name in list table
            guard let textStateModel = (self.textStateModel.first { $0.name == name }) else {
                completionHanlder(nil, 0)
                return
            }
            
            if let textDataEncodingModel = self.getTextDataEncodingModel(name: name) {
                completionHanlder(textDataEncodingModel.content, textStateModel.row)
                return
            }
            
            let fileURL = self.fileStoreBaseURL.appendingPathComponent(name)
            guard let fileData = try? Data(contentsOf: fileURL) else {
                completionHanlder(nil, 0)
                return
            }
            
            guard let textString = String.decoding(data: fileData) else {
                completionHanlder(nil, 0)
                return
            }
            
            let textStringSplit = textString.split(omittingEmptySubsequences: false) {
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
            
            let textDataEncodingModel = TextDataEncodingModel(name: name, content: textStringSplit)
            self.saveTextDataEncodingModel(textDataEncodingModel: textDataEncodingModel)
            
            completionHanlder(textStringSplit, textStateModel.row)
        }
    }
}

extension TextDataViewModel {
    private func getAllTextStateModel() -> [TextStateModel] {
        let stateURL = fileManger.documentItemURL(self.textDataStateModelBaseURL, isFile: true)
        let stateName = stateURL.map { $0.lastPathComponent }
        
        var textState: [TextStateModel] = []
        stateName.forEach {
            if let state = getTextStateModel(name: $0) {
                textState.append(state)
            }
        }
        
        return textState
    }
    
    private func addNewTextStateModel() {
        let fileURL = fileManger.documentItemURL(isFile: true)
        let stateURL = fileManger.documentItemURL(self.textDataStateModelBaseURL, isFile: true)
        
        let fileName = fileURL.map { $0.lastPathComponent }
        let stateName = stateURL.map { $0.lastPathComponent }
        
        let addStateName = Set(fileName).subtracting(Set(stateName)).sorted()
        addStateName.forEach {
            saveTextStateModel(textStateModel: TextStateModel(name: $0))
        }
    }
    
    private func removeMismatchFile() {
        let fileURL = fileManger.documentItemURL(isFile: true)
        let stateURL = fileManger.documentItemURL(self.textDataStateModelBaseURL, isFile: true)
        let encodingURL = fileManger.documentItemURL(self.textDataEncodingStoreBaseURL, isFile: true)
        
        let fileName = fileURL.map { $0.lastPathComponent }
        let stateName = stateURL.map { $0.lastPathComponent }
        let encodingName = encodingURL.map { $0.lastPathComponent }
        
        let deleteStateName = Set(stateName).subtracting(Set(fileName)).sorted()
        let deleteEncodingName = Set(encodingName).subtracting(Set(fileName)).sorted()
        
        fileManger.removeAll(baseURL: textDataStateModelBaseURL, name: Array(deleteStateName))
        fileManger.removeAll(baseURL: textDataEncodingStoreBaseURL, name: Array(deleteEncodingName))
    }
}

extension TextDataViewModel {
    func getTextStateModel(name: String) -> TextStateModel? {
        let url = textDataStateModelBaseURL.appendingPathComponent(name)
        if fileManger.fileNotExists(atPath: textDataEncodingStoreBaseURL.path) {
            return nil
        }
        
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        
        return try? JSONDecoder().decode(TextStateModel.self, from: data)
    }
    
    private func saveTextStateModel(textStateModel: TextStateModel) {
        let url = textDataStateModelBaseURL.appendingPathComponent(textStateModel.name)

        do {
            let data = try JSONEncoder().encode(textStateModel)
            try data.write(to: url)
        } catch {
            print(error)
        }
    }
}

extension TextDataViewModel {
    private func saveTextDataEncodingModel(textDataEncodingModel: TextDataEncodingModel) {
        let url = textDataEncodingStoreBaseURL.appendingPathComponent(textDataEncodingModel.name)
        
        guard let data = try? JSONEncoder().encode(textDataEncodingModel) else {
            return
        }
        try? data.write(to: url)
    }
    
    private func getTextDataEncodingModel(name: String) -> TextDataEncodingModel? {
        let url = textDataEncodingStoreBaseURL.appendingPathComponent(name)
        if fileManger.fileNotExists(atPath: textDataEncodingStoreBaseURL.path) {
            return nil
        }
        
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        
        return try? JSONDecoder().decode(TextDataEncodingModel.self, from: data)
    }
}
