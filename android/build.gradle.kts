allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// ← يحل lStar: يُجبر كل plugins المكتبات على compileSdk=35
//   whenPluginAdded يعمل قبل التقييم (بعكس afterEvaluate الذي يفشل)
subprojects {
    plugins.whenPluginAdded {
        if (this is com.android.build.gradle.LibraryPlugin) {
            extensions.getByType<com.android.build.gradle.LibraryExtension>().apply {
                compileSdk = 35
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

