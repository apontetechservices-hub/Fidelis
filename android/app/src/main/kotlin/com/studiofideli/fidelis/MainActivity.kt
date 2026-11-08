package com.studiofideli.fidelis

import com.ryanheise.audioservice.AudioServiceActivity

/// AudioServiceActivity links the activity to audio_service's shared
/// FlutterEngine so the background media session keeps the app alive.
class MainActivity : AudioServiceActivity()
