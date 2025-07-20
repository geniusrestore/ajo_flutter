buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Use Android Gradle Plugin compatible with Gradle 8.12
        classpath("com.android.tools.build:gradle:8.1.1")  
        // Update Kotlin version if you use Kotlin in your app
        classpath(kotlin("gradle-plugin", version = "1.8.22"))
    }
}