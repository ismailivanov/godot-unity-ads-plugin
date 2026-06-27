plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.godot.unityads"
    compileSdk = 34

    defaultConfig {
        minSdk = 24
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    // Provided by the Godot engine at runtime — compile against, never bundle.
    compileOnly("org.godotengine:godot:4.3.0.stable")
    // Resolved by Godot at export time via export_plugin.gd → _get_android_dependencies.
    compileOnly("com.unity3d.ads:unity-ads:4.18.1")
}
