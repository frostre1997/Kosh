package com.rk.terminal.ui.screens.terminal

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Environment
import android.system.Os
import com.rk.terminal.ui.activities.terminal.MainActivity
import com.rk.terminal.ui.screens.settings.WorkingMode
import java.io.File
import java.io.FileOutputStream

object MkSession {
    private fun localBinDir(): File {
        return File(Environment.getDataDirectory(), "data/${MainActivity::class.java.`package`!!.name}/files/bin")
    }

    private fun localLibDir(): File {
        return File(Environment.getDataDirectory(), "data/${MainActivity::class.java.`package`!!.name}/files/lib")
    }

    // Extract Alpine rootfs from assets on first run
    private fun extractAlpineRootfs(context: Context): File {
        val rootfsDir = File(context.filesDir, "alpine-rootfs")
        if (!rootfsDir.exists()) {
            rootfsDir.mkdirs()
            try {
                context.assets.open("alpine-rootfs.tar.gz").use { input ->
                    val tempFile = File(context.cacheDir, "alpine-rootfs.tar.gz")
                    tempFile.outputStream().use { output -> input.copyTo(output) }
                    // Use tar to extract
                    Runtime.getRuntime().exec(arrayOf("tar", "-xzf", tempFile.absolutePath, "-C", rootfsDir.absolutePath)).waitFor()
                    tempFile.delete()
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        return rootfsDir
    }

    fun buildEnv(context: Context, sessionId: String): MutableList<String> {
        val binDir = localBinDir()
        val libDir = localLibDir()
        val alpineRoot = extractAlpineRootfs(context)

        val env = mutableListOf(
            "PATH=${System.getenv("PATH") ?: "/system/bin:/system/xbin"}:/sbin:${binDir.absolutePath}",
            "HOME=${Environment.getExternalStorageDirectory().absolutePath}",
            "PUBLIC_HOME=${context.getExternalFilesDir(null)?.absolutePath}",
            "COLORTERM=truecolor",
            "TERM=xterm-256color",
            "LANG=C.UTF-8",
            "BIN=${binDir}",
            "DEBUG=${BuildConfig.DEBUG}",
            "PREFIX=${context.filesDir.parentFile!!.path}",
            "LD_LIBRARY_PATH=${libDir.absolutePath}",
            "LINKER=${if (File("/system/bin/linker64").exists()) "/system/bin/linker64" else "/system/bin/linker"}",
            "NATIVE_LIB_DIR=${context.applicationInfo.nativeLibraryDir}",
            "PKG=${context.packageName}",
            "RISH_APPLICATION_ID=${context.packageName}",
            "PKG_PATH=${context.applicationInfo.sourceDir}",
            "PROOT_TMP_DIR=${context.getExternalFilesDir(null)?.absolutePath}/proot-tmp",
            "TMPDIR=${context.getExternalFilesDir(null)?.absolutePath}/tmp",
            "PROOT_LOADER=${context.applicationInfo.nativeLibraryDir}/libloader.so",
            "ALPINE_ROOT=${alpineRoot.absolutePath}"
        )
        return env
    }

    fun buildPendingCommand(context: Context, mode: Int, sessionId: String): String {
        return when (mode) {
            WorkingMode.ALPINE -> {
                val root = extractAlpineRootfs(context).absolutePath
                "proot -r $root /bin/busybox sh -l"
            }
            WorkingMode.ANDROID -> {
                "/system/bin/sh"
            }
            else -> {
                "/system/bin/sh"
            }
        }
    }

    fun buildCustomPendingCommand(context: Context, custom: CustomSession): String {
        return custom.pendingCommand
    }
}
