package com.example.toolz;

import android.content.Intent;
import android.os.Build;
import android.provider.Settings;

import androidx.annotation.NonNull;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import io.flutter.Log;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.sai.toolz";
    private static final String EVENT_CHANNEL = "com.sai.toolz/notifications";
    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        //notifications channel
//        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
//                .setMethodCallHandler((call, result)->{
//                    //
//                    if (call.method.equals("startNotificationService")) {
//                        // Return the notifications list to Flutter
//                        startNotificationService();
//                        Log.d("get noti", "called");
//                        result.success("service started");
//                    } else {
//                        result.notImplemented();
//                    }
//                });

        new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), EVENT_CHANNEL)
                .setStreamHandler(
                        new EventChannel.StreamHandler() {

                            @Override
                            public void onListen(Object arguments, EventChannel.EventSink events) {
                                //
                                Log.d("init", "sucess");
                                NotificationListener.setEventSink(events);
                            }

                            @Override
                            public void onCancel(Object arguments) {
                                //
                                NotificationListener.setEventSink(null);
                            }
                        }
                );
    }

    private void startNotificationService() {
        Intent intent = new Intent(this, NotificationListener.class);
//        Intent intent = null;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            intent = new Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS);
        }
        startService(intent);
    }

//    public static void sendNotificationEvent(Map<String, Object> notification) {
//        if(eventSink != null) {
//            eventSink.success(notification);
//        }
//    }
}
