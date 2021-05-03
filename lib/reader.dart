part of flutter_zebra_rfid;

/// Represent a RFID reader
class Reader extends Object {

  /// The reader's identifier
  final String id;

  ///The reader's name
  String name;

  /// Indicates if the reader is active (connected)
  bool get isActive => _isActive;
  bool _isActive = false;

  final StreamController<TagData> _tagReadStreamController = StreamController<TagData>();
  Stream<TagData>? _tagReadingStream;
  Stream<TagData> get tagReadingStream {
    if (_tagReadingStream == null) {
      _tagReadingStream = _tagReadStreamController.stream.asBroadcastStream();
    }
    return _tagReadingStream!;
  }

  bool _isTriggerPressed = false;
  bool get isTriggerPressed => _isTriggerPressed;
  final StreamController<bool> _readerTriggerController = StreamController<bool>();
  Stream<bool>? _readerTriggerStream;
  Stream<bool> get readerTriggerStream {
    if (_readerTriggerStream == null) {
      _readerTriggerStream = _readerTriggerController.stream.asBroadcastStream();
    }
    return _readerTriggerStream!;
  }

  bool _isInventoring = false;
  bool get isInventoring => _isInventoring;
  final StreamController<bool> _readerInventoringController = StreamController<bool>();
  Stream<bool>? _readerInventoringStream;
  Stream<bool> get readerInventoringStream {
    if (_readerInventoringStream == null) {
      _readerInventoringStream = _readerInventoringController.stream.asBroadcastStream();
    }
    return _readerInventoringStream!;
  }

  bool _isLocating = false;
  bool get isLocating => _isLocating;
  final StreamController<int> _proximityController = StreamController<int>();
  Stream<int>? _proximityStream;
  Stream<int> get proximityStream {
    if (_proximityStream == null) {
      _proximityStream = _proximityController.stream.asBroadcastStream();
    }
    return _proximityStream!;
  }

  Reader({
    required this.id, 
    required this.name
  });

  void dispose() async { 
    await _tagReadStreamController.close();
  }

  Future<void> connect() async {
    if (isActive) {
      return;
    }
    await FlutterZebraRfid._channel.invokeMethod('connect', { "reader": this.id});
  }

  Future<String> startInventory({
    required MemoryBank memoryBank, 
    ReportConfig? reportConfig, 
    AccessConfig? accessConfig
  }) async {
    final Map result = await FlutterZebraRfid._channel.invokeMethod('startInventory', { 
      "reader": this.id, 
      "memoryBank": memoryBank.key, 
      "reportConfig": reportConfig == null ? null : {
        "includeFirstSeenTime": reportConfig.includeFirstSeenTime, 
        "includePhase": reportConfig.includePhase,
        "includePC": reportConfig.includePC,
        "includeRSSI": reportConfig.includeRSSI,
        "includeChannelIndex": reportConfig.includeChannelIndex,
        "includeLastSeenTime": reportConfig.includeLastSeenTime, 
        "includeTagSeenCount": reportConfig.includeTagSeenCount
      }, 
      "accessConfig": accessConfig == null ? null : {
        "doSelect": accessConfig.doSelect, 
        "power": accessConfig.power
      }
    });
    return result["status"];
  }

  Future<String> stopInventory() async {
    final Map result = await FlutterZebraRfid._channel.invokeMethod('stopInventory', { 
      "reader": this.id
    });
    return result["status"];
  }

  Future<String> startLocateTag(String tagEpcId) async {
    final Map result = await FlutterZebraRfid._channel.invokeMethod('startLocateTag', { 
      "reader": this.id, 
      "tagEpcId": tagEpcId
    });
    _isLocating = true;
    return result["status"];
  }

  Future<String> stopLocateTag() async {
    final Map result = await FlutterZebraRfid._channel.invokeMethod('stopLocateTag', { 
      "reader": this.id
    });
    _isLocating = false;
    return result["status"];
  }

  Future<TagData> readTag({
    required String tagId, 
    required MemoryBank memoryBank, 
    required int offset, 
    required int length, 
    int password = 0
  }) async {
    final result = await FlutterZebraRfid._channel.invokeMethod('readTag', { 
      "reader": this.id, 
      "tagId": tagId, 
      "memoryBank": memoryBank.key, 
      "offset": offset, 
      "length": length, 
      "password": password
    });
    final tagData = TagData.fromMap(result["tagData"]);
    return tagData;
  }

  Future<TagData> writeTag({
    required String tagId, 
    required MemoryBank memoryBank, 
    required int offset, 
    required Uint8List data, 
    int password = 0
  }) async {
    final result = await FlutterZebraRfid._channel.invokeMethod('writeTag', { 
      "reader": this.id, 
      "tagId": tagId, 
      "memoryBank": memoryBank.key, 
      "offset": offset, 
      "data": hex.encode(data.toList()), 
      "password": password
    });
    final tagData = TagData.fromMap(result["tagData"]);
    return tagData;
  }

  void _eventCommunicationSessionEstablished() {
    print("_eventCommunicationSessionEstablished: ${this.name}");
  }

  void _eventCommunicationSessionTerminated() {
    print("_eventCommunicationSessionTerminated: ${this.name}");
    _isActive = false;
  }

  void _eventCommunicationASCIIConnectionEstablished() {
    print("_eventCommunicationASCIIConnectionEstablished: ${this.name}");
    _isActive = true;
  }

  void _eventReadNotify(TagData tagData) {
    _tagReadStreamController.add(tagData);
  }

  void _eventStatusNotify(EventStatus event, {EventStatusData? data}) {
    print("eventStatusNotify: ${this.name} => $event => ${data?.toString()}");
    switch (event) {
      case EventStatus.operationStop:
        _isInventoring = false;
        _readerInventoringController.add(_isInventoring);
        break;

      case EventStatus.operationStart:
        _isInventoring = true;
        _readerInventoringController.add(_isInventoring);
        break;

      case EventStatus.operationBatchMode:
        _isInventoring = true;
        _readerInventoringController.add(_isInventoring);
        break;
      default:
        break;
    }
  }

  void _eventProximityNotify(int proximityPercent) {
    print("eventProximityNotify: ${this.name} => $proximityPercent");
    _proximityController.add(proximityPercent);
  }

  void _eventTriggerNotify(TriggerEvent event) {
    print("_eventTriggerNotify: ${this.name} => $event");
    _isTriggerPressed = (event == TriggerEvent.pressed);
    _readerTriggerController.add(_isTriggerPressed);
  }

  void _eventBatteryNotify(String cause, int powerLevel, bool isCharging) {
    print("_eventBatteryNotify: ${this.name} => cause=$cause, powerLevel=$powerLevel , isCharging=$isCharging");
  }
}