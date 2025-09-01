package com.example.toolz.Notifications.database;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;
import android.database.sqlite.SQLiteStatement;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import java.util.concurrent.ConcurrentHashMap;

public class NotificationDatabaseHelper extends SQLiteOpenHelper {

    private static final String TAG = "NotificationDB";

    // Database configuration
    public static final String DATABASE_NAME = "notifications.db";
    private static final int DATABASE_VERSION = 1;
    public static final String TABLE_NAME = "notifications";

    // Column definitions
    public static final String COLUMN_ID = "_id";
    public static final String COLUMN_POST_TIME = "post_time";
    public static final String COLUMN_PACKAGE_NAME = "package_name";
    public static final String COLUMN_APP_NAME = "app_name";
    public static final String COLUMN_NOTIFICATION_KEY = "notification_key";
    public static final String COLUMN_NOTIFICATION_ID = "notification_id";
    public static final String COLUMN_TITLE = "title";
    public static final String COLUMN_TEXT = "text";
    public static final String COLUMN_TEXT_BIG = "text_big";
    public static final String COLUMN_CHANNEL_ID = "channel_id";
    public static final String COLUMN_GROUP_KEY = "group_key";
    public static final String COLUMN_GROUP_NAME = "group_name";
    public static final String COLUMN_IS_GROUP_SUMMARY = "is_group_summary";
    public static final String COLUMN_IS_CLEARABLE = "is_clearable";
    public static final String COLUMN_PRIORITY = "priority";

    // Table creation SQL
    private static final String SQL_CREATE_TABLE =
            "CREATE TABLE " + TABLE_NAME + " (" +
                    COLUMN_ID + " INTEGER PRIMARY KEY AUTOINCREMENT, " +
                    COLUMN_POST_TIME + " INTEGER NOT NULL, " +
                    COLUMN_PACKAGE_NAME + " TEXT NOT NULL, " +
                    COLUMN_APP_NAME + " TEXT NOT NULL, " +
                    COLUMN_NOTIFICATION_KEY + " TEXT, " +
                    COLUMN_NOTIFICATION_ID + " INTEGER, " +
                    COLUMN_TITLE + " TEXT DEFAULT '', " +
                    COLUMN_TEXT + " TEXT DEFAULT '', " +
                    COLUMN_TEXT_BIG + " TEXT DEFAULT '', " +
                    COLUMN_CHANNEL_ID + " TEXT DEFAULT '', " +
                    COLUMN_GROUP_KEY + " TEXT DEFAULT '', " +
                    COLUMN_GROUP_NAME + " TEXT DEFAULT '', " +
                    COLUMN_IS_GROUP_SUMMARY + " INTEGER DEFAULT 0, " +
                    COLUMN_IS_CLEARABLE + " INTEGER DEFAULT 1, " +
                    COLUMN_PRIORITY + " INTEGER DEFAULT 0" +
                    ");";

    // Indexes for performance
    private static final String[] SQL_CREATE_INDEXES = {
            "CREATE INDEX idx_post_time ON " + TABLE_NAME + "(" + COLUMN_POST_TIME + " DESC)",
            "CREATE INDEX idx_app_name ON " + TABLE_NAME + "(" + COLUMN_APP_NAME + ")",
            "CREATE INDEX idx_package_time ON " + TABLE_NAME + "(" + COLUMN_PACKAGE_NAME + ", " + COLUMN_POST_TIME + " DESC)"
    };

    // Singleton pattern
    private static volatile NotificationDatabaseHelper INSTANCE;
    private final Context applicationContext;

    // App name caching
    private final ConcurrentHashMap<String, String> appNameCache = new ConcurrentHashMap<>();

    // Prepared statements (ONLY for INSERT/UPDATE/DELETE)
    private volatile SQLiteStatement insertStatement;
    private volatile SQLiteStatement deleteOldStatement;

    private NotificationDatabaseHelper(@NonNull Context context) {
        super(context.getApplicationContext(), DATABASE_NAME, null, DATABASE_VERSION);
        this.applicationContext = context.getApplicationContext();
    }

