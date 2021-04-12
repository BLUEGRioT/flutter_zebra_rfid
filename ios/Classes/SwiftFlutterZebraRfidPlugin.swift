import Flutter
import UIKit

public class SwiftFlutterZebraRfidPlugin: NSObject, FlutterPlugin {
    
    static var channel: FlutterMethodChannel!
    public static func register(with registrar: FlutterPluginRegistrar) {
        channel = FlutterMethodChannel(name: "flutter_zebra_rfid", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterZebraRfidPlugin(with: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    let _api: srfidISdkApi = srfidSdkFactory.createRfidSdkApiInstance()!
    let apiDelegate: SdkApiDelegate
    
    init(with channel: FlutterMethodChannel) {
        self.apiDelegate = SdkApiDelegate(with: channel, api: _api)
        
        _api.srfidSetOperationalMode(Int32(SRFID_OPMODE_ALL))
        _api.srfidSubsribe(forEvents: Int32(SRFID_EVENT_READER_APPEARANCE) | Int32(SRFID_EVENT_READER_DISAPPEARANCE) | Int32(SRFID_EVENT_SESSION_ESTABLISHMENT) | Int32(SRFID_EVENT_SESSION_TERMINATION))
        _api.srfidSubsribe(forEvents: Int32(SRFID_EVENT_MASK_READ) | Int32(SRFID_EVENT_MASK_STATUS) | Int32(SRFID_EVENT_MASK_STATUS_OPERENDSUMMARY))
        _api.srfidSubsribe(forEvents: Int32(SRFID_EVENT_MASK_TEMPERATURE) | Int32(SRFID_EVENT_MASK_POWER) | Int32(SRFID_EVENT_MASK_DATABASE))
        _api.srfidSubsribe(forEvents: Int32(SRFID_EVENT_MASK_PROXIMITY) | Int32(SRFID_EVENT_MASK_TRIGGER) | Int32(SRFID_EVENT_MASK_BATTERY))
        _api.srfidEnableAvailableReadersDetection(true)
        _api.srfidEnableAutomaticSessionReestablishment(true)
        _api.srfidSetDelegate(self.apiDelegate)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getSdkVersion":
            result(_api.srfidGetSdkVersion())
            break
        
        case "getAvailableReaders":
            let devices: NSMutableArray = NSMutableArray()
            var _devices = devices
            apiDelegate.availableReaders = withUnsafeMutablePointer(to: &_devices) { ptr -> Array<srfidReaderInfo>? in
                let devicesPtr : AutoreleasingUnsafeMutablePointer<NSMutableArray?> = AutoreleasingUnsafeMutablePointer<NSMutableArray?>.init(ptr)
                let r = _api.srfidGetAvailableReadersList(devicesPtr)
                if r == SRFID_RESULT_SUCCESS {
                    return (devices.map({ obj in
                        obj as! srfidReaderInfo
                    }))
                }
                else {
                    result(FlutterError(code: "\(r.rawValue)", message: "Unable to get available readers", details: nil))
                }
                return nil
            }
            result(apiDelegate.availableReaders!.map({ (reader: srfidReaderInfo) -> [String : Any] in
                return [
                    "name" : reader.getReaderName()!,
                    "id" : "\(reader.getReaderID())"
                ]
            }))
            break
            
        case "getActiveReaders":
            let devices: NSMutableArray = NSMutableArray()
            var _devices = devices
            apiDelegate.availableReaders = withUnsafeMutablePointer(to: &_devices) { ptr -> Array<srfidReaderInfo>? in
                let devicesPtr : AutoreleasingUnsafeMutablePointer<NSMutableArray?> = AutoreleasingUnsafeMutablePointer<NSMutableArray?>.init(ptr)
                let r = _api.srfidGetActiveReadersList(devicesPtr)
                if r == SRFID_RESULT_SUCCESS {
                    return (devices.map({ obj in
                        obj as! srfidReaderInfo
                    }))
                }
                else {
                    result(FlutterError(code: "\(r.rawValue)", message: "Unable to get active readers", details: nil))
                }
                return nil
            }
            result(apiDelegate.availableReaders!.map({ (reader: srfidReaderInfo) -> [String : Any] in
                return [
                    "name" : reader.getReaderName()!,
                    "id" : "\(reader.getReaderID())"
                ]
            }))
            break
            
        case "connect":
            var resp = SRFID_RESULT_FAILURE
            if let args = call.arguments as? Dictionary<String, Any>, let reader = args["reader"] as? String, let readerId = Int32(reader) {
                resp = _api.srfidEstablishCommunicationSession(readerId)
                if resp == SRFID_RESULT_SUCCESS {
                    result(nil)
                    return
                }
            }
            
            result(FlutterError(code: "\(resp.rawValue)", message: "Unable to connect to the device", details: nil))
            break
            
        case "startInventory":
            var resp = SRFID_RESULT_FAILURE
            var statusMessage: NSString = ""
            if let args = call.arguments as? Dictionary<String, Any>, let reader = args["reader"] as? String, let readerId = Int32(reader),
                let memoryBank = args["memoryBank"] as? UInt32 {
                let reportConfig = srfidReportConfig()
                if let _reportConfig = args["reportConfig"] as? Dictionary<String, Bool> {
                    if let includeFirstSeenTime = _reportConfig["includeFirstSeenTime"] {
                        reportConfig.setIncFirstSeenTime(includeFirstSeenTime)
                    }
                    if let includePhase = _reportConfig["includePhase"] {
                        reportConfig.setIncPhase(includePhase)
                    }
                    if let includePC = _reportConfig["includePC"] {
                        reportConfig.setIncPC(includePC)
                    }
                    if let includeRSSI = _reportConfig["includeRSSI"] {
                        reportConfig.setIncRSSI(includeRSSI)
                    }
                    if let includeChannelIndex = _reportConfig["includeChannelIndex"] {
                        reportConfig.setIncChannelIndex(includeChannelIndex)
                    }
                    if let includeLastSeenTime = _reportConfig["includeLastSeenTime"] {
                        reportConfig.setIncLastSeenTime(includeLastSeenTime)
                    }
                    if let includeTagSeenCount = _reportConfig["includeTagSeenCount"] {
                        reportConfig.setIncTagSeenCount(includeTagSeenCount)
                    }
                }
                let accessConfig = srfidAccessConfig()
                if let _accessConfig = args["accessConfig"] as? Dictionary<String, Any> {
                    if let doSelect = _accessConfig["doSelect"] as? Bool {
                        accessConfig.setDoSelect(doSelect)
                    }
                    if let power = _accessConfig["power"] as? Int16 {
                        accessConfig.setPower(power)
                    }
                }
                let __statusMessage = NSString()
                var _statusMessage = __statusMessage
                statusMessage = withUnsafeMutablePointer(to: &_statusMessage) { (ptr) -> NSString in
                    let autoreleasePtr = AutoreleasingUnsafeMutablePointer<NSString?>(ptr)
                    let bank = SRFID_MEMORYBANK(memoryBank)
                    resp = _api.srfidStartInventory(readerId, aMemoryBank: bank, aReportConfig: reportConfig, aAccessConfig: accessConfig, aStatusMessage: autoreleasePtr)
                    return __statusMessage
                }
                if resp == SRFID_RESULT_SUCCESS {
                    result(["status": statusMessage])
                    return
                }
            }
            
            result(FlutterError(code: "\(resp.rawValue)", message: "Unable to start inventory", details: statusMessage))
            break
            
        case "stopInventory":
            var resp = SRFID_RESULT_FAILURE
            var statusMessage: NSString = ""
            if let args = call.arguments as? Dictionary<String, Any>, let reader = args["reader"] as? String, let readerId = Int32(reader) {
                
                let __statusMessage = NSString()
                var _statusMessage = __statusMessage
                statusMessage = withUnsafeMutablePointer(to: &_statusMessage) { (ptr) -> NSString in
                    let autoreleasePtr = AutoreleasingUnsafeMutablePointer<NSString?>(ptr)
                    resp = _api.srfidStopInventory(readerId, aStatusMessage: autoreleasePtr)
                    return __statusMessage
                }
                if resp == SRFID_RESULT_SUCCESS {
                    result(["status": statusMessage])
                    return
                }
            }
            
            result(FlutterError(code: "\(resp.rawValue)", message: "Unable to stop inventory", details: statusMessage))
            break
            
        case "readTag":
            var resp = SRFID_RESULT_FAILURE
            var statusMessage: NSString = ""
            if let args = call.arguments as? Dictionary<String, Any>,
               let reader = args["reader"] as? String, let readerId = Int32(reader),
               let tagId = args["tagId"] as? String,
               let memoryBank = args["memoryBank"] as? UInt32,
               let offset = args["offset"] as? Int16,
               let length = args["length"] as? Int16,
               let passsword = args["password"] as? Int {
                
                let bank = SRFID_MEMORYBANK(memoryBank)
                
                var tagData = srfidTagData()
                resp = withUnsafeMutablePointer(to: &tagData) {
                    let ptr = AutoreleasingUnsafeMutablePointer<srfidTagData?>($0)
                    return withUnsafeMutablePointer(to: &statusMessage) {
                        return _api.srfidReadTag(readerId, aTagID: tagId, aAccessTagData: ptr, aMemoryBank: bank, aOffset: offset, aLength: length, aPassword: passsword, aStatusMessage: AutoreleasingUnsafeMutablePointer<NSString?>($0))
                    }
                }
                if resp == SRFID_RESULT_SUCCESS {
                    result([
                        "status": statusMessage,
                        "tagData": serializer.tagData(tagData)
                    ])
                    return
                }
            }
            
            result(FlutterError(code: "\(resp.rawValue)", message: "Unable to read tag", details: statusMessage))
            break
            
        case "writeTag":
            var resp = SRFID_RESULT_FAILURE
            var statusMessage: NSString = ""
            if let args = call.arguments as? Dictionary<String, Any>,
               let reader = args["reader"] as? String, let readerId = Int32(reader),
               let tagId = args["tagId"] as? String,
               let memoryBank = args["memoryBank"] as? UInt32,
               let offset = args["offset"] as? Int16,
               let data = args["data"] as? String,
               let passsword = args["password"] as? Int {
                
                let bank = SRFID_MEMORYBANK(memoryBank)
                
                var tagData = srfidTagData()
                resp = withUnsafeMutablePointer(to: &tagData) {
                    let ptr = AutoreleasingUnsafeMutablePointer<srfidTagData?>($0)
                    return withUnsafeMutablePointer(to: &statusMessage) {
                        return _api.srfidWriteTag(readerId, aTagID: tagId, aAccessTagData: ptr, aMemoryBank: bank, aOffset: offset, aData: data, aPassword: passsword, aDoBlockWrite: false, aStatusMessage: AutoreleasingUnsafeMutablePointer<NSString?>($0))
                    }
                }
                if resp == SRFID_RESULT_SUCCESS {
                    if !tagData.getOperationSucceed() {
                        result(FlutterError(code: "\(resp.rawValue)", message: "Unable to write tag", details: tagData.getOperationStatus()))
                        return
                    }
                    result([
                        "status": statusMessage,
                        "tagData": serializer.tagData(tagData)
                    ])
                    return
                }
            }
            
            result(FlutterError(code: "\(resp.rawValue)", message: "Unable to write tag", details: statusMessage))
            break
            
        case "startLocateTag":
            var resp = SRFID_RESULT_FAILURE
            var statusMessage: NSString = ""
            if let args = call.arguments as? Dictionary<String, Any>,
               let reader = args["reader"] as? String, let readerId = Int32(reader),
               let tagEpcId = args["tagEpcId"] as? String {
                resp = withUnsafeMutablePointer(to: &statusMessage) {
                    return _api.srfidStartTagLocationing(readerId, aTagEpcId: tagEpcId, aStatusMessage: AutoreleasingUnsafeMutablePointer<NSString?>($0))
                }
                if resp == SRFID_RESULT_SUCCESS {
                    result([
                        "status": statusMessage
                    ])
                    return
                }
            }
            
            result(FlutterError(code: "\(resp.rawValue)", message: "Unable to start locating tag", details: statusMessage))
            break
            
        case "stopLocateTag":
            var resp = SRFID_RESULT_FAILURE
            var statusMessage: NSString = ""
            if let args = call.arguments as? Dictionary<String, Any>,
               let reader = args["reader"] as? String, let readerId = Int32(reader) {
                resp = withUnsafeMutablePointer(to: &statusMessage) {
                    return _api.srfidStopTagLocationing(readerId, aStatusMessage: AutoreleasingUnsafeMutablePointer<NSString?>($0))
                }
                if resp == SRFID_RESULT_SUCCESS {
                    result([
                        "status": statusMessage
                    ])
                    return
                }
            }
            
            result(FlutterError(code: "\(resp.rawValue)", message: "Unable to stop locating tag", details: statusMessage))
            break
        default:
            break
        }
    }
    
}
