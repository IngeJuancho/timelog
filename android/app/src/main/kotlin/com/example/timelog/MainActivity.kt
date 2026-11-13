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

    // Intercepta los botones físicos de volumen en el primer flanco de pulsación
    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
            // Solo disparar en el evento inicial (repeatCount == 0), ignorar repeticiones automáticas por pulsación continua
            if (event?.repeatCount == 0) {
                methodChannel?.invokeMethod("volumeDown", null)
            }
            return true 
        } else if (keyCode == KeyEvent.KEYCODE_VOLUME_UP) {
            if (event?.repeatCount == 0) {
                methodChannel?.invokeMethod("volumeUp", null)
            }
            return true 
        }
        return super.onKeyDown(keyCode, event)
    }

    override fun onKeyUp(keyCode: Int, event: KeyEvent?): Boolean {
        // Consumir el flanco de subida para no disparar eventos colaterales en el sistema operativo
        if (keyCode == KeyEvent.KEYCODE_VOLUME_DOWN || keyCode == KeyEvent.KEYCODE_VOLUME_UP) {
            return true
        }
        return super.onKeyUp(keyCode, event)
    }
}