enum EventStatus {
  operationStart,
  operationStop,
  operationBatchMode,
  operationEndSummary,
  temperature,
  power,
  database,
  radioError
}

EventStatus eventStatusFromKey(int key) => EventStatus.values.firstWhere((element) => element.key == key);

extension EventStatusExtensions on EventStatus {
  int get key {
    switch (this) {
      case EventStatus.operationStart: return 0x00;
      case EventStatus.operationStop: return 0x01;
      case EventStatus.operationBatchMode: return 0x02;
      case EventStatus.operationEndSummary: return 0x03;
      case EventStatus.temperature: return 0x04;
      case EventStatus.power: return 0x05;
      case EventStatus.database: return 0x06;
      case EventStatus.radioError: return 0x07;
      default:
        throw Exception("Unkown status");
    }
  }
}

abstract class EventStatusData {

}

class EventStatusOperationEndSummaryData extends EventStatusData {
  final int totalTags;
  final int totalRounds;
  final int totalTimeUs;

  EventStatusOperationEndSummaryData({
    required this.totalTags, 
    required this.totalRounds, 
    required this.totalTimeUs
  });
}

class EventStatusDatabaseData extends EventStatusData {
  final String cause;
  final int entriesUsed;
  final int entriesRemaining;

  EventStatusDatabaseData({
    required this.cause, 
    required this.entriesUsed, 
    required this.entriesRemaining
  });
}

class EventStatusTemperatureData extends EventStatusData {
  final String cause;
  final int radioPATemp;
  final int stm32Temp;

  EventStatusTemperatureData({
    required this.cause, 
    required this.radioPATemp, 
    required this.stm32Temp
  });
}

class EventStatusPowerData extends EventStatusData {
  final String cause;
  final double power;
  final double voltage;
  final double current;

  EventStatusPowerData({
    required this.cause, 
    required this.power, 
    required this.voltage, 
    required this.current
  });
}