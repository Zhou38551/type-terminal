#!/bin/bash
set -e

# 1. 下载最纯净的安卓命令行工具
wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip -q commandlinetools-linux-11076708_latest.zip
mkdir -p android-sdk/cmdline-tools
mv cmdline-tools android-sdk/cmdline-tools/latest

# 2. 配置环境变量
export ANDROID_HOME=$PWD/android-sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools

# 3. 同意协议并下载基础构建工具
yes | sdkmanager "platforms;android-34" "build-tools;34.0.0" > /dev/null 2>&1

# 4. 创建一个极简的原生安卓工程结构
mkdir -p app/src/main/java/com/zhou38551/flowkeys
mkdir -p app/src/main/assets

# 5. 把你写好的 www 文件夹拷进安卓工程里
cp -r www/* app/src/main/assets/

# 6. 写入原生的 AndroidManifest.xml
cat > app/src/main/AndroidManifest.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="com.zhou38551.flowkeys">
    <application android:label="FlowKeys" android:icon="@android:drawable/sym_def_app_icon">
        <activity android:name=".MainActivity" android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF

# 7. 写入原生的 MainActivity.java（纯 WebView 外壳）
cat > app/src/main/java/com/zhou38551/flowkeys/MainActivity.java << 'EOF'
package com.zhou38551.flowkeys;
import android.app.Activity;
import android.os.Bundle;
import android.webkit.WebView;
public class MainActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        WebView webView = new WebView(this);
        webView.getSettings().setJavaScriptEnabled(true);
        webView.getSettings().setDomStorageEnabled(true);
        webView.loadUrl("file:///android_asset/index.html");
        setContentView(webView);
    }
}
EOF

# 8. 写入最基础的 Gradle 配置
cat > app/build.gradle << 'EOF'
apply plugin: 'com.android.application'
android {
    namespace 'com.zhou38551.flowkeys'
    compileSdk 34
    defaultConfig {
        applicationId "com.zhou38551.flowkeys"
        minSdk 24
        targetSdk 34
        versionCode 1
        versionName "1.0"
    }
}
EOF

cat > build.gradle << 'EOF'
buildscript {
    repositories { google(); mavenCentral() }
    dependencies { classpath 'com.android.tools.build:gradle:8.1.0' }
}
EOF

cat > settings.gradle << 'EOF'
include ':app'
EOF

cat > gradle.properties << 'EOF'
android.useAndroidX=true
EOF

# 9. 生成 Gradle Wrapper 并打包
gradle wrapper --gradle-version 8.1.0
./gradlew assembleDebug
