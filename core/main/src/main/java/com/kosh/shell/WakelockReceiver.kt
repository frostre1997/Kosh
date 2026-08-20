package com.kosh.shell

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.PowerManager

class WakelockReceiver : BroadcastReceiver() {
    companion object {
        private var wakeLock: PowerManager.WakeLock? = null
        private var isHeld = false
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != "com.kosh.shell.TOGGLE_WAKELOCK") return
        val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        if (wakeLock == null) {
            wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Kosh::WakeLock")
        }
        if (wakeLock!!.isHeld) {
            wakeLock!!.release()
            isHeld = false
        } else {
            wakeLock!!.acquire(10 * 60 * 1000L)
            isHeld = true
        }
    }
}
