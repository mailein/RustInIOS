import Foundation
import pcdfcore

class EventStore: ObservableObject {
    @Published var events: [PCDFEvent] = []
    
    public static func dirURL() throws -> URL {
        try FileManager.default.url(for: .documentDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: false)
    }
    
    public static func fileURL(fileName: String) throws -> URL {
        try dirURL().appendingPathComponent(fileName)
    }
    
    static func load(fileURL: URL, completion: @escaping (Result<[PCDFEvent], Error>)-> Void) {
        do {
//            let fileURL = try fileURL(fileName: fileName)
//                let file = try? FileHandle(forReadingFrom: fileURL)
            var events = [PCDFEvent]()
            
            let fileRead = try? FileHandle(forReadingFrom: fileURL)
            let dataRead = try fileRead?.readToEnd()
            let contentStr = String(decoding: dataRead!, as: UTF8.self)
            print(contentStr)
//            let contentStr = try String(contentsOf: fileURL, encoding: String.Encoding.utf8)
            try fileRead?.close()
            
            let texts = contentStr.split(separator: "\n")
            for text in texts {
                let event = PCDFEvent.Companion().fromString(string: String(text))//TODO: check gps event
                events.append(event)
            }
            
            completion(.success(events))
        } catch {
            completion(.failure(error))
        }
    }
    
    static func save(to fileName: String, events: [PCDFEvent], completion: @escaping (Result<Int, Error>)->Void) {
        let serializer = Serializer()
        do {
            let outfile = try fileURL(fileName: fileName)
            //create the file before write to it，otherwise the file is nil
            //TODO: app id
            var data = serializer.generateFromPattern(pattern: MetaEvent(source: "app id",
                                                                         timestamp: Int64(Date().timeIntervalSinceReferenceDate),//TODO
                                                                         pcdf_type: "PERSISTENT",
                                                                         ppcdf_version: "1.0.0",
                                                                         ipcdf_version: nil).getPattern()) + "\n"
            try data.write(to: outfile, atomically: true, encoding: .utf8)
            
            let file = try? FileHandle(forUpdating: outfile)
            
            for event in events {
                if let event = event as? OBDEvent {
                    //TODO: construct the pattern with all info available now in the event
                    data = serializer.generateFromPattern(pattern: OBDEvent(source: event.source,//TODO: background thread write string
                                                                            timestamp: event.timestamp,
                                                                            bytes: event.bytes).getPattern()) + "\n"
                } else {
                    data = serializer.generateFromPattern(pattern: event.getPattern()) + "\n"
                }
                try file?.seekToEnd()
                try file?.write(contentsOf: data.data(using: .utf8)!)
            }
            
            try file?.close()
            
            //debug
//            let fileRead = try? FileHandle(forReadingFrom: outfile)
//            let dataRead = try fileRead?.readToEnd()
//            print(String(decoding: dataRead!, as: UTF8.self))
//            try fileRead?.close()
            
            completion(.success(events.count))
        }catch{
            completion(.failure(error))
        }
    }
}