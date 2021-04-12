//
//  convert.swift
//  flutter_zebra_rfid
//
//  Created by Florent ROBIN on 02/04/2021.
//

import UIKit

class serializer: NSObject {
    static func tagData(_ tagData: srfidTagData) -> [String: Any] {
        return [
            "tagId" : tagData.getTagId() as Any,
            "firstSeenTime": tagData.getFirstSeenTime(),
            "lastSeenTime" : tagData.getLastSeenTime(),
            "pc" : tagData.getPC() as Any,
            "peakRSSI" : tagData.getPeakRSSI(),
            "channelIndex" : tagData.getChannelIndex(),
            "phaseInfo" : tagData.getPhaseInfo(),
            "seenCount" : tagData.getTagSeenCount(),
            "opCode" : (tagData.getOpCode() == nil ? nil : tagData.getOpCode().getOrdinal().rawValue) as Any,
            "operationSucceed" : tagData.getOperationSucceed(),
            "operationStatus" : tagData.getOperationStatus() as Any,
            "memoryBank" : tagData.getMemoryBank().rawValue,
            "memoryBankData" : tagData.getMemoryBankData() as Any,
            "permaLockData" : tagData.getPermaLock() as Any,
            "modifiedWordCount" : tagData.getModifiedWordCount(),
            "g2v2Result" : tagData.getg2v2Result() as Any,
            "g2v2Response" : tagData.getg2v2Response() as Any
        ]
    }
}
