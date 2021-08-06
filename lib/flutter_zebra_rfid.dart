
library flutter_zebra_rfid;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

export 'tagData.dart';
export 'eventStatus.dart';
export 'accessOperationCode.dart';
export 'memoryBank.dart';
export 'triggerEvent.dart';
export 'accessConfig.dart';
export 'reportConfig.dart';

import 'package:flutter/services.dart';
import 'package:flutter_zebra_rfid/accessConfig.dart';
import 'package:flutter_zebra_rfid/accessOperationCode.dart';
import 'package:flutter_zebra_rfid/eventStatus.dart';
import 'package:flutter_zebra_rfid/memoryBank.dart';
import 'package:flutter_zebra_rfid/reportConfig.dart';
import 'package:flutter_zebra_rfid/tagData.dart';
import 'package:convert/convert.dart';
import 'package:flutter_zebra_rfid/triggerEvent.dart';

part 'reader.dart';

class FlutterZebraRfid {
  static const MethodChannel _channel =
      const MethodChannel('flutter_zebra_rfid');

  static final FlutterZebraRfid _instance = FlutterZebraRfid._internal();
  FlutterZebraRfid._internal() {
    _channel.setMethodCallHandler((call) async {
      final args = call.arguments as Map;
      switch (call.method) {
        case "eventReaderAppeared":
          assert(args["name"] != null && args["name"] is String, "name argument is not defined or is not a String");
          assert(args["id"] != null && args["id"] is String, "id argument is not defined or is not a String");
          _eventReaderAppeared(Reader(id: args["id"], name: args["name"]));
          break;

        case "eventReaderDisappeared": 
          assert(args["name"] != null && args["name"] is String, "name argument is not defined or is not a String");
          assert(args["id"] != null && args["id"] is String, "id argument is not defined or is not a String");
          _eventReaderDisappeared(Reader(id: args["id"], name: args["name"]));
          break;

        case "eventCommunicationSessionEstablished":
          assert(args["name"] != null && args["name"] is String, "name argument is not defined or is not a String");
          assert(args["id"] != null && args["id"] is String, "id argument is not defined or is not a String");
          _getAvailableReaderInfo(args)._eventCommunicationSessionEstablished();
          break;

        case "eventCommunicationSessionTerminated":
          assert(args["name"] != null && args["name"] is String, "name argument is not defined or is not a String");
          assert(args["id"] != null && args["id"] is String, "id argument is not defined or is not a String");
          _getAvailableReaderInfo(args)._eventCommunicationSessionTerminated();
          break;

        case "eventReadNotify": 
          assert(args["reader"] != null && args["reader"] is Map, "reader argument is not defined or is not a Map");
          assert(args["tagData"] != null && args["tagData"] is Map, "tagData argument is not defined or is not a Map");
          if (args["tagData"]["tagId"] != null) {
            _getAvailableReaderInfo(args["reader"])._eventReadNotify(
              TagData.fromMap(args["tagData"])
            );
          }
          break;

        case "eventStatusNotify":
          assert(args["reader"] != null && args["reader"] is Map, "id argument is not defined or is not a Map");
          assert(args["event"] != null && args["event"] is num, "event argument is not defined or is not a num");
          final event = eventStatusFromKey(args["event"]);
          EventStatusData? data;
          switch (event) {
            case EventStatus.database:
              data = EventStatusDatabaseData(
                cause: args["data"]["cause"], 
                entriesUsed: args["data"]["entriesUsed"], 
                entriesRemaining: args["data"]["entriesRemaining"]
              );
              break;
            case EventStatus.operationEndSummary:
              data = EventStatusOperationEndSummaryData(
                totalTags: args["data"]["totalTags"], 
                totalRounds: args["data"]["totalRounds"], 
                totalTimeUs: args["data"]["totalTimeUs"]
              );
              break;
            case EventStatus.temperature:
              data = EventStatusTemperatureData(
                cause: args["data"]["cause"], 
                radioPATemp: args["data"]["radioPATemp"], 
                stm32Temp: args["data"]["stm32Temp"]
              );
              break;
            case EventStatus.power:
              data = EventStatusPowerData(
                cause: args["data"]["cause"], 
                power: args["data"]["power"], 
                voltage: args["data"]["voltage"], 
                current: args["data"]["current"]
              );
              break;
            default:
              break;
          }
          _getAvailableReaderInfo(args["reader"])._eventStatusNotify(
            event,
            data : data
          );
          break;

        case "eventProximityNotify": 
          assert(args["reader"] != null && args["reader"] is Map, "id argument is not defined or is not a Map");
          assert(args["proximityPercent"] != null && args["proximityPercent"] is num, "proximityPercent argument is not defined or is not a num");
          _getAvailableReaderInfo(args["reader"])._eventProximityNotify(args["proximityPercent"]);
          break;

        case "eventTriggerNotify":
          assert(args["reader"] != null && args["reader"] is Map, "id argument is not defined or is not a Map");
          assert(args["event"] != null && args["event"] is num, "event argument is not defined or is not a num");
          _getAvailableReaderInfo(args["reader"])._eventTriggerNotify(args["event"] == 1 ? TriggerEvent.released : TriggerEvent.pressed);
          break;

        case "eventBatteryNotify":
          assert(args["reader"] != null && args["reader"] is Map, "id argument is not defined or is not a Map");
          assert(args["cause"] != null && args["cause"] is String, "cause argument is not defined or is not a String");
          assert(args["isCharging"] != null && args["isCharging"] is bool, "isCharging argument is not defined or is not a bool");
          assert(args["powerLevel"] != null && args["powerLevel"] is int, "powerLevel argument is not defined or is not a int");
          _getAvailableReaderInfo(args["reader"])._eventBatteryNotify(
            args["cause"], 
            args["powerLevel"], 
            args["isCharging"]
          );
          break;

        case "eventCommunicationASCIIConnectionEstablished":
          assert(args["name"] != null && args["name"] is String, "name argument is not defined or is not a String");
          assert(args["id"] != null && args["id"] is String, "id argument is not defined or is not a String");
          _getAvailableReaderInfo(args)._eventCommunicationASCIIConnectionEstablished();
          break;
        default:
      }
    });
  }
  factory FlutterZebraRfid() => _instance;

  List<Reader> _readers = [];

  Reader _getAvailableReaderInfo(Map readerInfo) {
    final String id = readerInfo["id"];
    Reader reader = _readers.firstWhere((element) => element.id == id, orElse: () {
      final r =Reader(id: id, name: readerInfo["name"]);
      _readers.add(r);
      return r;
    });
    reader.name = readerInfo["name"];
    return reader;
  }

  Future<String> get sdkVersion async {
    final String version = await _channel.invokeMethod('getSdkVersion');
    return version;
  }

  Future<List<Reader>> fetchAvailableReaders() async {
    List<dynamic>? result = await _channel.invokeMethod('getActiveReaders');
    final activeReaderIds = result?.map<String>((e) => e["id"] as String).toList() ?? [];

    result = await _channel.invokeMethod('getAvailableReaders');
    if (result != null) {
      for (var readerInfo in result) {
        _getAvailableReaderInfo(readerInfo);
      }
    }

    for (var reader in _readers) {
      reader._isActive = activeReaderIds.contains(reader.id);
    }
    return _readers;
  }


  void _eventReaderAppeared(Reader readerInfo) {
    print("_eventReaderAppeared: ${readerInfo.name}");
  }

  void _eventReaderDisappeared(Reader readerInfo) {
    print("_eventReaderDisappeared: ${readerInfo.name}");
  }
}
