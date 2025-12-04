plugins {
    id 'com.android.library'
    id 'org.jetbrains.kotlin.android'
}

android {
    namespace = "fr.natnya.joycon"
    compileSdk 34

    defaultConfig {
        minSdk 21
        targetSdk 34
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            minifyEnabled false
        }
    }
}

dependencies {
    compileOnly fileTree(dir: '../../../../../../godot/bin', include: ['godot-lib.*.aar'])
}
