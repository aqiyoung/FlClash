package com.follow.clash

/**
 * The text another app handed us through ACTION_SEND, kept here until Flutter
 * asks for it. Sharing while the app is open replaces whatever was waiting.
 */
object SharedText {
    var value: String? = null

    fun take(): String? {
        val text = value
        value = null
        return text
    }
}
