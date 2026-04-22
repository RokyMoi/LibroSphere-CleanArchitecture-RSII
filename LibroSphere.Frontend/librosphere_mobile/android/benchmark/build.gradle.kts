plugins {
    id("com.android.test")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.example.librosphere_mobile.benchmark"
    compileSdk = 36

    defaultConfig {
        minSdk = 28
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        testInstrumentationRunnerArguments["androidx.benchmark.suppressErrors"] =
            "EMULATOR,LOW-BATTERY"
    }

    targetProjectPath = ":app"

    experimentalProperties["android.experimental.self-instrumenting"] = true

    buildTypes {
        create("release") {
            isDebuggable = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }
}

androidComponents {
    beforeVariants(selector().all()) {
        it.enable = it.buildType == "release"
    }
}

dependencies {
    implementation("androidx.benchmark:benchmark-macro-junit4:1.3.4")
    implementation("androidx.test.ext:junit:1.2.1")
    implementation("androidx.test:runner:1.6.2")
    implementation("androidx.test.uiautomator:uiautomator:2.3.0")
}
