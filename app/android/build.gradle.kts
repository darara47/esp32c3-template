allprojects {
    repositories {
        google()
        mavenCentral()
        // flutter_esp_ble_prov's Android side pulls Espressif's provisioning
        // SDK from here — see docs/04-firmware.md#provisioning-ble.
        maven { url = uri("https://jitpack.io") }
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

// flutter_esp_ble_prov (0.1.7, last published 2023) predates AGP's
// namespace requirement and has no active maintenance to add it — its own
// android/build.gradle has no `namespace`, which recent AGP treats as a
// hard configuration error instead of falling back to the manifest's
// `package` attribute. Reflection (not a typed BaseExtension import) keeps
// this independent of whatever AGP classpath the root project happens to
// see. Synthesizing a private namespace is the standard workaround for
// exactly this "old plugin, new AGP" situation — the value just needs to
// be unique, it doesn't need to match anything the plugin itself uses.
subprojects {
    val assignNamespaceIfMissing = {
        val android = project.extensions.findByName("android")
        val getNamespace = android?.javaClass?.methods?.find { it.name == "getNamespace" }
        val setNamespace = android?.javaClass?.methods?.find { it.name == "setNamespace" && it.parameterCount == 1 }
        if (android != null && getNamespace != null && setNamespace != null && getNamespace.invoke(android) == null) {
            val synthesized = "com.codema.ledctl.thirdparty.${project.name.replace(Regex("[^A-Za-z0-9]"), "_")}"
            setNamespace.invoke(android, synthesized)
            logger.lifecycle("Assigned missing Android namespace '$synthesized' to :${project.name}")
        }
    }
    // evaluationDependsOn(":app") above already forces some subprojects
    // through evaluation before this block runs on them — afterEvaluate()
    // throws on a project that's already past that point, so only defer
    // for the ones that aren't there yet.
    if (project.state.executed) assignNamespaceIfMissing() else afterEvaluate { assignNamespaceIfMissing() }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
