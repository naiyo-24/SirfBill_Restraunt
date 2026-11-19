package com.example.manju_medical

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbDeviceConnection
import android.hardware.usb.UsbEndpoint
import android.hardware.usb.UsbInterface
import android.hardware.usb.UsbManager
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.sirfbill.pos/usb_printer"
    private var permissionReceiver: BroadcastReceiver? = null
    private var bluetoothPrinterManager: BluetoothPrinterManager? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val btManager = BluetoothPrinterManager(this)
        bluetoothPrinterManager = btManager
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BluetoothPrinterManager.CHANNEL)
            .setMethodCallHandler(btManager)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val usbManager = getSystemService(Context.USB_SERVICE) as? UsbManager
            if (usbManager == null) {
                result.error("NO_USB_MANAGER", "UsbManager is not available on this device", null)
                return@setMethodCallHandler
            }

            when (call.method) {
                "getUsbDevices" -> {
                    try {
                        val deviceList = usbManager.deviceList
                        val list = mutableListOf<Map<String, Any?>>()
                        for ((_, device) in deviceList) {
                            list.add(
                                mapOf(
                                    "deviceId" to device.deviceId,
                                    "deviceName" to device.deviceName,
                                    "vendorId" to device.vendorId,
                                    "productId" to device.productId,
                                    "productName" to (device.productName ?: "USB Device"),
                                    "manufacturerName" to (device.manufacturerName ?: ""),
                                    "isPrinter" to isPrinterDevice(device),
                                    "hasPermission" to usbManager.hasPermission(device)
                                )
                            )
                        }
                        result.success(list)
                    } catch (e: Exception) {
                        result.error("SCAN_ERROR", e.message, null)
                    }
                }

                "hasPermission" -> {
                    val deviceId = call.argument<Int>("deviceId")
                    if (deviceId == null) {
                        result.error("INVALID_ARG", "deviceId is required", null)
                        return@setMethodCallHandler
                    }
                    val device = findDevice(usbManager, deviceId)
                    if (device == null) {
                        result.success(false)
                    } else {
                        result.success(usbManager.hasPermission(device))
                    }
                }

                "requestPermission" -> {
                    val deviceId = call.argument<Int>("deviceId")
                    if (deviceId == null) {
                        result.error("INVALID_ARG", "deviceId is required", null)
                        return@setMethodCallHandler
                    }
                    val device = findDevice(usbManager, deviceId)
                    if (device == null) {
                        result.error("DEVICE_NOT_FOUND", "USB device $deviceId not found", null)
                        return@setMethodCallHandler
                    }

                    if (usbManager.hasPermission(device)) {
                        result.success(true)
                        return@setMethodCallHandler
                    }

                    requestDevicePermission(usbManager, device) { granted ->
                        result.success(granted)
                    }
                }

                "printBytes" -> {
                    val deviceId = call.argument<Int>("deviceId")
                    val rawBytes = call.argument<ByteArray>("bytes")

                    if (rawBytes == null || rawBytes.isEmpty()) {
                        result.error("INVALID_DATA", "Print bytes cannot be empty", null)
                        return@setMethodCallHandler
                    }

                    val device = if (deviceId != null) {
                        findDevice(usbManager, deviceId)
                    } else {
                        findFirstPrinter(usbManager)
                    }

                    if (device == null) {
                        result.error("DEVICE_NOT_FOUND", "No suitable USB thermal printer connected", null)
                        return@setMethodCallHandler
                    }

                    if (!usbManager.hasPermission(device)) {
                        requestDevicePermission(usbManager, device) { granted ->
                            if (!granted) {
                                result.error("PERMISSION_DENIED", "USB device permission was not granted by user", null)
                            } else {
                                executePrint(usbManager, device, rawBytes, result)
                            }
                        }
                        return@setMethodCallHandler
                    }

                    executePrint(usbManager, device, rawBytes, result)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun isPrinterDevice(device: UsbDevice): Boolean {
        if (device.deviceClass == UsbConstants.USB_CLASS_PRINTER) return true
        for (i in 0 until device.interfaceCount) {
            val iface = device.getInterface(i)
            if (iface.interfaceClass == UsbConstants.USB_CLASS_PRINTER) return true
            for (e in 0 until iface.endpointCount) {
                val ep = iface.getEndpoint(e)
                if (ep.direction == UsbConstants.USB_DIR_OUT && ep.type == UsbConstants.USB_ENDPOINT_XFER_BULK) {
                    return true
                }
            }
        }
        return false
    }

    private fun findDevice(usbManager: UsbManager, deviceId: Int): UsbDevice? {
        return usbManager.deviceList.values.firstOrNull { it.deviceId == deviceId }
    }

    private fun findFirstPrinter(usbManager: UsbManager): UsbDevice? {
        val list = usbManager.deviceList.values
        val explicitPrinter = list.firstOrNull { d ->
            d.deviceClass == UsbConstants.USB_CLASS_PRINTER ||
            (0 until d.interfaceCount).any { d.getInterface(it).interfaceClass == UsbConstants.USB_CLASS_PRINTER }
        }
        if (explicitPrinter != null) return explicitPrinter
        return list.firstOrNull { isPrinterDevice(it) } ?: list.firstOrNull()
    }

    private fun requestDevicePermission(
        usbManager: UsbManager,
        device: UsbDevice,
        callback: (Boolean) -> Unit
    ) {
        val action = "com.sirfbill.pos.USB_PERMISSION_${System.currentTimeMillis()}"
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_MUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val intent = Intent(action).setPackage(packageName)
        val pendingIntent = PendingIntent.getBroadcast(this, 0, intent, flags)

        permissionReceiver?.let {
            try { unregisterReceiver(it) } catch (_: Exception) {}
        }

        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, recvIntent: Intent?) {
                if (recvIntent?.action == action) {
                    try { unregisterReceiver(this) } catch (_: Exception) {}
                    permissionReceiver = null
                    val granted = recvIntent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)
                    callback(granted)
                }
            }
        }
        permissionReceiver = receiver

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(receiver, IntentFilter(action), Context.RECEIVER_EXPORTED)
        } else {
            registerReceiver(receiver, IntentFilter(action))
        }

        usbManager.requestPermission(device, pendingIntent)
    }

    private fun executePrint(
        usbManager: UsbManager,
        device: UsbDevice,
        bytes: ByteArray,
        result: MethodChannel.Result
    ) {
        Thread {
            var connection: UsbDeviceConnection? = null
            var usbInterface: UsbInterface? = null
            try {
                connection = usbManager.openDevice(device)
                    ?: throw Exception("Could not open connection to USB device ${device.deviceName}")

                var bulkOutEndpoint: UsbEndpoint? = null
                for (i in 0 until device.interfaceCount) {
                    val iface = device.getInterface(i)
                    for (e in 0 until iface.endpointCount) {
                        val ep = iface.getEndpoint(e)
                        if (ep.direction == UsbConstants.USB_DIR_OUT && ep.type == UsbConstants.USB_ENDPOINT_XFER_BULK) {
                            usbInterface = iface
                            bulkOutEndpoint = ep
                            break
                        }
                    }
                    if (bulkOutEndpoint != null) break
                }

                if (usbInterface == null || bulkOutEndpoint == null) {
                    throw Exception("No bulk OUT endpoint found on USB device")
                }

                if (!connection.claimInterface(usbInterface, true)) {
                    throw Exception("Failed to claim USB interface for printing")
                }

                val chunkSize = 4096
                var offset = 0
                var totalWritten = 0

                while (offset < bytes.size) {
                    val length = Math.min(chunkSize, bytes.size - offset)
                    val chunk = bytes.copyOfRange(offset, offset + length)
                    val written = connection.bulkTransfer(bulkOutEndpoint, chunk, length, 5000)
                    if (written < 0) {
                        throw Exception("USB bulkTransfer failed with return code $written at offset $offset")
                    }
                    totalWritten += written
                    offset += length
                }

                runOnUiThread {
                    result.success(
                        mapOf(
                            "success" to true,
                            "bytesWritten" to totalWritten
                        )
                    )
                }
            } catch (e: Exception) {
                runOnUiThread {
                    result.error("PRINT_FAILED", e.message ?: "Unknown USB print error", null)
                }
            } finally {
                try {
                    usbInterface?.let { connection?.releaseInterface(it) }
                } catch (_: Exception) {}
                try {
                    connection?.close()
                } catch (_: Exception) {}
            }
        }.start()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        if (bluetoothPrinterManager?.handleRequestPermissionsResult(requestCode, permissions, grantResults) == true) {
            return
        }
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    override fun onDestroy() {
        permissionReceiver?.let {
            try { unregisterReceiver(it) } catch (_: Exception) {}
            permissionReceiver = null
        }
        super.onDestroy()
    }
}
