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

// flutter_pcm_sound 等插件仍写死 compileSdk 33，与 androidx 依赖要求冲突。
// evaluationDependsOn(":app") 会使部分子工程已 evaluate，需兼容两种时机。
subprojects {
    fun bumpLibraryCompileSdk() {
        extensions.findByType<com.android.build.gradle.LibraryExtension>()?.apply {
            if ((compileSdk ?: 0) < 36) {
                compileSdk = 36
            }
        }
    }
    if (state.executed) {
        bumpLibraryCompileSdk()
    } else {
        afterEvaluate { bumpLibraryCompileSdk() }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
