allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Some plugins (e.g. file_picker) pin an older compileSdk than their own
// dependencies require. Force every Android library module to compile against
// API 36. Using plugins.withId avoids afterEvaluate timing errors.
subprojects {
    plugins.withId("com.android.library") {
        (extensions.getByName("android") as com.android.build.gradle.BaseExtension)
            .compileSdkVersion(36)
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
