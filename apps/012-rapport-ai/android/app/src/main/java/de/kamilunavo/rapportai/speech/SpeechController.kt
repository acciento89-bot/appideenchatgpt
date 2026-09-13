package de.kamilunavo.rapportai.speech

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer

class SpeechController(
    context: Context,
    private val onText: (String) -> Unit,
    private val onRecording: (Boolean) -> Unit,
    private val onError: (String) -> Unit
) : RecognitionListener {
    private val handler = Handler(Looper.getMainLooper())
    private val recognizer = SpeechRecognizer.createSpeechRecognizer(context)
    private var running = false
    private var committed = ""
    private var lastSegment = ""

    private val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
        putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
        putExtra(RecognizerIntent.EXTRA_LANGUAGE, "de-DE")
        putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
        putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 3)
        putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 1_500L)
        putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, 900L)
    }

    init { recognizer.setRecognitionListener(this) }

    fun start(existingText: String) {
        if (running) return
        committed = existingText.trim()
        lastSegment = ""
        running = true
        onRecording(true)
        listen()
    }

    fun stop() {
        if (!running) return
        running = false
        handler.removeCallbacksAndMessages(null)
        recognizer.stopListening()
        onRecording(false)
    }

    fun destroy() {
        running = false
        handler.removeCallbacksAndMessages(null)
        recognizer.destroy()
    }

    private fun listen() {
        if (!running) return
        runCatching { recognizer.startListening(intent) }.onFailure {
            running = false
            onRecording(false)
            onError("Die Spracherkennung konnte nicht gestartet werden.")
        }
    }

    private fun restart() {
        if (running) handler.postDelayed({ listen() }, 300)
    }

    private fun combined(partial: String): String = listOf(committed, partial.trim())
        .filter { it.isNotBlank() }.joinToString(" ")

    override fun onPartialResults(partialResults: Bundle?) {
        val partial = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull().orEmpty()
        if (partial.isNotBlank()) onText(combined(partial))
    }

    override fun onResults(results: Bundle?) {
        val segment = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull()?.trim().orEmpty()
        val normalized = segment.lowercase().replace(Regex("\\s+"), " ")
        if (segment.isNotBlank() && normalized != lastSegment) {
            committed = combined(segment)
            lastSegment = normalized
            onText(committed)
        }
        restart()
    }

    override fun onError(error: Int) {
        if (!running) return
        if (error == SpeechRecognizer.ERROR_NO_MATCH || error == SpeechRecognizer.ERROR_SPEECH_TIMEOUT || error == SpeechRecognizer.ERROR_CLIENT) {
            restart()
        } else {
            running = false
            onRecording(false)
            onError("Die Spracherkennung wurde unterbrochen. Bitte erneut starten.")
        }
    }

    override fun onReadyForSpeech(params: Bundle?) = Unit
    override fun onBeginningOfSpeech() = Unit
    override fun onRmsChanged(rmsdB: Float) = Unit
    override fun onBufferReceived(buffer: ByteArray?) = Unit
    override fun onEndOfSpeech() = Unit
    override fun onEvent(eventType: Int, params: Bundle?) = Unit
}
