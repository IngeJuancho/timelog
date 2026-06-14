package com.example.timelog // Asegúrate de que esto coincida con tu paquete actual

import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.timelog/volume_buttons"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Preparamos el canal para hablar con Flutter
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
    }

    // Esta función intercepta los botones físicos
    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
            // Mandamos la señal a Flutter
            methodChannel?.invokeMethod("volumeDown", null)
            // Devolvemos 'true' para decirle a Android "Ya lo usé, no muestres la barra de volumen"
            return true 
        } else if (keyCode == KeyEvent.KEYCODE_VOLUME_UP) {
            methodChannel?.invokeMethod("volumeUp", null)
            return true 
        }
        return super.onKeyDown(keyCode, event)
    }
}