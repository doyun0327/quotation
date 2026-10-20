# shared_preferences_android 2.5.x JNI looks up these Kotlin classes by name.
# R8 renames them in release builds and SharedPreferences.getInstance() crashes
# (white screen before runApp). See flutter/flutter#194649.
-keep class kotlin.Unit { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$Failure { *; }
-keep class kotlin.coroutines.Continuation { *; }
-keep class kotlin.coroutines.intrinsics.CoroutineSingletons { *; }
-keep class kotlin.coroutines.intrinsics.IntrinsicsKt { *; }
