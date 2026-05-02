package com.healthcheck.disease_check_app

import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import com.google.ai.edge.litertlm.Backend
import com.google.ai.edge.litertlm.Engine
import com.google.ai.edge.litertlm.EngineConfig
import com.google.ai.edge.litertlm.Conversation
import com.google.ai.edge.litertlm.ConversationConfig
import com.google.ai.edge.litertlm.SamplerConfig
import com.google.ai.edge.litertlm.Contents
import com.google.ai.edge.litertlm.Content
import com.google.ai.edge.litertlm.LogSeverity

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.healthcheck.gemma"
    private var engine: Engine? = null
    private val scope = CoroutineScope(Dispatchers.Main)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "initializeModel" -> {
                        val modelPath = call.argument<String>("modelPath") ?: ""
                        initializeModel(modelPath, result)
                    }
                    "generateText" -> {
                        val prompt = call.argument<String>("prompt") ?: ""
                        generateText(prompt, result)
                    }
                    "closeModel" -> {
                        closeModel()
                        result.success(null)
                    }
                    "startForegroundDownload" -> {
                        DownloadForegroundService.start(this)
                        result.success(null)
                    }
                    "updateForegroundProgress" -> {
                        val progress = call.argument<Int>("progress") ?: 0
                        val text = call.argument<String>("text") ?: "Downloading..."
                        DownloadForegroundService.updateProgress(this, progress, text)
                        result.success(null)
                    }
                    "stopForegroundDownload" -> {
                        DownloadForegroundService.stop(this)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun initializeModel(modelPath: String, result: MethodChannel.Result) {
        scope.launch {
            try {
                if (engine != null) {
                    Log.d("AIEngine", "Engine already initialized")
                    withContext(Dispatchers.Main) { result.success(true) }
                    return@launch
                }

                Log.d("AIEngine", "Loading model from: $modelPath")

                val engineResult = withContext(Dispatchers.IO) {
                    try {
                        Engine.setNativeMinLogSeverity(LogSeverity.ERROR)

                        val engineConfig = EngineConfig(
                            modelPath = modelPath,
                            backend = Backend.CPU(),
                            cacheDir = context.cacheDir.absolutePath,
                        )

                        val newEngine = Engine(engineConfig)
                        Log.d("AIEngine", "Engine created, calling initialize...")
                        newEngine.initialize()
                        Log.d("AIEngine", "Engine initialized successfully")

                        engine = newEngine
                        true
                    } catch (e: Exception) {
                        Log.e("AIEngine", "Engine init failed", e)
                        engine = null
                        false
                    }
                }

                Log.d("AIEngine", "Init result: $engineResult")
                withContext(Dispatchers.Main) { result.success(engineResult) }
            } catch (e: Exception) {
                Log.e("AIEngine", "Failed to initialize model", e)
                engine = null
                withContext(Dispatchers.Main) { result.success(false) }
            }
        }
    }

    private fun generateText(prompt: String, result: MethodChannel.Result) {
        scope.launch {
            try {
                if (engine == null) {
                    Log.e("AIEngine", "Engine not initialized when generateText called")
                    withContext(Dispatchers.Main) {
                        result.error("NOT_INITIALIZED", "AI model not initialized. Please restart the app.", null)
                    }
                    return@launch
                }

                Log.d("AIEngine", "Generating text, prompt length: ${prompt.length}")

                val response = withContext(Dispatchers.IO) {
                    try {
                        var conversation: Conversation? = null
                        try {
                            val conversationConfig = ConversationConfig(
                                samplerConfig = SamplerConfig(
                                    topK = 40,
                                    topP = 0.95,
                                    temperature = 0.7,
                                ),
                            )
                            conversation = engine!!.createConversation(conversationConfig)
                            val msg = conversation.sendMessage(prompt)
                            val text = msg.toString()
                            Log.d("AIEngine", "Got response, length: ${text.length}")
                            text
                        } finally {
                            conversation?.close()
                        }
                    } catch (e: Exception) {
                        Log.e("AIEngine", "Generation failed", e)
                        null
                    }
                }

                withContext(Dispatchers.Main) {
                    if (response != null) {
                        result.success(response)
                    } else {
                        result.error("GENERATION_FAILED", "AI generation failed. Please try again.", null)
                    }
                }
            } catch (e: Exception) {
                Log.e("AIEngine", "Failed to generate text", e)
                withContext(Dispatchers.Main) {
                    result.error("GENERATION_FAILED", e.message, null)
                }
            }
        }
    }

    private fun closeModel() {
        try {
            engine?.close()
        } catch (e: Exception) {
            Log.e("AIEngine", "Error closing model", e)
        } finally {
            engine = null
        }
    }

    override fun onDestroy() {
        closeModel()
        super.onDestroy()
    }
}
