package com.trtech.expense_tracker

import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        try {
            enableEdgeToEdge()
        } catch (_: Throwable) {
            // Graceful fallback for devices or environments where enableEdgeToEdge is unsupported
        }
        super.onCreate(savedInstanceState)
    }
}
