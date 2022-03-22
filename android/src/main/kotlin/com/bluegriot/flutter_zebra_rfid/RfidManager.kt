package com.bluegriot.flutter_zebra_rfid

import android.R
import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import com.zebra.rfid.api3.*
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch

class RfidManager(private var channel: MethodChannel, private var context: Context) : Readers.RFIDReaderEventHandler {

    private var readers: Readers? = null
    private var availableRFIDReaderList: ArrayList<ReaderDevice>? = null

    fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {
            "getSdkVersion" -> getSdkVersion(call, result)
            "getAvailableReaders" -> getAvailableReaders(result)
            "getActiveReaders" -> getActiveReaders(result)
            "connect" -> connect(call, result)
            "getIsConnected" -> getIsConnected(call, result)
            "startInventory" -> startInventory(call, result)
            "stopInventory" -> stopInventory(call, result)
            "readTag" -> readTag(call, result)
            "writeTag" -> writeTag(call, result)
            "startLocateTag" -> startLocateTag(call, result)
            "stopLocateTag" -> stopLocateTag(call, result)
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun stopLocateTag(call: MethodCall, result: MethodChannel.Result) {
        val readerId = call.argument<String>("reader") ?: run {
            result.error("INVALID_ARGUMENT", "Missing argument reader", null)
            return
        }
        val reader = availableRFIDReaderList!!.first { it.address ==  readerId }

        try {
            reader.rfidReader.Actions.TagLocationing.Stop()

            result.success(hashMapOf(
                    "status" to "OK"
            ))
        }
        catch (ex: Exception) {
            result.error("LOCATE_TAG_ERROR", ex.localizedMessage, null)
        }
    }

    private fun startLocateTag(call: MethodCall, result: MethodChannel.Result) {
        val readerId = call.argument<String>("reader") ?: run {
            result.error("INVALID_ARGUMENT", "Missing argument reader", null)
            return
        }
        val reader = availableRFIDReaderList!!.first { it.address ==  readerId }

        val tagEpcId = call.argument<String>("tagEpcId") ?: run {
            result.error("INVALID_ARGUMENT", "Missing argument tagEpcId", null)
            return
        }

        try {
            reader.rfidReader.Actions.TagLocationing.Perform(tagEpcId, null, null)

            result.success(hashMapOf(
                    "status" to "OK"
            ))
        }
        catch (ex: Exception) {
            result.error("LOCATE_TAG_ERROR", ex.localizedMessage, null)
        }
    }

    private fun writeTag(call: MethodCall, result: MethodChannel.Result) {
        val readerId = call.argument<String>("reader") ?: run {
            result.error("INVALID_ARGUMENT", "Missing argument reader", null)
            return
        }
        val reader = availableRFIDReaderList!!.first { it.address ==  readerId }

        val tagId = call.argument<String>("tagId") ?: run {
            result.error("INVALID_ARGUMENT", "Missing argument tagId", null)
            return
        }
        val memoryBank = call.argument<Int>("memoryBank") ?: run {
            result.error("INVALID_ARGUMENT", "Missing argument memoryBank", null)
            return
        }
        val password = call.argument<Int>("password") ?: run {
            result.error("INVALID_ARGUMENT", "Missing argument password", null)
            return
        }
        val offset = call.argument<Int>("offset") ?: run {
            result.error("INVALID_ARGUMENT", "Missing argument offset", null)
            return
        }
        val dataHex = call.argument<String>("data") ?: run {
            result.error("INVALID_ARGUMENT", "Missing argument data", null)
            return
        }

        val maxRetries = call.argument<Int>("maxRetries") ?: 10

        GlobalScope.launch {
            try {
                val tagAccess = TagAccess()
                val writeAccessParams = tagAccess.WriteAccessParams()
                writeAccessParams.accessPassword = password.toLong()
                writeAccessParams.writeDataLength = dataHex.length / 4
                writeAccessParams.memoryBank = parseMemoryBank(memoryBank)
                writeAccessParams.byteOffset = offset * 2 // the parameter is in words
                writeAccessParams.setWriteData(dataHex)
                var tagData = TagData()
                _writeTag(maxRetries, reader.rfidReader, tagId, writeAccessParams, tagData)
                Handler(Looper.getMainLooper()).post {
                    result.success(hashMapOf(
                            "status" to "OK",
                            "tagData" to serializeTagData(tagData, parseMemoryBank(memoryBank))
                    ))
                }
            } catch (ex: InvalidUsageException) {
                Handler(Looper.getMainLooper()).post {
                    result.error("WRITE_TAG_ERROR", ex.info, null)
                }
            } catch (ex: OperationFailureException) {
                Handler(Looper.getMainLooper()).post {
                    result.error("WRITE_TAG_ERROR", ex.vendorMessage, null)
                }
            }
        }
    }

    private fun _writeTag(remainingTries: Int, reader: RFIDReader, tagId: String, writeAccessParams: TagAccess.WriteAccessParams, tagData: TagData) {
        try {
            reader.Actions.TagAccess.writeWait(tagId, writeAccessParams, null, tagData)
        }
        catch (ex: Exception) {
            if (remainingTries <= 0) {
                throw ex
            }
            _writeTag(remainingTries - 1, reader, tagId, writeAccessParams, tagData)
        }
    }

    private var isReading = false
    private fun readTag(call: MethodCall, result: MethodChannel.Result) {
        val readerId = call.argument<String>("reader") ?: run {
            result.error("INVALID_ARGUMENT", "Missing argument reader", null)
            return
        }
        val reader = availableRFIDReaderList!!.first { it.address ==  readerId }

        val tagId = call.argument<String>("tagId") ?: run {
            result.error("INVALID_ARGUMENT", "Missing argument tagId", null)
            return
        }
        val memoryBank = call.argument<Int>("memoryBank") ?: run {
            result.error("INVALID_ARGUMENT", "Missing argument memoryBank", null)
            return
        }
        val password = call.argument<Int>("password") ?: run {
            result.error("INVALID_ARGUMENT", "Missing argument password", null)
            return
        }
        val offset = call.argument<Int>("offset") ?: run {
            result.error("INVALID_ARGUMENT", "Missing argument offset", null)
            return
        }
        val length = call.argument<Int>("length") ?: run {
            result.error("INVALID_ARGUMENT", "Missing argument length", null)
            return
        }

        val maxRetries = call.argument<Int>("maxRetries") ?: 4

        if (isReading) {
            result.error("INVALID_STATE", "The device already is reading", null)
            return
        }

        isReading = true

        GlobalScope.launch {
            try {
                val tagAccess = TagAccess()
                val readAccessParams = tagAccess.ReadAccessParams()
                readAccessParams.accessPassword = password.toLong()
                readAccessParams.byteCount = length * 2 // the parameter is in words
                readAccessParams.memoryBank = parseMemoryBank(memoryBank)
                readAccessParams.byteOffset = offset * 2 // the parameter is in words

                val readAccessTag = _readTag(maxRetries, reader.rfidReader, tagId, readAccessParams)
                Handler(Looper.getMainLooper()).post {
                    result.success(hashMapOf(
                            "status" to "OK",
                            "tagData" to serializeTagData(readAccessTag, parseMemoryBank(memoryBank))
                    ))
                }
                isReading = false
            } catch (ex: InvalidUsageException) {
                isReading = false
                Handler(Looper.getMainLooper()).post {
                    result.error("READ_TAG_ERROR", ex.info, null)
                }
            } catch (ex: OperationFailureException) {
                isReading = false
                Handler(Looper.getMainLooper()).post {
                    result.error("READ_TAG_ERROR", ex.vendorMessage, null)
                }
            }
        }
    }

    private fun _readTag(remainingTries: Int, reader: RFIDReader, tagId: String, readAccessParams: TagAccess.ReadAccessParams) : TagData {
        try {
            return reader.Actions.TagAccess.readWait(tagId, readAccessParams, null)
        }
        catch (ex: Exception) {
            if (remainingTries <= 0) {
                throw ex
            }
            return _readTag(remainingTries - 1, reader, tagId, readAccessParams)
        }
    }

    private fun stopInventory(call: MethodCall, result: MethodChannel.Result) {
        val readerId = call.argument<String>("reader") ?: run {
            result.error("INVALID_ARGUMENT", "Missing argument reader", null)
            return
        }
        val reader = availableRFIDReaderList!!.first { it.address ==  readerId }

        try {
            reader.rfidReader.Actions.Inventory.stop()
            result.success(hashMapOf(
                    "status" to "OK"
            ))
        }
        catch (ex: InvalidUsageException) {
            result.error("INVENTORY_ERROR", ex.info, null)
        }
        catch (ex: OperationFailureException) {
            result.error("INVENTORY_ERROR", ex.vendorMessage, null)
        }
    }

    private fun startInventory(call: MethodCall, result: MethodChannel.Result) {
        val readerId = call.argument<String>("reader") ?: run {
            result.error("INVALID_ARGUMENT", "Missing argument reader", null)
            return
        }
        val memoryBank = call.argument<Int>("memoryBank") ?: run {
            result.error("INVALID_ARGUMENT", "Missing argument memoryBank", null)
            return
        }
        val reader = availableRFIDReaderList!!.first { it.address ==  readerId }
        val tagStorageSettings = TagStorageSettings(500, 2048, 18, TAG_FIELD.TAG_SEEN_COUNT, true)
        val fields = ArrayList<TAG_FIELD>()
        call.argument<HashMap<String, Boolean>>("reportConfig")?.let { rc ->
            rc["includeFirstSeenTime"]?.let {
                if (it) fields.add(TAG_FIELD.FIRST_SEEN_TIME_STAMP)
            }
            rc["includePhase"]?.let {
                if (it) fields.add(TAG_FIELD.PHASE_INFO)
            }
            rc["includePC"]?.let {
                if (it) fields.add(TAG_FIELD.PC)
            }
            rc["includeRSSI"]?.let {
                if (it) fields.add(TAG_FIELD.PEAK_RSSI)
            }
            rc["includeChannelIndex"]?.let {
                if (it) fields.add(TAG_FIELD.CHANNEL_INDEX)
            }
            rc["includeLastSeenTime"]?.let {
                if (it) fields.add(TAG_FIELD.LAST_SEEN_TIME_STAMP)
            }
            rc["includeTagSeenCount"]?.let {
                if (it) fields.add(TAG_FIELD.TAG_SEEN_COUNT)
            }
        }
        tagStorageSettings.tagFields = fields.toTypedArray()

        if (!reader.rfidReader.isConnected) {
            result.error("INVENTORY_ERROR", "The reader is not connected", null)
            return
        }

        if (reader.rfidReader.Config == null) {
            configureReader(reader)
        }

        reader.rfidReader.Config.tagStorageSettings = tagStorageSettings

        try {
            val tagAccess = TagAccess()
            val readAccessParams = tagAccess.ReadAccessParams()
            readAccessParams.count = 0
            readAccessParams.offset = 0
            readAccessParams.memoryBank = parseMemoryBank(memoryBank)
            reader.rfidReader.Actions.TagAccess.readEvent(readAccessParams, null, null)
            result.success(hashMapOf(
                    "status" to "OK"
            ))
        }
        catch (ex: InvalidUsageException) {
            result.error("INVENTORY_ERROR", ex.info, null)
        }
        catch (ex: OperationFailureException) {
            result.error("INVENTORY_ERROR", ex.vendorMessage, null)
        }
    }

    private fun getIsConnected(call: MethodCall, result: MethodChannel.Result) {
        val readerId = call.argument<String>("reader") ?: run {
            result.error("INVALID_ARGUMENT", "Missing argument reader", null)
            return
        }

        GlobalScope.launch {
            try {
                val reader = availableRFIDReaderList!!.first { it.address == readerId }
                Handler(Looper.getMainLooper()).post {
                    result.success(reader.rfidReader.isConnected)
                }
            } catch (ex: InvalidUsageException) {
                Handler(Looper.getMainLooper()).post {
                    result.error("ERROR", ex.info, null)
                }
            } catch (ex: OperationFailureException) {
                Handler(Looper.getMainLooper()).post {
                    result.error("ERROR", ex.vendorMessage, null)
                }
            }
        }
    }

    private fun connect(call: MethodCall, result: MethodChannel.Result) {
        val readerId = call.argument<String>("reader") ?: run {
            result.error("INVALID_ARGUMENT", "Missing argument reader", null)
            return
        }

        val maxRetries = call.argument<Int>("maxRetries") ?: 4

        GlobalScope.launch {
            try {
                val reader = availableRFIDReaderList!!.first { it.address == readerId }
                if (!reader.rfidReader.isConnected) {
                    _connect(maxRetries, reader)
                }
                Handler(Looper.getMainLooper()).post {
                    result.success(null)
                }
            } catch (ex: InvalidUsageException) {
                Handler(Looper.getMainLooper()).post {
                    result.error("CONNECTION_ERROR", ex.info, null)
                }
            } catch (ex: OperationFailureException) {
                Handler(Looper.getMainLooper()).post {
                    result.error("CONNECTION_ERROR", ex.vendorMessage, null)
                }
            }
        }
    }

    private fun _connect(remainingTries: Int, reader: ReaderDevice) {
        try {
            if (!reader.rfidReader.isConnected) {
                reader.rfidReader.connect()
            }
            configureReader(reader)
        }
        catch (ex: Exception) {
            if (remainingTries <= 0) {
                throw ex
            }
            _connect(remainingTries - 1, reader)
        }
    }

    private fun configureReader(readerDevice: ReaderDevice) {
        val reader = readerDevice.rfidReader
        if (reader.isConnected) {
            val triggerInfo = TriggerInfo()
            triggerInfo.StartTrigger.triggerType = START_TRIGGER_TYPE.START_TRIGGER_TYPE_IMMEDIATE
            triggerInfo.StopTrigger.triggerType = STOP_TRIGGER_TYPE.STOP_TRIGGER_TYPE_IMMEDIATE
            reader.Events.addEventsListener(ReaderEventsListener(readerDevice, channel))
            reader.Events.setAttachTagDataWithReadEvent(true)
            reader.Events.setBatchModeEvent(true)
            reader.Events.setBatteryEvent(true)
            reader.Events.setHandheldEvent(true)
            reader.Events.setInventoryStartEvent(true)
            reader.Events.setInventoryStopEvent(true)
            reader.Events.setOperationEndSummaryEvent(true)
            reader.Events.setPowerEvent(true)
            reader.Events.setReaderDisconnectEvent(true)
            reader.Events.setTagReadEvent(true)
            reader.Config.setBatchMode(BATCH_MODE.DISABLE)
            reader.Config.setTriggerMode(ENUM_TRIGGER_MODE.RFID_MODE, true)
            reader.Config.setUniqueTagReport(false)
            reader.Config.startTrigger = triggerInfo.StartTrigger
            reader.Config.stopTrigger = triggerInfo.StopTrigger
            reader.Config.beeperVolume = BEEPER_VOLUME.QUIET_BEEP
            reader.Config.dpoState = DYNAMIC_POWER_OPTIMIZATION.DISABLE
            reader.Actions.PreFilters.deleteAll()

            reader.Config.saveConfig()
        }
    }

    private fun getActiveReaders(result: MethodChannel.Result) {
        try {
            if (readers == null) {
                readers = Readers(context, ENUM_TRANSPORT.BLUETOOTH)
            }
            availableRFIDReaderList = readers!!.GetAvailableRFIDReaderList()

            val items = ArrayList(availableRFIDReaderList!!.filter { it.rfidReader.isConnected }).map {
                hashMapOf(
                        "name" to it.name,
                        "id" to it.address
                )
            }

            result.success(items)
        }
        catch (e: InvalidUsageException) {
            result.error("FETCH_READER_ERROR", e.vendorMessage, e.info)
        }
    }

    private fun getAvailableReaders(result: MethodChannel.Result) {
        try {
            if (readers == null) {
                readers = Readers(context, ENUM_TRANSPORT.BLUETOOTH)
            }
            availableRFIDReaderList = readers!!.GetAvailableRFIDReaderList();
            val items = availableRFIDReaderList!!.map {
                hashMapOf(
                        "name" to it.name,
                        "id" to it.address
                )
            }

            result.success(items)
        }
        catch (e: InvalidUsageException) {
            result.error("FETCH_READER_ERROR", e.vendorMessage, e.info)
        }
    }

    private fun getSdkVersion(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {

    }

    override fun RFIDReaderAppeared(readerDevice: ReaderDevice?) {
        channel.invokeMethod("eventReaderAppeared", hashMapOf(
                "id" to readerDevice!!.address,
                "name" to readerDevice.name
        ))
    }

    override fun RFIDReaderDisappeared(readerDevice: ReaderDevice?) {
        channel.invokeMethod("eventReaderDisappeared", hashMapOf(
                "id" to readerDevice!!.address,
                "name" to readerDevice.name
        ))
    }

    companion object {
        fun parseMemoryBank(memoryBank: Int): MEMORY_BANK {
            return when (memoryBank) {
                0x01 -> MEMORY_BANK.MEMORY_BANK_EPC
                0x02 -> MEMORY_BANK.MEMORY_BANK_TID
                0x04 -> MEMORY_BANK.MEMORY_BANK_USER
                0x08 -> MEMORY_BANK.MEMORY_BANK_RESERVED
                else -> throw Exception("Unsupported memory bank value")
            }
        }

        private fun serializeMemoryBank(memoryBank: MEMORY_BANK?): Int? {
            if (memoryBank == null)
                return null
            return when (memoryBank) {
                MEMORY_BANK.MEMORY_BANK_EPC -> 0x01
                MEMORY_BANK.MEMORY_BANK_TID -> 0x02
                MEMORY_BANK.MEMORY_BANK_USER -> 0x04
                MEMORY_BANK.MEMORY_BANK_RESERVED -> 0x08
                else -> throw Exception("Unsupported memory bank value")
            }
        }

        fun serializeStatusEventType(statusEventType: STATUS_EVENT_TYPE): Int? {
            return when (statusEventType) {
                STATUS_EVENT_TYPE.INVENTORY_START_EVENT -> 0x00
                STATUS_EVENT_TYPE.INVENTORY_STOP_EVENT -> 0x01
                STATUS_EVENT_TYPE.ACCESS_START_EVENT -> 0x00
                STATUS_EVENT_TYPE.ACCESS_STOP_EVENT -> 0x01
                STATUS_EVENT_TYPE.BATCH_MODE_EVENT -> 0x02
                STATUS_EVENT_TYPE.OPERATION_END_SUMMARY_EVENT -> 0x03
                STATUS_EVENT_TYPE.TEMPERATURE_ALARM_EVENT -> 0x04
                STATUS_EVENT_TYPE.POWER_EVENT -> 0x05
                else -> null
            }
        }

        fun serializeTagData(tagData: TagData, memoryBank: MEMORY_BANK?): HashMap<String, Any?> {
            return hashMapOf(
                    "tagId" to tagData.tagID,
                    "firstSeenTime" to tagData.SeenTime?.upTime?.firstSeenTimeStamp,
                    "lastSeenTime" to tagData.SeenTime?.upTime?.lastSeenTimeStamp,
                    "pc" to tagData.pc?.toString(16),
                    "peakRSSI" to tagData.peakRSSI,
                    "channelIndex" to tagData.channelIndex,
                    "phaseInfo" to tagData.phase,
                    "seenCount" to tagData.tagSeenCount,
                    "opCode" to tagData.opCode?.ordinal,
                    "operationSucceed" to (tagData.opStatus == ACCESS_OPERATION_STATUS.ACCESS_SUCCESS),
                    "operationStatus" to tagData.opStatus?.toString(),
                    "memoryBank" to serializeMemoryBank(memoryBank),
                    "memoryBankData" to tagData.memoryBankData,
                    "permaLockData" to tagData.permaLockData,
                    "modifiedWordCount" to tagData.numberOfWords,
                    "g2v2Result" to tagData.g2v2OpCode?.toString(),
                    "g2v2Response" to tagData.g2v2Response
            )
        }
    }

    class ReaderEventsListener(
            private var reader: ReaderDevice,
            private var channel: MethodChannel
    ) : RfidEventsListener {


        override fun eventReadNotify(event: RfidReadEvents?) {
            event?.readEventData?.tagData?.run {
                if (this.tagID != null) {
                    Handler(Looper.getMainLooper()).post {
                        channel.invokeMethod("eventReadNotify", hashMapOf<String, Any>(
                                "reader" to hashMapOf<String, Any>(
                                        "id" to reader.address,
                                        "name" to reader.name
                                ),
                                "tagData" to serializeTagData(this, this.memoryBank)
                        ))
                    }
                }
                if (this.isContainsLocationInfo) {
                    Handler(Looper.getMainLooper()).post {
                        channel.invokeMethod("eventProximityNotify", hashMapOf<String, Any>(
                                "reader" to hashMapOf<String, Any>(
                                        "id" to reader.address,
                                        "name" to reader.name
                                ),
                                "proximityPercent" to this.LocationInfo.relativeDistance
                        ))
                    }
                }
            }
        }

        override fun eventStatusNotify(event: RfidStatusEvents?) {
            event?.StatusEventData?.run {
                val reader = hashMapOf<String, Any>(
                        "id" to reader.address,
                        "name" to reader.name
                )

                when(this.statusEventType) {
                    STATUS_EVENT_TYPE.OPERATION_END_SUMMARY_EVENT -> {
                        Handler(Looper.getMainLooper()).post {
                            channel.invokeMethod("eventStatusNotify", hashMapOf<String, Any>(
                                    "reader" to reader,
                                    "event" to serializeStatusEventType(this.statusEventType)!!,
                                    "data" to hashMapOf(
                                            "totalTags" to this.OperationEndSummaryData.totalTags,
                                            "totalRounds" to this.OperationEndSummaryData.totalRounds,
                                            "totalTimeUs" to this.OperationEndSummaryData.totalTimeuS
                                    )
                            ))
                        }
                    }

                    STATUS_EVENT_TYPE.TEMPERATURE_ALARM_EVENT -> {
                        Handler(Looper.getMainLooper()).post {
                            channel.invokeMethod("eventStatusNotify", hashMapOf<String, Any>(
                                    "reader" to reader,
                                    "event" to serializeStatusEventType(this.statusEventType)!!,
                                    "data" to hashMapOf(
                                            "cause" to this.TemperatureAlarmData.cause,
                                            "radioPATemp" to this.TemperatureAlarmData.paTemp,
                                            "STM32Temp" to this.TemperatureAlarmData.currentTemperature
                                    )
                            ))
                        }
                    }

                    STATUS_EVENT_TYPE.POWER_EVENT -> {
                        Handler(Looper.getMainLooper()).post {
                            channel.invokeMethod("eventStatusNotify", hashMapOf<String, Any>(
                                    "reader" to reader,
                                    "event" to serializeStatusEventType(this.statusEventType)!!,
                                    "data" to hashMapOf(
                                            "cause" to this.PowerData.cause,
                                            "power" to this.PowerData.power,
                                            "voltage" to this.PowerData.voltage,
                                            "current" to this.PowerData.current
                                    )
                            ))
                        }
                    }

                    STATUS_EVENT_TYPE.HANDHELD_TRIGGER_EVENT -> {
                        Handler(Looper.getMainLooper()).post {
                            channel.invokeMethod("eventTriggerNotify", hashMapOf<String, Any>(
                                    "reader" to reader,
                                    "event" to if (this.HandheldTriggerEventData.handheldEvent == HANDHELD_TRIGGER_EVENT_TYPE.HANDHELD_TRIGGER_RELEASED) 1 else 0
                            ))
                        }
                    }

                    STATUS_EVENT_TYPE.BATTERY_EVENT -> {
                        Handler(Looper.getMainLooper()).post {
                            channel.invokeMethod("eventBatteryNotify", hashMapOf<String, Any>(
                                    "reader" to reader,
                                    "cause" to this.BatteryData.cause,
                                    "isCharging" to this.BatteryData.charging,
                                    "powerLevel" to this.BatteryData.level
                            ))
                        }
                    }

                    STATUS_EVENT_TYPE.INVENTORY_START_EVENT, STATUS_EVENT_TYPE.INVENTORY_STOP_EVENT, STATUS_EVENT_TYPE.ACCESS_START_EVENT, STATUS_EVENT_TYPE.ACCESS_STOP_EVENT -> {
                        Handler(Looper.getMainLooper()).post {
                            channel.invokeMethod("eventStatusNotify", hashMapOf<String, Any?>(
                                    "reader" to reader,
                                    "event" to serializeStatusEventType(this.statusEventType)!!,
                                    "data" to null
                            ))
                        }
                    }

                    STATUS_EVENT_TYPE.DISCONNECTION_EVENT -> {
                        Handler(Looper.getMainLooper()).post {
                            channel.invokeMethod("eventDisconnectionNotify", hashMapOf<String, Any?>(
                                "reader" to reader
                            ))
                        }
                    }

                    else -> {}
                }
            }
        }
    }
}