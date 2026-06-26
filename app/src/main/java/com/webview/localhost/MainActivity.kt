package com.webview.localhost

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Bitmap
import android.os.Bundle
import android.util.Log
import android.webkit.ConsoleMessage
import android.webkit.WebChromeClient
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.EditText
import android.widget.FrameLayout
import androidx.activity.enableEdgeToEdge
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat

class MainActivity : AppCompatActivity() {

    private lateinit var webView: WebView
    private val PREFS_NAME = "WebViewPrefs"
    private val KEY_URL = "last_url"

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContentView(R.layout.activity_main)
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main)) { v, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom)
            insets
        }

        webView = findViewById(R.id.webview)
        
        // --- ENABLE DEBUGGING FOR DEVELOPERS ---
        // 1. This allows developers to use Chrome DevTools (chrome://inspect) in their desktop browser
        WebView.setWebContentsDebuggingEnabled(true)
        
        // Essential settings for modern web apps
        webView.settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            databaseEnabled = true
            mediaPlaybackRequiresUserGesture = false
            loadWithOverviewMode = true
            useWideViewPort = true
        }

        // 2. Bridge JS console logs (console.log, console.error, etc.) to Android Logcat
        webView.webChromeClient = object : WebChromeClient() {
            override fun onConsoleMessage(consoleMessage: ConsoleMessage?): Boolean {
                consoleMessage?.apply {
                    val logMsg = "${message()} -- From line ${lineNumber()} of ${sourceId()}"
                    when (messageLevel()) {
                        ConsoleMessage.MessageLevel.ERROR -> Log.e("WebConsole", logMsg)
                        ConsoleMessage.MessageLevel.WARNING -> Log.w("WebConsole", logMsg)
                        else -> Log.d("WebConsole", logMsg)
                    }
                }
                return true
            }
        }

        webView.webViewClient = object : WebViewClient() {
            override fun onPageStarted(view: WebView?, url: String?, favicon: Bitmap?) {
                Log.d("WebView", "Started loading: $url")
            }

            override fun onPageFinished(view: WebView?, url: String?) {
                Log.d("WebView", "Finished loading: $url")
            }

            override fun onReceivedError(
                view: WebView?,
                request: WebResourceRequest?,
                error: WebResourceError?
            ) {
                Log.e("WebView", "Error: ${error?.description} (Code: ${error?.errorCode}) at ${request?.url}")
            }
        }

        showUrlInputDialog()
    }

    private fun showUrlInputDialog() {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        // Default to the emulator localhost if none is saved
        val lastUrl = prefs.getString(KEY_URL, "http://10.0.2.2:8080")

        val input = EditText(this)
        input.setText(lastUrl)
        input.setSelection(input.text.length) // Put cursor at the end

        // Add margins to the EditText for better UI
        val container = FrameLayout(this)
        val params = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.WRAP_CONTENT
        )
        val margin = (24 * resources.displayMetrics.density).toInt()
        params.setMargins(margin, margin / 4, margin, 0)
        input.layoutParams = params
        container.addView(input)

        AlertDialog.Builder(this)
            .setTitle("Developer Localhost")
            .setMessage("Enter your server address:")
            .setView(container)
            .setCancelable(false) // Force user to confirm to start the app
            .setPositiveButton("Confirm") { _, _ ->
                val url = input.text.toString().trim()
                if (url.isNotEmpty()) {
                    // Save for next session
                    prefs.edit().putString(KEY_URL, url).apply()
                    // Start loading the game
                    webView.loadUrl(url)
                }
            }
            .show()
    }
}
