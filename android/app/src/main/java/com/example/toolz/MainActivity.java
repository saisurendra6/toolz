package com.example.toolz;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.os.Bundle;
import android.provider.Settings;
import android.text.TextUtils;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.example.toolz.Notifications.database.NotificationDatabaseHelper;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.TimeUnit;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {

    private static final String TAG = "MainActivity";
    private static final String CHANNEL = "com.example.toolz/notification_db";

    // Optimized thread pool
    private ThreadPoolExecutor executor;
    private NotificationDatabaseHelper dbHelper;

    // Method constants
    private static final String METHOD_GET_NOTIFICATIONS = "getNotifications";
    private static final String METHOD_SEARCH_NOTIFICATIONS = "searchNotifications";
    private static final String METHOD_CLEAR_NOTIFICATIONS = "clearNotifications";
    private static final String METHOD_DELETE_NOTIFICATION = "deleteNotification";
    private static final String METHOD_GET_NOTIFICATION_COUNT = "getNotificationCount";
    private static final String METHOD_DELETE_OLD_NOTIFICATIONS = "deleteOldNotifications";
    private static final String METHOD_GET_OLD_NOTIFICATIONS_COUNT = "getOldNotificationsCount";
    private static final String METHOD_CHECK_NOTIFICATION_PERMISSION = "checkNotificationPermission";
    private static final String METHOD_REQUEST_NOTIFICATION_PERMISSION = "requestNotificationPermission";
    private static final String METHOD_GET_DB_PATH = "getDbPath";
    private static final String METHOD_OPTIMIZE_DATABASE = "optimizeDatabase";

    // Column indices cache for performance
    private static class ColumnIndices {
        final int id, postTime, packageName, appName, title, text, textBig;
        final int channelId, groupKey, isGroupSummary, isClearable, priority;

        ColumnIndices(Cursor cursor) {
            id = cursor.getColumnIndex(NotificationDatabaseHelper.COLUMN_ID);
            postTime = cursor.getColumnIndex(NotificationDatabaseHelper.COLUMN_POST_TIME);
            packageName = cursor.getColumnIndex(NotificationDatabaseHelper.COLUMN_PACKAGE_NAME);
            appName = cursor.getColumnIndex(NotificationDatabaseHelper.COLUMN_APP_NAME);
            title = cursor.getColumnIndex(NotificationDatabaseHelper.COLUMN_TITLE);
            text = cursor.getColumnIndex(NotificationDatabaseHelper.COLUMN_TEXT);
            textBig = cursor.getColumnIndex(NotificationDatabaseHelper.COLUMN_TEXT_BIG);
            channelId = cursor.getColumnIndex(NotificationDatabaseHelper.COLUMN_CHANNEL_ID);
            groupKey = cursor.getColumnIndex(NotificationDatabaseHelper.COLUMN_GROUP_KEY);
            isGroupSummary = cursor.getColumnIndex(NotificationDatabaseHelper.COLUMN_IS_GROUP_SUMMARY);
            isClearable = cursor.getColumnIndex(NotificationDatabaseHelper.COLUMN_IS_CLEARABLE);
            priority = cursor.getColumnIndex(NotificationDatabaseHelper.COLUMN_PRIORITY);
        }
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        dbHelper = NotificationDatabaseHelper.getInstance(this);

        // Optimized thread pool configuration
        executor = new ThreadPoolExecutor(
                1,                                    // Core threads (start with 1)
                3,                                    // Max threads (scale up to 3)
                60L, TimeUnit.SECONDS,               // Keep-alive
                new ArrayBlockingQueue<>(100),       // Reasonable queue size
                r -> {
                    Thread t = new Thread(r, "FlutterDB-" + System.currentTimeMillis());
                    t.setPriority(Thread.NORM_PRIORITY - 1);
                    return t;
                }
        );

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(this::handleMethodCall);
    }

    private void handleMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        try {
            switch (call.method) {
                case METHOD_GET_NOTIFICATIONS:
                    handleGetNotifications(call, result);
                    break;
                case METHOD_SEARCH_NOTIFICATIONS:
                    handleSearchNotifications(call, result);
                    break;
                case METHOD_CLEAR_NOTIFICATIONS:
                    handleClearNotifications(result);
                    break;
                case METHOD_DELETE_NOTIFICATION:
                    handleDeleteNotification(call, result);
                    break;
                case METHOD_GET_NOTIFICATION_COUNT:
                    handleGetNotificationCount(result);
                    break;
                case METHOD_DELETE_OLD_NOTIFICATIONS:
                    handleDeleteOldNotifications(call, result);
                    break;
                case METHOD_GET_OLD_NOTIFICATIONS_COUNT:
                    handleGetOldNotificationsCount(call, result);
                    break;
                case METHOD_CHECK_NOTIFICATION_PERMISSION:
                    handleCheckNotificationPermission(result);
                    break;
                case METHOD_REQUEST_NOTIFICATION_PERMISSION:
                    handleRequestNotificationPermission(result);
                    break;
                case METHOD_GET_DB_PATH:
                    handleGetDbPath(result);
                    break;
                case METHOD_OPTIMIZE_DATABASE:
                    handleOptimizeDatabase(result);
                    break;
                default:
                    result.notImplemented();
                    break;
            }
        } catch (Exception e) {
            Log.e(TAG, "Method call error: " + call.method, e);
            result.error("METHOD_ERROR", "Failed: " + call.method, e.getMessage());
        }
    }

    // ✅ FIXED: Proper pagination with validation
    // In MainActivity.java - Add null check before calling database operations
    private void handleGetNotifications(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        executor.execute(() -> {
            Cursor cursor = null;
            try {
                // ✅ ADD THIS: Ensure database is properly initialized
                if (dbHelper == null) {
                    dbHelper = NotificationDatabaseHelper.getInstance(this);
                }

                // Force database to open and prepare statements
                SQLiteDatabase db = dbHelper.getReadableDatabase();
                if (db != null) {
                    db.close(); // This ensures onOpen() is called
                }

                int limit = Math.min(Math.max(getIntArg(call, "limit", 50), 1), 200);
                int offset = Math.max(getIntArg(call, "offset", 0), 0);

                cursor = dbHelper.getAllNotifications(limit, offset);
                List<Map<String, Object>> notifications = cursorToListOptimized(cursor);

                runOnUiThread(() -> result.success(notifications));

            } catch (Exception e) {
                Log.e(TAG, "Error getting notifications", e);
                runOnUiThread(() -> result.error("GET_ERROR",
                        "Failed to get notifications", e.getMessage()));
            } finally {
                if (cursor != null) cursor.close();
            }
        });
    }


    // ✅ FIXED: Optimized search with proper limits
    private void handleSearchNotifications(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        executor.execute(() -> {
            Cursor cursor = null;
            try {
                String query = extractQueryString(call);
                if (query == null || query.trim().length() < 2) {
                    runOnUiThread(() -> result.success(new ArrayList<>()));
                    return;
                }

                int limit = Math.min(getIntArg(call, "limit", 50), 100);
                cursor = dbHelper.searchNotifications(query.trim(), limit);
                List<Map<String, Object>> notifications = cursorToListOptimized(cursor);

                runOnUiThread(() -> result.success(notifications));

            } catch (Exception e) {
                Log.e(TAG, "Error searching notifications", e);
                runOnUiThread(() -> result.error("SEARCH_ERROR",
                        "Search failed", e.getMessage()));
            } finally {
                if (cursor != null) cursor.close();
            }
        });
    }

    // ✅ FIXED: Proper bulk delete
    private void handleClearNotifications(@NonNull MethodChannel.Result result) {
        executor.execute(() -> {
            try {
                int deletedCount = dbHelper.clearAllNotifications();

                runOnUiThread(() -> {
                    Map<String, Object> response = new HashMap<>();
                    response.put("deleted_count", deletedCount);
                    response.put("success", true);
                    result.success(response);
                });

            } catch (Exception e) {
                Log.e(TAG, "Error clearing notifications", e);
                runOnUiThread(() -> result.error("CLEAR_ERROR",
                        "Failed to clear all notifications", e.getMessage()));
            }
        });
    }

    // ✅ FIXED: Implemented proper single delete
    private void handleDeleteNotification(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        executor.execute(() -> {
            try {
                Long id = getLongArg(call, "id");
                if (id == null) {
                    runOnUiThread(() -> result.error("INVALID_ARGS", "ID required", null));
                    return;
                }

                int deletedCount = dbHelper.deleteNotificationById(id);
                boolean success = deletedCount > 0;

                runOnUiThread(() -> {
                    Map<String, Object> response = new HashMap<>();
                    response.put("success", success);
                    response.put("deleted_count", deletedCount);
                    result.success(response);
                });

            } catch (Exception e) {
                Log.e(TAG, "Error deleting notification", e);
                runOnUiThread(() -> result.error("DELETE_ERROR",
                        "Failed to delete notification", e.getMessage()));
            }
        });
    }

    private void handleGetNotificationCount(@NonNull MethodChannel.Result result) {
        executor.execute(() -> {
            try {
                long count = dbHelper.getTotalCount();
                runOnUiThread(() -> result.success(count));
            } catch (Exception e) {
                Log.e(TAG, "Error getting count", e);
                runOnUiThread(() -> result.error("COUNT_ERROR", "Count failed", e.getMessage()));
            }
        });
    }

    private void handleDeleteOldNotifications(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        executor.execute(() -> {
            try {
                int days = Math.min(Math.max(getIntArg(call, "days", 30), 1), 365);
                int deletedCount = dbHelper.deleteOldNotifications(days);

                runOnUiThread(() -> {
                    Map<String, Object> response = new HashMap<>();
                    response.put("deleted_count", deletedCount);
                    response.put("days", days);
                    result.success(response);
                });

            } catch (Exception e) {
                Log.e(TAG, "Error deleting old notifications", e);
                runOnUiThread(() -> result.error("DELETE_OLD_ERROR",
                        "Failed to delete old notifications", e.getMessage()));
            }
        });
    }

    private void handleGetOldNotificationsCount(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        executor.execute(() -> {
            try {
                int days = Math.min(Math.max(getIntArg(call, "days", 30), 1), 365);
                int count = dbHelper.getOldNotificationsCount(days);

                runOnUiThread(() -> {
                    Map<String, Object> response = new HashMap<>();
                    response.put("count", count);
                    response.put("days", days);
                    result.success(response);
                });

            } catch (Exception e) {
                Log.e(TAG, "Error counting old notifications", e);
                runOnUiThread(() -> result.error("COUNT_OLD_ERROR",
                        "Failed to count old notifications", e.getMessage()));
            }
        });
    }

    private void handleCheckNotificationPermission(@NonNull MethodChannel.Result result) {
        try {
            boolean hasPermission = isNotificationServiceEnabled();
            result.success(hasPermission);
        } catch (Exception e) {
            Log.e(TAG, "Permission check failed", e);
            result.error("PERMISSION_ERROR", "Permission check failed", e.getMessage());
        }
    }

    private void handleRequestNotificationPermission(@NonNull MethodChannel.Result result) {
        try {
            Intent intent = new Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            startActivity(intent);
            result.success(true);
        } catch (Exception e) {
            Log.e(TAG, "Permission request failed", e);
            result.error("PERMISSION_REQUEST_ERROR", "Failed to open settings", e.getMessage());
        }
    }

    private void handleGetDbPath(@NonNull MethodChannel.Result result) {
        try {
            String path = getDatabasePath(NotificationDatabaseHelper.DATABASE_NAME).getAbsolutePath();
            result.success(path);
        } catch (Exception e) {
            result.error("DB_PATH_ERROR", "Failed to get path", e.getMessage());
        }
    }

    private void handleOptimizeDatabase(@NonNull MethodChannel.Result result) {
        executor.execute(() -> {
            try {
                dbHelper.optimize();
                runOnUiThread(() -> result.success(true));
            } catch (Exception e) {
                Log.e(TAG, "Database optimization failed", e);
                runOnUiThread(() -> result.error("OPTIMIZE_ERROR",
                        "Optimization failed", e.getMessage()));
            }
        });
    }

    // ✅ OPTIMIZED: Efficient cursor to list conversion
    @NonNull
    private List<Map<String, Object>> cursorToListOptimized(@Nullable Cursor cursor) {
        if (cursor == null || !cursor.moveToFirst()) {
            return new ArrayList<>();
        }

        int count = cursor.getCount();
        List<Map<String, Object>> result = new ArrayList<>(count);

        // ✅ Cache column indices for performance
        ColumnIndices indices = new ColumnIndices(cursor);

        do {
            Map<String, Object> row = new HashMap<>();

            // Use cached indices for maximum performance
            if (indices.id >= 0) row.put("id", cursor.getLong(indices.id));
            if (indices.postTime >= 0) row.put("post_time", cursor.getLong(indices.postTime));
            if (indices.packageName >= 0) row.put("package_name", cursor.getString(indices.packageName));
            if (indices.appName >= 0) row.put("app_name", cursor.getString(indices.appName));
            if (indices.title >= 0) row.put("title", cursor.getString(indices.title));
            if (indices.text >= 0) row.put("text", cursor.getString(indices.text));
            if (indices.textBig >= 0) row.put("text_big", cursor.getString(indices.textBig));
            if (indices.channelId >= 0) row.put("channel_id", cursor.getString(indices.channelId));
            if (indices.groupKey >= 0) row.put("group_key", cursor.getString(indices.groupKey));
            if (indices.isGroupSummary >= 0) row.put("is_group_summary", cursor.getInt(indices.isGroupSummary));
            if (indices.isClearable >= 0) row.put("is_clearable", cursor.getInt(indices.isClearable));
            if (indices.priority >= 0) row.put("priority", cursor.getInt(indices.priority));

            result.add(row);

        } while (cursor.moveToNext());

        return result;
    }

    // Helper methods for type-safe argument extraction
    private int getIntArg(@NonNull MethodCall call, @NonNull String key, int defaultValue) {
        Object arg = call.argument(key);
        if (arg instanceof Integer) return (Integer) arg;
        if (arg instanceof Long) return ((Long) arg).intValue();
        return defaultValue;
    }

    private Long getLongArg(@NonNull MethodCall call, @NonNull String key) {
        Object arg = call.argument(key);
        if (arg instanceof Integer) return ((Integer) arg).longValue();
        if (arg instanceof Long) return (Long) arg;
        return null;
    }

    @Nullable
    private String extractQueryString(@NonNull MethodCall call) {
        Object arg = call.arguments;
        if (arg instanceof String) return (String) arg;
        if (arg instanceof Map) {
            Object query = ((Map<?, ?>) arg).get("query");
            return query instanceof String ? (String) query : null;
        }
        return null;
    }

    private boolean isNotificationServiceEnabled() {
        String pkgName = getPackageName();
        final String flat = Settings.Secure.getString(getContentResolver(),
                "enabled_notification_listeners");
        if (!TextUtils.isEmpty(flat)) {
            final String[] names = flat.split(":");
            for (String name : names) {
                final ComponentName cn = ComponentName.unflattenFromString(name);
                if (cn != null && TextUtils.equals(pkgName, cn.getPackageName())) {
                    return true;
                }
            }
        }
        return false;
    }

    @Override
    protected void onDestroy() {
        if (executor != null && !executor.isShutdown()) {
            executor.shutdown();
            try {
                if (!executor.awaitTermination(3, TimeUnit.SECONDS)) {
                    executor.shutdownNow();
                }
            } catch (InterruptedException e) {
                executor.shutdownNow();
                Thread.currentThread().interrupt();
            }
        }
        super.onDestroy();
    }
}
