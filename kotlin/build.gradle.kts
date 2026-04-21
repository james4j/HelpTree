plugins {
    kotlin("jvm") version "2.3.10"
    application
}

repositories {
    mavenCentral()
}

dependencies {
    implementation("com.github.ajalt.clikt:clikt:5.0.3")
}

kotlin {
    jvmToolchain(25)
}

application {
    mainClass.set("helptree.examples.BasicKt")
}

fun createRunTask(name: String, mainClassName: String) {
    tasks.register<JavaExec>("run$name") {
        group = "application"
        classpath = sourceSets["main"].runtimeClasspath
        mainClass.set(mainClassName)
        args = project.findProperty("args")?.toString()?.split(" ") ?: emptyList()
    }
}

createRunTask("Basic", "helptree.examples.BasicKt")
createRunTask("Deep", "helptree.examples.DeepKt")
createRunTask("Hidden", "helptree.examples.HiddenKt")
