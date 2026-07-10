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

// PARCHE MAESTRO PARA LIBRERÍAS ANTIGUAS (Isar y otras)
subprojects {
    afterEvaluate {
        if (hasProperty("android")) {
            val androidExt = extensions.findByName("android")
            if (androidExt != null) {
                
                // 1. PARCHE PARA ERROR "lStar" y nuevas libs (Forzar la compilación a la API 35)
                try {
                    val compileSdkMethod = androidExt.javaClass.getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
                    compileSdkMethod.invoke(androidExt, 35)
                } catch (e: Exception) {
                    try {
                        val setCompileSdkMethod = androidExt.javaClass.getMethod("setCompileSdk", Int::class.javaObjectType)
                        setCompileSdkMethod.invoke(androidExt, 35)
                    } catch (e2: Exception) {
                        // Ignorar silenciosamente
                    }
                }

                // 2. PARCHE PARA EL NAMESPACE
                try {
                    val getNamespace = androidExt.javaClass.getMethod("getNamespace")
                    val namespace = getNamespace.invoke(androidExt)
                    if (namespace == null || namespace.toString().isEmpty()) {
                        val setNamespace = androidExt.javaClass.getMethod("setNamespace", String::class.java)
                        setNamespace.invoke(androidExt, project.group.toString())
                    }
                } catch (e: Exception) {
                    // Ignorar silenciosamente
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}