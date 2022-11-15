# https://stackoverflow.com/a/62675479/13659833
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.SerializationKt
-keep,includedescriptorclasses class com.fleetingnotes.**$$serializer { *; } # <-- change package name to your app's
-keepclassmembers class com.fleetingnotes.** { # <-- change package name to your app's
    *** Companion;
}
-keepclasseswithmembers class com.fleetingnotes.** { # <-- change package name to your app's
    kotlinx.serialization.KSerializer serializer(...);
}