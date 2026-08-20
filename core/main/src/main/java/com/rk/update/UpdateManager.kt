package com.kosh.shell.update

import android.content.Context
import com.kosh.shell.libcommons.child
import com.kosh.shell.libcommons.createFileIfNot
import com.kosh.shell.libcommons.localBinDir
import java.io.File

class UpdateManager(private val context: Context) {
    fun onUpdate() {
        with(context) {
            val initFile: File = localBinDir().child("init-host")
            if (initFile.exists()) {
                initFile.delete()
            }

            if (initFile.exists().not()) {
                initFile.createFileIfNot()
                assets.open("init-host.sh").bufferedReader().use { it.readText() }.let {
                    initFile.writeText(it)
                }
            }

            val initFilex: File = localBinDir().child("init")
            if (initFilex.exists()) {
                initFilex.delete()
            }

            if (initFilex.exists().not()) {
                initFilex.createFileIfNot()
                assets.open("init.sh").bufferedReader().use { it.readText() }.let {
                    initFilex.writeText(it)
                }
            }
        }
    }
}