    @NonNull
    public static NotificationDatabaseHelper getInstance(@NonNull Context context) {
        NotificationDatabaseHelper result = INSTANCE;
        if (result == null) {
            synchronized (NotificationDatabaseHelper.class) {
                result = INSTANCE;
                if (result == null) {
                    INSTANCE = result = new NotificationDatabaseHelper(context);
                }
            }
        }
        return result;
    }

    @Override
    public void onCreate(@NonNull SQLiteDatabase db) {
        try {
            Log.d(TAG, "Creating database schema...");

            db.beginTransaction();

            // Create table
            db.execSQL(SQL_CREATE_TABLE);

            // Create indexes
            for (String indexSql : SQL_CREATE_INDEXES) {
                db.execSQL(indexSql);
            }

            db.setTransactionSuccessful();
            Log.d(TAG, "Database schema created successfully");

        } catch (Exception e) {
            Log.e(TAG, "Error creating database schema", e);
            throw new RuntimeException("Database creation failed", e);
        } finally {
            db.endTransaction();
        }
    }

    @Override
    public void onUpgrade(@NonNull SQLiteDatabase db, int oldVersion, int newVersion) {
        Log.w(TAG, "Upgrading database from version " + oldVersion + " to " + newVersion);

        try {
            db.beginTransaction();
            db.execSQL("DROP TABLE IF EXISTS " + TABLE_NAME);
            onCreate(db);
            db.setTransactionSuccessful();
        } catch (Exception e) {
            Log.e(TAG, "Error upgrading database", e);
            throw new RuntimeException("Database upgrade failed", e);
        } finally {
            db.endTransaction();
        }
    }

    @Override
    public void onOpen(@NonNull SQLiteDatabase db) {
        super.onOpen(db);

        Log.d(TAG, "Database onOpen() called - preparing statements");

        // ✅ FIXED: Remove any SELECT queries from onOpen()
        if (!db.isReadOnly()) {
            // Only execute PRAGMA statements (these are allowed)
            try {
                db.execSQL("PRAGMA foreign_keys=ON");
                db.execSQL("PRAGMA journal_mode=WAL");
                db.execSQL("PRAGMA synchronous=NORMAL");
                db.execSQL("PRAGMA cache_size=20000");
                db.execSQL("PRAGMA temp_store=MEMORY");
            } catch (Exception e) {
                Log.e(TAG, "Error setting PRAGMA options", e);
            }
        }

        // Prepare statements
        prepareStatements(db);

        Log.d(TAG, "Statements prepared successfully");
    }

    private void prepareStatements(@NonNull SQLiteDatabase db) {
        try {
            // Close existing statements
            if (insertStatement != null) {
                insertStatement.close();
                insertStatement = null;
            }
            if (deleteOldStatement != null) {
                deleteOldStatement.close();
                deleteOldStatement = null;
            }

            // Prepare INSERT statement
            insertStatement = db.compileStatement(
                    "INSERT INTO " + TABLE_NAME + " (" +
                            COLUMN_POST_TIME + ", " + COLUMN_PACKAGE_NAME + ", " + COLUMN_APP_NAME + ", " +
                            COLUMN_NOTIFICATION_KEY + ", " + COLUMN_NOTIFICATION_ID + ", " + COLUMN_TITLE + ", " +
                            COLUMN_TEXT + ", " + COLUMN_TEXT_BIG + ", " + COLUMN_CHANNEL_ID + ", " +
                            COLUMN_GROUP_KEY + ", " + COLUMN_GROUP_NAME + ", " + COLUMN_IS_GROUP_SUMMARY + ", " +
                            COLUMN_IS_CLEARABLE + ", " + COLUMN_PRIORITY +
                            ") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
            );

            // Prepare DELETE statement
            deleteOldStatement = db.compileStatement(
                    "DELETE FROM " + TABLE_NAME + " WHERE " + COLUMN_POST_TIME + " < ?"
            );

            Log.d(TAG, "All statements prepared successfully");

        } catch (Exception e) {
            Log.e(TAG, "Error preparing statements", e);
            insertStatement = null;
            deleteOldStatement = null;
        }
    }

