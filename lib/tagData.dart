import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_zebra_rfid/accessOperationCode.dart';
import 'package:flutter_zebra_rfid/flutter_zebra_rfid.dart';
import 'package:convert/convert.dart';

// ignore: must_be_immutable
class TagData extends Equatable {
  /// The tags identifier
  final String tagId;
  final DateTime? firstSeenTime;
  final DateTime? lastSeenTime;
  final String? pc;
  final int? peakRSSI;
  final int? channelIndex;
  final int? phaseInfo;
  int? seenCount;
  final AccessOperationCode? opCode;
  final bool operationSucceed;
  final String operationStatus;
  final MemoryBank memoryBank;
  final Uint8List? memoryBankData;
  final Uint8List? permaLockData;
  final int modifiedWordCount;
  final String? g2v2Result;
  final String? g2v2Response;

  TagData({
    required this.tagId, 
    required this.firstSeenTime, 
    required this.lastSeenTime, 
    required this.pc, 
    required this.peakRSSI, 
    required this.channelIndex, 
    required this.phaseInfo, 
    required this.seenCount, 
    required this.opCode, 
    required this.operationSucceed, 
    required this.operationStatus, 
    required this.memoryBank, 
    required this.memoryBankData, 
    required this.permaLockData, 
    required this.modifiedWordCount, 
    required this.g2v2Result, 
    required this.g2v2Response
    });

  @override
  List<Object?> get props => [tagId];

  factory TagData.fromMap(Map map) {
    return TagData(
      tagId: map["tagId"], 
      firstSeenTime: DateTime.fromMillisecondsSinceEpoch((map["firstSeenTime"] as int) * 1000, isUtc: true), 
      lastSeenTime: DateTime.fromMillisecondsSinceEpoch((map["lastSeenTime"] as int) * 1000, isUtc: true), 
      pc: map["pc"], 
      peakRSSI: map["peakRSSI"], 
      channelIndex: map["channelIndex"], 
      phaseInfo: map["phaseInfo"], 
      seenCount: map["seenCount"], 
      opCode: map["opCode"] == null ? null : accessOperationCodeFromOrdial(map["opCode"]), 
      operationSucceed: map["operationSucceed"], 
      operationStatus: map["operationStatus"], 
      memoryBank: memoryBankFromKey(map["memoryBank"] ?? MemoryBank.all.key), 
      memoryBankData: Uint8List.fromList(hex.decode(map["memoryBankData"] ?? "")), 
      permaLockData: Uint8List.fromList(hex.decode(map["permaLockData"] ?? "")), 
      modifiedWordCount: map["modifiedWordCount"], 
      g2v2Result: map["g2v2Result"], 
      g2v2Response: map["g2v2Response"]
    );
  }
}