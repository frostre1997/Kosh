package com.kosh.shell

import android.content.Context
import android.os.PowerManager

object TermService {
    private var wakeLock: PowerManager.WakeLock? = null
    private var isWakelockHeld = false

    fun toggleWakelock(context: Context) {
        if (wakeLock == null) {
            val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Kosh::WakeLock")
        }
        if (wakeLock!!.isHeld) {
            wakeLock!!.release()
            isWakelockHeld = false
        } else {
            wakeLock!!.acquire(10 * 60 * 1000L)
            isWakelockHeld = true
        }
        // Optionally update notification here
    }

    fun isWakelockHeld(): Boolean = isWakelockHeld
}
