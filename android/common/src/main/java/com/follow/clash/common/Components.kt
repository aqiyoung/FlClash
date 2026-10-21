package com.follow.clash.common

import android.content.ComponentName

object Components {
    // Upstream's namespace, not our applicationId: the components below live in
    // com.follow.clash.* and this also prefixes the plugins' method channels.
    // Our APK id is com.threely.trinity (android/app/build.gradle.kts); matching
    // this literal to it would point every ComponentName at a class that does
    // not exist.
    const val PACKAGE_NAME = "com.follow.clash"

    val mainActivity =
        ComponentName(GlobalState.packageName, "${PACKAGE_NAME}.MainActivity")

    val quickActionActivity =
        ComponentName(GlobalState.packageName, "${PACKAGE_NAME}.QuickActionActivity")

    val serviceBroadcastReceiver =
        ComponentName(GlobalState.packageName, "${PACKAGE_NAME}.ServiceBroadcastReceiver")
}
