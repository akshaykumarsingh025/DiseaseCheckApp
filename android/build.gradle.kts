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
    // Only redirect build directory for projects on the same drive as the root project.
    // This fixes "different roots" error when plugins are in C:\ and project is on D:\
    if (project.projectDir.absolutePath.startsWith(rootProject.rootDir.parentFile.absolutePath)) {
        val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
        project.layout.buildDirectory.value(newSubprojectBuildDir)
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

// Disable problematic unit test config tasks that fail on cross-drive setups
subprojects {
    tasks.whenTaskAdded {
        if (name.contains("generate") && name.contains("UnitTestConfig")) {
            enabled = false
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
