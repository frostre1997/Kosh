package com.kosh.shell

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import com.termux.terminal.TerminalSession
import com.termux.terminal.TerminalSessionClient

class ShellTermSession(
    shell: String,
    cwd: String,
    args: Array<String>,
    env: Array<String>,
    transcriptRows: Int,
    client: TerminalSessionClient,
    private val context: Context,
    private val procId: Int
) : TerminalSession(shell, cwd, args, env, transcriptRows, client) {

    override fun write(bytes: ByteArray, offset: Int, length: Int) {
        val cmd = String(bytes, offset, length).trim()
        if (cmd.isEmpty()) {
            super.write(bytes, offset, length)
            return
        }

        // ─── Suspend / Resume ──────────────────────────────────────────
        if (cmd == "suspend" || cmd == "sp") {
            TermExec.sendSignal(-procId, 19) // SIGSTOP
            val msg = "Session suspended.\n"
            appendToEmulator(msg.toByteArray(), 0, msg.length)
            return
        }
        if (cmd == "resume" || cmd == "rs") {
            TermExec.sendSignal(-procId, 18) // SIGCONT
            val msg = "Session resumed.\n"
            appendToEmulator(msg.toByteArray(), 0, msg.length)
            return
        }

        // ─── Wakelock with flags ──────────────────────────────────────
        if (cmd.startsWith("wakelock")) {
            val parts = cmd.split(" ")
            val flag = if (parts.size > 1) parts[1] else ""
            when (flag) {
                "-y" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                        if (pm != null && !pm.isIgnoringBatteryOptimizations(context.packageName)) {
                            Handler(Looper.getMainLooper()).post {
                                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                                intent.data = Uri.parse("package:" + context.packageName)
                                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                context.startActivity(intent)
                            }
                            val msg = "Opening battery optimisation settings...\n"
                            appendToEmulator(msg.toByteArray(), 0, msg.length)
                            return
                        }
                    }
                    TermService.toggleWakelock()
                    val msg = "Wakelock toggled.\n"
                    appendToEmulator(msg.toByteArray(), 0, msg.length)
                    return
                }
                "-r" -> {
                    TermService.toggleWakelock()
                    val msg = "Wakelock toggled (no dialog).\n"
                    appendToEmulator(msg.toByteArray(), 0, msg.length)
                    return
                }
                "-s" -> {
                    val status = if (TermService.isWakelockHeld()) "held" else "not held"
                    val msg = "Wakelock is $status.\n"
                    appendToEmulator(msg.toByteArray(), 0, msg.length)
                    return
                }
                "-h" -> {
                    val msg = "Usage: wakelock [-y] [-r] [-s] [-h]\n" +
                              "  -y   Open battery dialog (if needed) then toggle\n" +
                              "  -r   Toggle without dialog\n" +
                              "  -s   Show status\n" +
                              "  -h   Show this help\n"
                    appendToEmulator(msg.toByteArray(), 0, msg.length)
                    return
                }
                else -> {
                    // Default: same as -y
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                        if (pm != null && !pm.isIgnoringBatteryOptimizations(context.packageName)) {
                            Handler(Looper.getMainLooper()).post {
                                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                                intent.data = Uri.parse("package:" + context.packageName)
                                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                context.startActivity(intent)
                            }
                            val msg = "Opening battery optimisation settings...\n"
                            appendToEmulator(msg.toByteArray(), 0, msg.length)
                            return
                        }
                    }
                    TermService.toggleWakelock()
                    val msg = "Wakelock toggled.\n"
                    appendToEmulator(msg.toByteArray(), 0, msg.length)
                    return
                }
            }
        }

        // ─── All other commands ──────────────────────────────────────
        super.write(bytes, offset, length)
    }
}
