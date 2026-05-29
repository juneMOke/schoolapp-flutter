# R8/ProGuard rules for school_app_flutter.
# Keep this file minimal and add targeted rules only when a release issue is observed.

# Keep useful metadata for post-mortem diagnostics.
-keepattributes SourceFile,LineNumberTable,*Annotation*,Signature,EnclosingMethod

# Keep Flutter plugin registration entrypoint.
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
