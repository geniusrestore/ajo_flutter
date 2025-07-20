allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Optional: Custom build directory (uncomment if needed for CI/CD or mono-repo setup)
// val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
// rootProject.layout.buildDirectory.set(newBuildDir)

// subprojects {
//     val newSubprojectBuildDir = newBuildDir.dir(name)
//     layout.buildDirectory.set(newSubprojectBuildDir)
//     evaluationDependsOn(":app")
// }

// Ensure all subprojects evaluate the app module
subprojects {
    evaluationDependsOn(":app")
}

// Clean task to delete build outputs
tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}