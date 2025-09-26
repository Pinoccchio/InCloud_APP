E/AndroidRuntime(23925): FATAL EXCEPTION: main
E/AndroidRuntime(23925): Process: com.jasfoodtrading.incloud, PID: 23925
E/AndroidRuntime(23925): java.lang.RuntimeException: Unable to instantiate activity ComponentInfo{com.jasfoodtrading.incloud/com.jasfoodtrading.incloud.MainActivity}: java.lang.ClassNotFoundException: Didn't find class "com.jasfoodtrading.incloud.MainActivity" on path: DexPathList[[zip file "/data/app/~~PKNg_o2G8ZIfkK4Wz7jBhA==/com.jasfoodtrading.incloud-0NsBWI7a4OxB2aHS4exSmw==/base.apk"],nativeLibraryDirectories=[/data/app/~~PKNg_o2G8ZIfkK4Wz7jBhA==/com.jasfoodtrading.incloud-0NsBWI7a4OxB2aHS4exSmw==/lib/arm64, /data/app/~~PKNg_o2G8ZIfkK4Wz7jBhA==/com.jasfoodtrading.incloud-0NsBWI7a4OxB2aHS4exSmw==/base.apk!/lib/arm64-v8a, /system/lib64, /system_ext/lib64]]
E/AndroidRuntime(23925): 	at android.app.ActivityThread.performLaunchActivity(ActivityThread.java:4161)
E/AndroidRuntime(23925): 	at android.app.ActivityThread.handleLaunchActivity(ActivityThread.java:4494)
E/AndroidRuntime(23925): 	at android.app.servertransaction.LaunchActivityItem.execute(LaunchActivityItem.java:123)
E/AndroidRuntime(23925): 	at android.app.servertransaction.TransactionExecutor.executeNonLifecycleItem(TransactionExecutor.java:174)
E/AndroidRuntime(23925): 	at android.app.servertransaction.TransactionExecutor.executeTransactionItems(TransactionExecutor.java:109)
E/AndroidRuntime(23925): 	at android.app.servertransaction.TransactionExecutor.execute(TransactionExecutor.java:81)
E/AndroidRuntime(23925): 	at android.app.ActivityThread$H.handleMessage(ActivityThread.java:2786)
E/AndroidRuntime(23925): 	at android.os.Handler.dispatchMessage(Handler.java:107)
E/AndroidRuntime(23925): 	at android.os.Looper.loopOnce(Looper.java:311)
E/AndroidRuntime(23925): 	at android.os.Looper.loop(Looper.java:408)
E/AndroidRuntime(23925): 	at android.app.ActivityThread.main(ActivityThread.java:9105)
E/AndroidRuntime(23925): 	at java.lang.reflect.Method.invoke(Native Method)
E/AndroidRuntime(23925): 	at com.android.internal.os.RuntimeInit$MethodAndArgsCaller.run(RuntimeInit.java:627)
E/AndroidRuntime(23925): 	at com.android.internal.os.ZygoteInit.main(ZygoteInit.java:970)
E/AndroidRuntime(23925): Caused by: java.lang.ClassNotFoundException: Didn't find class "com.jasfoodtrading.incloud.MainActivity" on path: DexPathList[[zip file "/data/app/~~PKNg_o2G8ZIfkK4Wz7jBhA==/com.jasfoodtrading.incloud-0NsBWI7a4OxB2aHS4exSmw==/base.apk"],nativeLibraryDirectories=[/data/app/~~PKNg_o2G8ZIfkK4Wz7jBhA==/com.jasfoodtrading.incloud-0NsBWI7a4OxB2aHS4exSmw==/lib/arm64, /data/app/~~PKNg_o2G8ZIfkK4Wz7jBhA==/com.jasfoodtrading.incloud-0NsBWI7a4OxB2aHS4exSmw==/base.apk!/lib/arm64-v8a, /system/lib64, /system_ext/lib64]]
E/AndroidRuntime(23925): 	at dalvik.system.BaseDexClassLoader.findClass(BaseDexClassLoader.java:259)
E/AndroidRuntime(23925): 	at java.lang.ClassLoader.loadClass(ClassLoader.java:637)
E/AndroidRuntime(23925): 	at java.lang.ClassLoader.loadClass(ClassLoader.java:573)
E/AndroidRuntime(23925): 	at android.app.AppComponentFactory.instantiateActivity(AppComponentFactory.java:95)
E/AndroidRuntime(23925): 	at androidx.core.app.CoreComponentFactory.instantiateActivity(CoreComponentFactory.java:44)
E/AndroidRuntime(23925): 	at android.app.Instrumentation.newActivity(Instrumentation.java:1452)
E/AndroidRuntime(23925): 	at android.app.ActivityThread.performLaunchActivity(ActivityThread.java:4148)
E/AndroidRuntime(23925): 	... 13 more
