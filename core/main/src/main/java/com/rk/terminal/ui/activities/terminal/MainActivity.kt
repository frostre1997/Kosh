package com.rk.terminal.ui.activities.terminal

import android.content.pm.PackageManager
import android.graphics.Rect
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.WindowManager
import android.view.inputmethod.InputMethodManager
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.viewModels
import androidx.compose.material3.Surface
import androidx.compose.runtime.*
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.core.content.ContextCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.rk.terminal.ui.navHosts.MainActivityNavHost
import com.rk.terminal.ui.routes.MainActivityRoutes
import com.rk.terminal.ui.screens.terminal.TerminalViewModel
import com.rk.terminal.ui.theme.KarbonTheme

class MainActivity : ComponentActivity() {
    val viewModel: MainViewModel by viewModels()
    private val terminalViewModel: TerminalViewModel by viewModels()
    private var isKeyboardVisible = false
    private var wasKeyboardOpen = false

    private val requestNotificationPermission =
        registerForActivityResult(ActivityResultContracts.RequestPermission()) { isGranted ->
            if (!isGranted) {
                // Optional: Handle permission denied
            }
        }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Force fullscreen after layout is ready
        window.decorView.post {
            window.addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)
            window.addFlags(WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS)
            hideSystemBars()
        }
        
        // Re-hide bars if they become visible (e.g., swipe from top)
        window.decorView.setOnSystemUiVisibilityChangeListener { visibility ->
            if (visibility and View.SYSTEM_UI_FLAG_FULLSCREEN == 0) {
                hideSystemBars()
            }
        }

        // 1. Configure the window for immersive edge-to-edge content
        WindowCompat.setDecorFitsSystemWindows(window, false)
        
        // 2. Hide both the navigation and status bars cleanly
        hideSystemBars()

        requestPermission()

        if (intent.hasExtra("awake_intent")) {
            moveTaskToBack(true)
        }

        setContent {
            KarbonTheme {
                Surface {
                    val navController = rememberNavController()
                    if (viewModel.isBound) {
                        MainActivityNavHost(
                            navController = navController,
                            mainActivity = this@MainActivity
                        )
                    }

                    val backStackEntry by navController.currentBackStackEntryAsState()
                    val focusManager = LocalFocusManager.current
                    val keyboardController = LocalSoftwareKeyboardController.current

                    LaunchedEffect(backStackEntry?.destination?.route) {
                        if (backStackEntry?.destination?.route != MainActivityRoutes.MainScreen.route) {
                            focusManager.clearFocus(force = true)
                            terminalViewModel.terminalView?.clearFocus()
                            keyboardController?.hide()
                        }
                    }
                }
            }
        }
        
        setupKeyboardListener()
    }

    override fun onStart() {
        super.onStart()
        viewModel.startAndBindService(this)
    }

    override fun onStop() {
        super.onStop()
        viewModel.unbindService(this)
    }

    override fun onPause() {
        super.onPause()
        wasKeyboardOpen = isKeyboardVisible
    }

    override fun onResume() {
        window.decorView.post { hideSystemBars() }
        super.onResume()
        // 3. Ensure bars remain hidden when re-focusing or returning to the terminal
        hideSystemBars()

        if (wasKeyboardOpen && !isKeyboardVisible) {
            terminalViewModel.terminalView?.let { terminalView ->
                val imm = getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager
                imm.showSoftInput(terminalView, InputMethodManager.SHOW_IMPLICIT)
            }
        }
    }

    // Helper method handling the modern full-screen logic
    private fun hideSystemBars() {
        WindowCompat.getInsetsController(window, window.decorView).apply {
            // Re-hides the bars automatically after a user swipes them into view
            systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            // Hides both the status bar and navigation bar
            hide(WindowInsetsCompat.Type.systemBars())
        }
    }

    private fun requestPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(
                    this,
                    android.Manifest.permission.POST_NOTIFICATIONS
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                requestNotificationPermission.launch(android.Manifest.permission.POST_NOTIFICATIONS)
            }
        }
    }

    private fun setupKeyboardListener() {
        val rootView = findViewById<View>(android.R.id.content)
        rootView.viewTreeObserver.addOnGlobalLayoutListener {
            val rect = Rect()
            rootView.getWindowVisibleDisplayFrame(rect)
            val screenHeight = rootView.rootView.height
            val keypadHeight = screenHeight - rect.bottom
            isKeyboardVisible = keypadHeight > screenHeight * 0.15
        }
    }
}
