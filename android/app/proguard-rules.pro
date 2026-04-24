# ===========================
# FLUTTER KEEP RULES
# ===========================
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# ===========================
# SHARE_PLUS KEEP RULES
# ===========================
-keep class dev.fluttercommunity.plus.share.** { *; }
-dontwarn dev.fluttercommunity.plus.share.**

# ===========================
# PLAY CORE KEEP RULES (IMPORTANT)
# ===========================
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# ===========================
# ANDROIDX / GOOGLE KEEP RULES
# ===========================
-dontwarn androidx.**
-dontwarn com.google.android.gms.**
-keep class com.crazecoder.openfile.** { *; }
-keep class androidx.core.content.FileProvider { *; }
