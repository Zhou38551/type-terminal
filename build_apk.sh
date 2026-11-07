#!/bin/bash
set -e

echo "========== 1. 配置环境 =========="
export ANDROID_HOME=$PWD/android-sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools

echo "========== 2. 下载并安装 Android SDK =========="
wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O cmdtools.zip
unzip -q cmdtools.zip
mkdir -p $ANDROID_HOME/cmdline-tools
mv cmdline-tools $ANDROID_HOME/cmdline-tools/latest

echo "========== 3. 接受许可并安装构建工具 =========="
yes | sdkmanager "platforms;android-34" "build-tools;34.0.0" > /dev/null 2>&1

echo "========== 4. 生成原生安卓工程 =========="
mkdir -p app/src/main/java/com/zhou38551/typeterminal
mkdir -p app/src/main/assets

if [ -d "www" ] && [ "$(ls -A www)" ]; then
    cp -r www/* app/src/main/assets/
else
    echo "ERROR: www 文件夹为空！"
    exit 1
fi

# 写入 Manifest
cat > app/src/main/AndroidManifest.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="com.zhou38551.typeterminal">
    <application android:label="Terminal Typist" android:icon="@android:drawable/sym_def_app_icon">
        <activity android:name=".MainActivity" android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF

# 写入 MainActivity
cat > app/src/main/java/com/zhou38551/typeterminal/MainActivity.java << 'EOF'
package com.zhou38551.typeterminal;
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

# 写入 Gradle 配置
cat > app/build.gradle << 'EOF'
apply plugin: 'com.android.application'
android {
    namespace 'com.zhou38551.typeterminal'
    compileSdk 34
    defaultConfig {
        applicationId "com.zhou38551.typeterminal"
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

echo "========== 5. 开始编译 APK =========="
# 直接使用系统自带的 Gradle，不再手动下载！
gradle wrapper --gradle-version 8.1.0
chmod +x ./gradlew
./gradlew assembleDebug

echo "========== 编译成功！ =========="
