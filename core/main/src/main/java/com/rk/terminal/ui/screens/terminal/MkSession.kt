package com.kosh.shell.ui.screens.terminal

import android.content.Context
import com.kosh.shell.libcommons.alpineHomeDir
import com.kosh.shell.libcommons.child
import com.kosh.shell.libcommons.createFileIfNot
import com.kosh.shell.libcommons.localBinDir
import com.kosh.shell.libcommons.localDir
import com.kosh.shell.libcommons.localLibDir
import com.kosh.shell.App.Companion.getTempDir
import com.kosh.shell.BuildConfig
import com.kosh.shell.ui.screens.settings.WorkingMode
import com.termux.terminal.TerminalEmulator
import com.termux.terminal.TerminalSession
import com.termux.terminal.TerminalSessionClient
import java.io.File
nprivate fun extractAlpineRootfs(context: Context): File {
    val rootfsDir = File(context.filesDir, "alpine-rootfs")
    val mProcId = TermExec.createSubprocess(mTermFd, arg0, args, env)
    if (!rootfsDir.exists()) {
        rootfsDir.mkdirs()
        try {
            context.assets.open("alpine-rootfs.tar.gz").use { input ->
                val tempFile = File(context.cacheDir, "alpine-rootfs.tar.gz")
                tempFile.outputStream().use { output -> input.copyTo(output) }
                Runtime.getRuntime().exec(arrayOf("tar", "-xzf", tempFile.absolutePath, "-C", rootfsDir.absolutePath)).waitFor()
                tempFile.delete()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    return rootfsDir
}

import java.io.FileOutputStream
nprivate fun extractAlpineRootfs(context: Context): File {
    val rootfsDir = File(context.filesDir, "alpine-rootfs")
    if (!rootfsDir.exists()) {
        rootfsDir.mkdirs()
        try {
            context.assets.open("alpine-rootfs.tar.gz").use { input ->
                val tempFile = File(context.cacheDir, "alpine-rootfs.tar.gz")
                tempFile.outputStream().use { output -> input.copyTo(output) }
                Runtime.getRuntime().exec(arrayOf("tar", "-xzf", tempFile.absolutePath, "-C", rootfsDir.absolutePath)).waitFor()
                tempFile.delete()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    return rootfsDir
}


data class PendingCommand(
    val shell: String,
    val args: Array<String>,
    val workingDir: String?,
    val env: List<String>?
)

object MkSession {
    // Extract any asset binary to files dir and make executable
    private fun extractBinary(context: Context, assetName: String): File {
        val targetFile = File(context.filesDir, assetName)
        if (!targetFile.exists()) {
            try {
                context.assets.open(assetName).use { input ->
                    FileOutputStream(targetFile).use { output ->
                        input.copyTo(output)
                    }
                }
                targetFile.setExecutable(true)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        return targetFile
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
                    Runtime.getRuntime().exec(arrayOf("tar", "-xzf", tempFile.absolutePath, "-C", rootfsDir.absolutePath)).waitFor()
                    tempFile.delete()
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        return rootfsDir
    }

    fun createSession(
        context: Context,
        sessionClient: TerminalSessionClient,
        sessionId: String,
        workingMode: Int,
        pendingCommand: PendingCommand? = null
    ): TerminalSession {
        with(context) {
            val envVariables = mapOf(
                "ANDROID_ART_ROOT" to System.getenv("ANDROID_ART_ROOT"),
                "ANDROID_DATA" to System.getenv("ANDROID_DATA"),
                "ANDROID_I18N_ROOT" to System.getenv("ANDROID_I18N_ROOT"),
                "ANDROID_ROOT" to System.getenv("ANDROID_ROOT"),
                "ANDROID_RUNTIME_ROOT" to System.getenv("ANDROID_RUNTIME_ROOT"),
                "ANDROID_TZDATA_ROOT" to System.getenv("ANDROID_TZDATA_ROOT"),
                "BOOTCLASSPATH" to System.getenv("BOOTCLASSPATH"),
                "DEX2OATBOOTCLASSPATH" to System.getenv("DEX2OATBOOTCLASSPATH"),
                "EXTERNAL_STORAGE" to System.getenv("EXTERNAL_STORAGE")
            )

            val workingDir = pendingCommand?.workingDir ?: alpineHomeDir().path

            // Extract binaries if they don't exist
            extractBinary(context, "busybox")
            extractBinary(context, "bash")
            extractBinary(context, "python")
            extractBinary(context, "pkg.sh")

            // Alpine rootfs extraction
            val alpineRoot = extractAlpineRootfs(context)

            val useChroot = Rootfs.execMode.value == ExecMode.CHROOT

            val initFile: File = localBinDir().child("init-host")
            if (initFile.exists().not()) {
                initFile.createFileIfNot()
                assets.open("init-host.sh").bufferedReader().use { it.readText() }.let {
                    initFile.writeText(it)
                }
            }

            val initChrootFile: File = localBinDir().child("init-host-chroot")
            if (useChroot && initChrootFile.exists().not()) {
                initChrootFile.createFileIfNot()
                assets.open("init-host-chroot.sh").bufferedReader().use { it.readText() }.let {
                    initChrootFile.writeText(it)
                }
            }

            localBinDir().child("init").apply {
                if (exists().not()) {
                    createFileIfNot()
                    assets.open("init.sh").bufferedReader().use { it.readText() }.let {
                        writeText(it)
                    }
                }
            }

            // Build PATH with the files directory (where binaries are extracted)
            val binPath = context.filesDir.absolutePath

            val env = mutableListOf(
                "PATH=${System.getenv("PATH") ?: "/system/bin:/system/xbin"}:/sbin:${localBinDir().absolutePath}:$binPath",
                "HOME=/sdcard",
                "PUBLIC_HOME=${getExternalFilesDir(null)?.absolutePath}",
                "COLORTERM=truecolor",
                "TERM=xterm-256color",
                "LANG=C.UTF-8",
                "BIN=${localBinDir()}",
                "DEBUG=${BuildConfig.DEBUG}",
                "PREFIX=${filesDir.parentFile!!.path}",
                "LD_LIBRARY_PATH=${localLibDir().absolutePath}",
                "LINKER=${if (File("/system/bin/linker64").exists()) "/system/bin/linker64" else "/system/bin/linker"}",
                "NATIVE_LIB_DIR=${applicationInfo.nativeLibraryDir}",
                "PKG=${packageName}",
                "RISH_APPLICATION_ID=${packageName}",
                "PKG_PATH=${applicationInfo.sourceDir}",
                "PROOT_TMP_DIR=${getTempDir(this).child(sessionId).also { if (it.exists().not()) it.mkdirs() }}",
                "TMPDIR=${getTempDir(this).absolutePath}",
                "PROOT_LOADER=${applicationInfo.nativeLibraryDir}/libloader.so",
                "PROOT=${applicationInfo.nativeLibraryDir}/libproot.so",
                "CHROOT=${if (File("/system/bin/chroot").exists()) "/system/bin/chroot" else "/system/xbin/chroot"}",
                "USE_CHROOT=${if (useChroot) "1" else "0"}",
                "ALPINE_ROOT=${alpineRoot.absolutePath}"
            )

            val loader32 = "${applicationInfo.nativeLibraryDir}/libloader32.so"
            if (File(loader32).exists()) {
                env.add("PROOT_LOADER_32=$loader32")
            }

            env.addAll(envVariables.map { "${it.key}=${it.value}" })

            localDir().child("stat").apply {
                if (exists().not()) {
                    writeText(TerminalUtils.stat)
                }
            }

            localDir().child("vmstat").apply {
                if (exists().not()) {
                    writeText(TerminalUtils.vmstat)
                }
            }

            pendingCommand?.env?.let {
                env.addAll(it)
            }

            val args: Array<String>
            val shell = if (pendingCommand == null) {
                args = if (workingMode == WorkingMode.ALPINE) {
                    val targetInit = if (useChroot) initChrootFile else initFile
                    arrayOf("-c", targetInit.absolutePath)
                } else {
                    arrayOf()
                }
                "/system/bin/sh"
            } else {
                args = pendingCommand.args
                pendingCommand.shell
            }

            return ShellTermSession(
                shell,
                workingDir,
                args,
                env.toTypedArray(),
                TerminalEmulator.DEFAULT_TERMINAL_TRANSCRIPT_ROWS,
                sessionClient,
                context,
                mProcId
            )
        }
    }

    fun buildCustomPendingCommand(context: Context, custom: CustomSession): PendingCommand {
        val scriptFile = File(custom.shellPath)
        val sysSh = File("/system/bin/sh")

        val shell: String
        val args: Array<String>

        if (sysSh.canExecute()) {
            shell = sysSh.absolutePath
            args = arrayOf("-c", scriptFile.absolutePath)
        } else {
            val proot = "${context.applicationInfo.nativeLibraryDir}/libproot.so"
            shell = proot
            args = arrayOf(
                "-r", "/",
                "-b", "/dev",
                "-b", "/proc",
                "-b", "/sdcard",
                "-0",
                "sh", scriptFile.absolutePath
            )
        }

        return PendingCommand(
            shell = shell,
            args = args,
            workingDir = scriptFile.parentFile?.absolutePath ?: "/sdcard/ReTerminal",
            env = null
        )
    }
}