    // ✅ High-performance insert
    public long insertNotification(
            long postTime, @NonNull String packageName, @NonNull String appName,
            @Nullable String notificationKey, int notificationId, @NonNull String title,
            @NonNull String text, @NonNull String textBig, @NonNull String channelId,
            @NonNull String groupKey, @NonNull String groupName, boolean isGroupSummary,
            boolean isClearable, int priority) {

        SQLiteDatabase db = getWritableDatabase();
        if (db == null || !db.isOpen()) {
            Log.e(TAG, "Database is not open, reinitializing...");
            prepareStatements(db);
            if (insertStatement == null) {
                Log.e(TAG, "Failed to prepare insert statement");
                return -1;
            }
        }

        if (insertStatement == null) {
            Log.e(TAG, "Insert statement not prepared, preparing now...");
            prepareStatements(db);
            if (insertStatement == null) {
                return -1;
            }
        }

        try {
            synchronized (insertStatement) {
                insertStatement.clearBindings();

                insertStatement.bindLong(1, postTime);
                insertStatement.bindString(2, packageName);
                insertStatement.bindString(3, appName);

                if (notificationKey != null) {
                    insertStatement.bindString(4, notificationKey);
                } else {
                    insertStatement.bindNull(4);
                }

                insertStatement.bindLong(5, notificationId);
                insertStatement.bindString(6, title != null ? title : "");
                insertStatement.bindString(7, text != null ? text : "");
                insertStatement.bindString(8, textBig != null ? textBig : "");
                insertStatement.bindString(9, channelId != null ? channelId : "");
                insertStatement.bindString(10, groupKey != null ? groupKey : "");
                insertStatement.bindString(11, groupName != null ? groupName : "");
                insertStatement.bindLong(12, isGroupSummary ? 1 : 0);
                insertStatement.bindLong(13, isClearable ? 1 : 0);
                insertStatement.bindLong(14, priority);

                return insertStatement.executeInsert();
            }
        } catch (Exception e) {
            Log.e(TAG, "Insert execution failed", e);
            prepareStatements(db);
            return -1;
        }
    }

    // ✅ Delete by ID
    public int deleteNotificationById(long id) {
        SQLiteDatabase db = null;
        try {
            db = getWritableDatabase();
            int deletedRows = db.delete(TABLE_NAME, COLUMN_ID + " = ?", new String[]{String.valueOf(id)});
            Log.d(TAG, "Deleted notification with ID: " + id);
            return deletedRows;
        } catch (Exception e) {
            Log.e(TAG, "Error deleting notification by ID: " + id, e);
            return 0;
        }
    }

    // ✅ Clear all notifications
    public int clearAllNotifications() {
        SQLiteDatabase db = null;
        try {
            db = getWritableDatabase();
            int deletedCount = db.delete(TABLE_NAME, null, null);
            Log.d(TAG, "Cleared all notifications, total deleted: " + deletedCount);
            return deletedCount;
        } catch (Exception e) {
            Log.e(TAG, "Error clearing all notifications", e);
            return 0;
        } finally {
            if (db != null) db.close();
        }
    }

    // ✅ Delete old notifications
    public int deleteOldNotifications(int days) {
        if (deleteOldStatement == null) {
            Log.e(TAG, "Delete statement not prepared");
            return 0;
        }

        try {
            long cutoffTime = System.currentTimeMillis() - ((long) days * 24L * 60L * 60L * 1000L);

            synchronized (deleteOldStatement) {
                deleteOldStatement.bindLong(1, cutoffTime);
                return deleteOldStatement.executeUpdateDelete();
            }
        } catch (Exception e) {
            Log.e(TAG, "Error deleting old notifications", e);
            return 0;
        }
    }

    // ✅ FIXED: Get total count using rawQuery
    public long getTotalCount() {
        SQLiteDatabase db = null;
        Cursor cursor = null;
        try {
            db = getReadableDatabase();
            cursor = db.rawQuery("SELECT COUNT(*) FROM " + TABLE_NAME, null);

            if (cursor.moveToFirst()) {
                return cursor.getLong(0);
            }
            return 0;

        } catch (Exception e) {
            Log.e(TAG, "Error getting total count", e);
            return 0;
        } finally {
            if (cursor != null) cursor.close();
            if (db != null) db.close();
        }
    }

