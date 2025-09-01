package com.example.toolz.Notifications.service;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.service.notification.NotificationListenerService;
import android.service.notification.StatusBarNotification;
import android.util.Log;
import com.example.toolz.Notifications.database.NotificationDatabaseHelper;

public class MyNotificationListener extends NotificationListenerService {

    private static final String TAG = "MyNotificationListener";
    private NotificationDatabaseHelper dbHelper;

    // ✅ FIXED: Use modern Handler constructor with explicit Looper
    private Handler mainHandler;

    @Override
    public void onCreate() {
        super.onCreate();
        Log.d(TAG, "NotificationListenerService created");

        try {
            dbHelper = NotificationDatabaseHelper.getInstance(this);
            if (!dbHelper.isDatabaseHealthy()) {
                Log.w(TAG, "Database not healthy, attempting recovery");
                dbHelper.recoverDatabase();
            }
            mainHandler = new Handler(Looper.getMainLooper());
            Log.d(TAG, "Service initialization completed successfully");
        } catch (Exception e) {
            Log.e(TAG, "Error during service creation", e);
        }
    }


    @Override
    public void onNotificationPosted(StatusBarNotification sbn) {
        try {
            // Process notification on background thread to avoid ANR
            new Thread(() -> processNotification(sbn)).start();

        } catch (Exception e) {
            Log.e(TAG, "Error in onNotificationPosted", e);
        }
    }

    private void processNotification(StatusBarNotification sbn) {
        try {
            Notification notification = sbn.getNotification();
            String packageName = sbn.getPackageName();

            // Skip system notifications if needed
            if (isSystemNotification(packageName)) {
                return;
            }

            if (sbn.isOngoing()) {
                return;
            }

            // ✅ Safe extraction with null checks
            String title = "";
            String text = "";
            String bigText = "";

            try {
                if (notification.extras != null) {
                    CharSequence titleCs = notification.extras.getCharSequence(Notification.EXTRA_TITLE);
                    CharSequence textCs = notification.extras.getCharSequence(Notification.EXTRA_TEXT);
                    CharSequence bigTextCs = notification.extras.getCharSequence(Notification.EXTRA_BIG_TEXT);

                    title = titleCs != null ? titleCs.toString().trim() : "";
                    text = textCs != null ? textCs.toString().trim() : "";
                    bigText = bigTextCs != null ? bigTextCs.toString().trim() : text;
                }
            } catch (Exception e) {
                Log.w(TAG, "Error extracting notification text: " + e.getMessage());
            }

            // Ensure we have some content
            if (title.isEmpty() && text.isEmpty()) {
                Log.d(TAG, "Skipping notification with no content from: " + packageName);
                return;
            }

            // ✅ Validate dbHelper before using
            if (dbHelper == null) {
                Log.e(TAG, "Database helper is null, reinitializing...");
                dbHelper = NotificationDatabaseHelper.getInstance(this);
                if (dbHelper == null) {
                    Log.e(TAG, "Failed to initialize database helper");
                    return;
                }
            }

            // Get app name safely
            String appName = dbHelper.getAppNameFromPackage(packageName);


            // Get notification metadata
            String channelId = "";


            String groupName = getGroupName(notification);
            boolean isGroupSummary = (notification.flags & Notification.FLAG_GROUP_SUMMARY) != 0;
            boolean isClearable = (notification.flags & Notification.FLAG_NO_CLEAR) == 0;

            int importance = 0;
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                importance = NotificationManager.IMPORTANCE_DEFAULT;
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                channelId = notification.getChannelId();
                NotificationChannel channel = getSystemService(NotificationManager.class)
                        .getNotificationChannel(channelId);
                if (channel != null) {
                    importance = channel.getImportance();
                }
            } else {
                importance = notification.priority; // fallback
            }


            // Save to database
            long result = dbHelper.insertNotification(
                    sbn.getPostTime(),
                    packageName,
                    appName,
                    sbn.getKey(),
                    sbn.getId(),
                    title,
                    text,
                    bigText,
                    channelId,
                    notification.getGroup(),
                    groupName,
                    isGroupSummary,
                    isClearable,
                    importance
            );

            if (result > 0) {
                Log.d(TAG, "Notification saved: " + appName + " - " + title);
            } else {
                Log.w(TAG, "Failed to save notification from: " + appName);
                // Optional: Try to recover database connection
                dbHelper = NotificationDatabaseHelper.getInstance(this);
            }

        } catch (Exception e) {
            Log.e(TAG, "Error processing notification from " + (sbn != null ? sbn.getPackageName() : "unknown"), e);
        }
    }

    @Override
    public void onNotificationRemoved(StatusBarNotification sbn) {
        Log.d(TAG, "Notification removed: " + sbn.getPackageName());
        // Optional: Remove from database or mark as dismissed
    }

    private String getGroupName(Notification notification) {
        try {
            if (notification.extras != null) {
                CharSequence groupName = notification.extras.getCharSequence("android.subText");
                return groupName != null ? groupName.toString() : "";
            }
            return "";
        } catch (Exception e) {
            Log.w(TAG, "Error getting group name", e);
            return "";
        }
    }

    private boolean isSystemNotification(String packageName) {
        // Skip certain system notifications to reduce noise
        return packageName.equals("android") ||
                packageName.equals("com.android.systemui") ||
                packageName.startsWith("com.android.system");
    }

    @Override
    public void onDestroy() {
        Log.d(TAG, "NotificationListenerService destroyed");

        // Clean up handler
        if (mainHandler != null) {
            mainHandler.removeCallbacksAndMessages(null);
        }

        super.onDestroy();
    }

    @Override
    public void onListenerConnected() {
        super.onListenerConnected();
        Log.d(TAG, "NotificationListener connected");
    }

    @Override
    public void onListenerDisconnected() {
        super.onListenerDisconnected();
        Log.w(TAG, "NotificationListener disconnected");
    }
}
