package com.brainhealth.memorygame

import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.WindowInsetsController
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Enable edge-to-edge display using modern approach for Android 15+
        setupEdgeToEdgeDisplay()
    }
    
    private fun setupEdgeToEdgeDisplay() {
        when {
            // Android 15+ (API 35+) - Use enableEdgeToEdge() as recommended by Google
            Build.VERSION.SDK_INT >= 35 -> {
                setupAndroid15EdgeToEdge()
            }
            // Android 11+ (API 30+) - Use WindowInsetsController
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.R -> {
                setupModernEdgeToEdge()
            }
            // Android 10 (API 29) - Use system UI flags
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q -> {
                setupLegacyEdgeToEdge()
            }
            // Older versions - Basic setup
            else -> {
                setupBasicEdgeToEdge()
            }
        }
        
        // Setup window insets handling for proper content layout
        setupWindowInsetsHandling()
    }
    
    private fun setupAndroid15EdgeToEdge() {
        // For Android 15+, use WindowCompat approach with proper configuration
        WindowCompat.setDecorFitsSystemWindows(window, false)
        
        // Configure system bars for optimal edge-to-edge display
        window.insetsController?.let { controller ->
            // Configure system bars appearance for better contrast
            controller.setSystemBarsAppearance(
                0, // Clear all flags for transparent bars
                WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS or 
                WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS
            )
        }
        
        // Set transparent colors for edge-to-edge experience
        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = Color.TRANSPARENT
    }
    
    private fun setupModernEdgeToEdge() {
        // For Android 11-14, use WindowCompat approach
        WindowCompat.setDecorFitsSystemWindows(window, false)
        
        window.insetsController?.let { controller ->
            controller.setSystemBarsAppearance(
                0,
                WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS or 
                WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS
            )
        }
        
        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = Color.TRANSPARENT
    }
    
    @Suppress("DEPRECATION")
    private fun setupLegacyEdgeToEdge() {
        // For Android 10, use WindowCompat with system UI flags fallback
        WindowCompat.setDecorFitsSystemWindows(window, false)
        
        window.decorView.systemUiVisibility = (
            View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
            View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
            View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
        )
        
        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = Color.TRANSPARENT
    }
    
    @Suppress("DEPRECATION")
    private fun setupBasicEdgeToEdge() {
        // For older Android versions, use WindowCompat with basic setup
        WindowCompat.setDecorFitsSystemWindows(window, false)
        
        window.decorView.systemUiVisibility = (
            View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
            View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
        )
        
        window.statusBarColor = Color.TRANSPARENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            window.navigationBarColor = Color.TRANSPARENT
        }
    }
    
    private fun setupWindowInsetsHandling() {
        // For Flutter apps, we need to let Flutter handle the insets
        // but ensure proper edge-to-edge display setup
        val rootView = findViewById<View>(android.R.id.content)
        rootView?.let { view ->
            ViewCompat.setOnApplyWindowInsetsListener(view) { v, insets ->
                // Let Flutter handle the insets by not consuming them
                // This ensures Flutter's own inset handling works properly
                insets
            }
        }
        
        // Ensure the Flutter view can extend to edges
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // For Android 11+, ensure proper window insets behavior
            window.setDecorFitsSystemWindows(false)
        }
    }
}