    // ✅ FIXED: Get old notifications count using rawQuery
    public int getOldNotificationsCount(int days) {
        SQLiteDatabase db = null;
        Cursor cursor = null;
        try {
            db = getReadableDatabase();
            long cutoffTime = System.currentTimeMillis() - ((long) days * 24L * 60L * 60L * 1000L);

            cursor = db.rawQuery(
                    "SELECT COUNT(*) FROM " + TABLE_NAME + " WHERE " + COLUMN_POST_TIME + " < ?",
                    new String[]{String.valueOf(cutoffTime)}
            );

            if (cursor.moveToFirst()) {
                return cursor.getInt(0);
            }
            return 0;

        } catch (Exception e) {
            Log.e(TAG, "Error counting old notifications", e);
            return 0;
        } finally {
            if (cursor != null) cursor.close();
            if (db != null) db.close();
        }
    }

    // ✅ Get all notifications with pagination
    public Cursor getAllNotifications(int limit, int offset) {
        SQLiteDatabase db = getReadableDatabase();
        return db.rawQuery(
                "SELECT * FROM " + TABLE_NAME + " ORDER BY " + COLUMN_POST_TIME + " DESC LIMIT ? OFFSET ?",
                new String[]{String.valueOf(limit), String.valueOf(offset)}
        );
    }

    // ✅ Search notifications
    public Cursor searchNotifications(String query, int limit) {
        SQLiteDatabase db = getReadableDatabase();
        String searchQuery = "%" + query.toLowerCase() + "%";

        return db.rawQuery(
                "SELECT * FROM " + TABLE_NAME + " WHERE " +
                        "LOWER(" + COLUMN_TITLE + ") LIKE ? OR LOWER(" + COLUMN_TEXT + ") LIKE ? " +
                        "ORDER BY " + COLUMN_POST_TIME + " DESC LIMIT ?",
                new String[]{searchQuery, searchQuery, String.valueOf(limit)}
        );
    }

    // ✅ App name caching
    @NonNull
    public String getAppNameFromPackage(@NonNull String packageName) {
        String cached = appNameCache.get(packageName);
        if (cached != null) {
            return cached;
        }

        String appName;
        try {
            PackageManager pm = applicationContext.getPackageManager();
            ApplicationInfo appInfo = pm.getApplicationInfo(packageName, 0);
            appName = pm.getApplicationLabel(appInfo).toString();
        } catch (PackageManager.NameNotFoundException e) {
            int lastDot = packageName.lastIndexOf('.');
            appName = lastDot > 0 ? packageName.substring(lastDot + 1) : packageName;
        }

        if (appNameCache.size() < 1000) {
            appNameCache.put(packageName, appName);
        }

        return appName;
    }


    // ✅ Method to validate and recover database state
    public boolean isDatabaseHealthy() {
        try {
            SQLiteDatabase db = getReadableDatabase();
            if (db == null || !db.isOpen()) {
                return false;
            }

            // Simple query to test database
            Cursor cursor = db.rawQuery("SELECT 1", null);
            if (cursor != null) {
                cursor.close();
                return true;
            }
            return false;
        } catch (Exception e) {
            Log.e(TAG, "Database health check failed", e);
            return false;
        }
    }

    // ✅ Recovery method
    public void recoverDatabase() {
        try {
            Log.w(TAG, "Attempting database recovery...");
            close();
            INSTANCE = null;
            INSTANCE = new NotificationDatabaseHelper(applicationContext);
            Log.i(TAG, "Database recovery completed");
        } catch (Exception e) {
            Log.e(TAG, "Database recovery failed", e);
        }
    }


    // ✅ Optimize database
    public void optimize() {
        SQLiteDatabase db = null;
        try {
            db = getWritableDatabase();
            db.execSQL("PRAGMA optimize");
            db.execSQL("PRAGMA wal_checkpoint(TRUNCATE)");
            Log.d(TAG, "Database optimization completed");
        } catch (Exception e) {
            Log.e(TAG, "Database optimization failed", e);
        } finally {
            if (db != null) db.close();
        }
    }

    @Override
    public void close() {
        try {
            if (insertStatement != null) insertStatement.close();
            if (deleteOldStatement != null) deleteOldStatement.close();
        } catch (Exception e) {
            Log.e(TAG, "Error closing prepared statements", e);
        }
        super.close();
    }
}
