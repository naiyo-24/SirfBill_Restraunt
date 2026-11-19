package com.example.manju_medical

import android.Manifest
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.UUID

class BluetoothPrinterManager(private val activity: Activity) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL = "com.sirfbill.pos/bluetooth_printer"
        private val SPP_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
        const val BT_PERMISSION_CODE = 4001
    }

    private var pendingResult: MethodChannel.Result? = null

    private fun hasBtPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            ContextCompat.checkSelfPermission(
                activity,
                Manifest.permission.BLUETOOTH_CONNECT
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            ContextCompat.checkSelfPermission(
                activity,
                Manifest.permission.BLUETOOTH
            ) == PackageManager.PERMISSION_GRANTED
        }
    }

    fun handleRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode == BT_PERMISSION_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingResult?.success(granted)
            pendingResult = null
            return true
        }
        return false
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val adapter = BluetoothAdapter.getDefaultAdapter()
        if (adapter == null) {
            result.error("NO_BLUETOOTH", "Device does not support Bluetooth", null)
            return
        }

        when (call.method) {
            "hasPermission" -> {
                result.success(hasBtPermission())
            }

            "requestPermission" -> {
                if (hasBtPermission()) {
                    result.success(true)
                    return
                }
                pendingResult = result
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    ActivityCompat.requestPermissions(
                        activity,
                        arrayOf(Manifest.permission.BLUETOOTH_CONNECT, Manifest.permission.BLUETOOTH_SCAN),
                        BT_PERMISSION_CODE
                    )
                } else {
                    ActivityCompat.requestPermissions(
                        activity,
                        arrayOf(Manifest.permission.BLUETOOTH, Manifest.permission.BLUETOOTH_ADMIN),
                        BT_PERMISSION_CODE
                    )
                }
            }

            "getBondedDevices" -> {
                if (!hasBtPermission()) {
                    result.error("PERMISSION_DENIED", "Bluetooth permission not granted", null)
                    return
                }
                try {
                    val bonded = adapter.bondedDevices ?: emptySet<BluetoothDevice>()
                    val list = mutableListOf<Map<String, Any?>>()
                    for (dev in bonded) {
                        list.add(
                            mapOf(
                                "name" to (dev.name ?: "Unknown Bluetooth Device"),
                                "address" to dev.address,
                                "type" to dev.type
                            )
                        )
                    }
                    result.success(list)
                } catch (e: Exception) {
                    result.error("GET_DEVICES_FAILED", e.message, null)
                }
            }

            "printBytes" -> {
                val address = call.argument<String>("address")
                val bytes = call.argument<ByteArray>("bytes")

                if (address.isNullOrEmpty() || bytes == null || bytes.isEmpty()) {
                    result.error("INVALID_ARGS", "Address and bytes are required", null)
                    return
                }

                if (!hasBtPermission()) {
                    result.error("PERMISSION_DENIED", "Bluetooth permission not granted", null)
                    return
                }

                Thread {
                    var socket: BluetoothSocket? = null
                    try {
                        val device = adapter.getRemoteDevice(address)
                        adapter.cancelDiscovery()

                        socket = device.createRfcommSocketToServiceRecord(SPP_UUID)
                        socket.connect()

                        val out = socket.outputStream
                        out.write(bytes)
                        out.flush()

                        activity.runOnUiThread {
                            result.success(mapOf("success" to true))
                        }
                    } catch (e: Exception) {
                        activity.runOnUiThread {
                            result.error("PRINT_FAILED", e.message ?: "Failed to print via Bluetooth", null)
                        }
                    } finally {
                        try {
                            socket?.close()
                        } catch (_: Exception) {}
                    }
                }.start()
            }

            else -> result.notImplemented()
        }
    }
}
