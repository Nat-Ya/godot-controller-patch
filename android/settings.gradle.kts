pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
        flatDir {
            dirs("godot-lib")
        }
    }
}

rootProject.name = "joycon-android-plugin"
include(":plugins")
project(":plugins").projectDir = file("plugins")
