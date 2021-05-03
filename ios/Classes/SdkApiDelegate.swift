//
//  SdkApiDelegate.swift
//  flutter_zebra_rfid
//
//  Created by Florent ROBIN on 31/03/2021.
//

import UIKit
import Flutter

class SdkApiDelegate: NSObject, srfidISdkApiDelegate {
    let channel: FlutterMethodChannel
    let api: srfidISdkApi
    var availableReaders: Array<srfidReaderInfo>?
    var activeReaders: Array<srfidReaderInfo>?
    
    init(with channel: FlutterMethodChannel, api: srfidISdkApi) {
        self.channel = channel
        self.api = api
        
    }
    
    
    public func srfidEventReaderAppeared(_ availableReader: srfidReaderInfo!) {
        channel.invokeMethod("eventReaderAppeared", arguments: [
            "id" : "\(availableReader.getReaderID())",
            "name": availableReader.getReaderName()
        ])
    }
    
    public func srfidEventReaderDisappeared(_ readerID: Int32) {
        if let reader = self.availableReaders?.first(where: { $0.getReaderID() == readerID}) {
            channel.invokeMethod("eventReaderDisappeared", arguments: [
                "id" : "\(reader.getReaderID())",
                "name" : reader.getReaderName()!
            ])
        }
    }
    
    public func srfidEventCommunicationSessionEstablished(_ activeReader: srfidReaderInfo!) {
        if let reader = self.availableReaders?.first(where: { $0.getReaderID() == activeReader.getReaderID()}) {
            reader.setActive(true)
        }
        channel.invokeMethod("eventCommunicationSessionEstablished", arguments: [
            "id" : "\(activeReader.getReaderID())",
            "name": activeReader.getReaderName()
        ])
        let resp = self.api.srfidEstablishAsciiConnection(activeReader.getReaderID(), aPassword: nil)
        if resp == SRFID_RESULT_SUCCESS {
            channel.invokeMethod("eventCommunicationASCIIConnectionEstablished", arguments: [
                "id" : "\(activeReader.getReaderID())",
                "name": activeReader.getReaderName()
            ])
            self.api.srfidSetBeeperConfig(activeReader.getReaderID(), aBeeperConfig: SRFID_BEEPERCONFIG_QUIET, aStatusMessage: nil)
        }
    }
    
    public func srfidEventCommunicationSessionTerminated(_ readerID: Int32) {
        if let reader = self.availableReaders?.first(where: { $0.getReaderID() == readerID}) {
            reader.setActive(false)
            channel.invokeMethod("eventCommunicationSessionTerminated", arguments: [
                "id" : "\(reader.getReaderID())",
                "name" : reader.getReaderName()!
            ])
        }
    }
    
    public func srfidEventReadNotify(_ readerID: Int32, aTagData tagData: srfidTagData!) {
        if let reader = self.availableReaders?.first(where: { $0.getReaderID() == readerID}) {
            let args = [
            "reader": [
                "id" : "\(reader.getReaderID())",
                "name" : reader.getReaderName()!
            ],
            "tagData": serializer.tagData(tagData)
        ]
        channel.invokeMethod("eventReadNotify", arguments: args)
        }
    }
    
    public func srfidEventStatusNotify(_ readerID: Int32, aEvent event: SRFID_EVENT_STATUS, aNotification notificationData: Any!) {
        if let reader = self.availableReaders?.first(where: { $0.getReaderID() == readerID}) {
            var data: Any?
            switch event {
            case SRFID_EVENT_STATUS_OPERATION_END_SUMMARY:
                if let _data = notificationData as? srfidOperEndSummaryEvent {
                    data = [
                        "totalTags": _data.getTotalTags(),
                        "totalRounds": _data.getTotalRounds(),
                        "totalTimeUs": _data.getTotalTimeUs(),
                    ]
                }
                break
            case SRFID_EVENT_STATUS_DATABASE:
                if let _data = notificationData as? srfidDatabaseEvent {
                    data = [
                        "cause": _data.getCause() as Any,
                        "entriesUsed": _data.getEntriesUsed(),
                        "entriesRemaining": _data.getEntriesRemaining(),
                    ]
                }
                break
            case SRFID_EVENT_STATUS_TEMPERATURE:
                if let _data = notificationData as? srfidTemperatureEvent {
                    data = [
                        "cause": _data.getCause() as Any,
                        "radioPATemp": _data.getRadioPATemp(),
                        "STM32Temp": _data.getSTM32Temp(),
                    ]
                }
                break
            case SRFID_EVENT_STATUS_POWER:
                if let _data = notificationData as? srfidPowerEvent {
                    data = [
                        "cause": _data.getCause() as Any,
                        "power": _data.getPower(),
                        "voltage": _data.getVoltage(),
                        "current": _data.getCurrent(),
                    ]
                }
                break
            default:
                break
            }
            SwiftFlutterZebraRfidPlugin.channel.invokeMethod("eventStatusNotify", arguments: [
                "reader": [
                    "id" : "\(reader.getReaderID())",
                    "name" : reader.getReaderName()!
                ],
                "event": event.rawValue,
                "data": data
            ])
        }
    }
    
    public func srfidEventProximityNotify(_ readerID: Int32, aProximityPercent proximityPercent: Int32) {
        if let reader = self.availableReaders?.first(where: { $0.getReaderID() == readerID}) {
            reader.setActive(false)
            channel.invokeMethod("eventProximityNotify", arguments: [
                "reader": [
                    "id" : "\(reader.getReaderID())",
                    "name" : reader.getReaderName()!
                ],
                "proximityPercent": proximityPercent
            ])
        }
    }
    
    public func srfidEventTriggerNotify(_ readerID: Int32, aTriggerEvent triggerEvent: SRFID_TRIGGEREVENT) {
        if let reader = self.availableReaders?.first(where: { $0.getReaderID() == readerID}) {
            reader.setActive(false)
            channel.invokeMethod("eventTriggerNotify", arguments: [
                "reader": [
                    "id" : "\(reader.getReaderID())",
                    "name" : reader.getReaderName()!
                ],
                "event": triggerEvent.rawValue
            ])
        }
    }
    
    public func srfidEventBatteryNotity(_ readerID: Int32, aBatteryEvent batteryEvent: srfidBatteryEvent!) {
        if let reader = self.availableReaders?.first(where: { $0.getReaderID() == readerID}) {
            reader.setActive(false)
            channel.invokeMethod("eventBatteryNotify", arguments: [
                "reader": [
                    "id" : "\(reader.getReaderID())",
                    "name" : reader.getReaderName()!
                ],
                "cause": batteryEvent.getCause() as Any,
                "isCharging" : batteryEvent.getIsCharging(),
                "powerLevel" : batteryEvent.getPowerLevel()
            ])
        }
    }
    
}
