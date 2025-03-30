package com.example.toolz;

import android.app.Notification;
import android.os.Build;
import android.os.Bundle;
import android.service.notification.NotificationListenerService;
import android.service.notification.StatusBarNotification;

import androidx.core.app.NotificationCompat;

import org.json.JSONObject;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.time.LocalDateTime;
import java.util.Date;

import io.flutter.plugin.common.EventChannel;

public class NotificationListener extends NotificationListenerService {

    private static EventChannel.EventSink eventSink;
    public static void setEventSink(EventChannel.EventSink sink) {
        eventSink = sink;
    }

    @Override
    public void onNotificationPosted(StatusBarNotification sbn) {
        super.onNotificationPosted(sbn);

        if (sbn.isOngoing()) {
            return;
        }

        try {

            JSONObject jsonObject = new JSONObject();

            String tickerText = "", title = "", titleBig = "", text = "", textBig = "", textInfo = "", textSub = "", textSummary = "", textLines = "";
            Notification notification = sbn.getNotification();
            String packageName = sbn.getPackageName(),
                    postTime = String.valueOf(sbn.getPostTime()),
                    isClearable = String.valueOf(sbn.isClearable()),
                    id = String.valueOf(sbn.getId()), tag = "" + sbn.getTag(),
                    key = sbn.getKey(), sortKey = "" + notification.getSortKey();


            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                jsonObject.put("isGroup", String.valueOf(sbn.isGroup()));
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                jsonObject.put("isAppGroup", String.valueOf(sbn.isAppGroup()));
            }
            jsonObject.put("groupKey", "" + sbn.getGroupKey());

//        jsonObject.put("data", sbn.toString());
//        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
//            jsonObject.put("channelId", "" + notification.getChannelId());
//            jsonObject.put("group", "" + notification.getGroup());
//        }
//        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
//            jsonObject.put("smallIcon", notification.getSmallIcon());
//            jsonObject.put("largeIcon", notification.getLargeIcon());
//        }

            Bundle extras = NotificationCompat.getExtras(notification);

            tickerText = nullToEmptyString(notification.tickerText);
            if (extras != null) {
                title = nullToEmptyString(extras.getCharSequence(NotificationCompat.EXTRA_TITLE));
                titleBig = nullToEmptyString(extras.getCharSequence(NotificationCompat.EXTRA_TITLE_BIG));
                text = nullToEmptyString(extras.getCharSequence(NotificationCompat.EXTRA_TEXT));
                textBig = nullToEmptyString(extras.getCharSequence(NotificationCompat.EXTRA_BIG_TEXT));
                textInfo = nullToEmptyString(extras.getCharSequence(NotificationCompat.EXTRA_INFO_TEXT));
                textSub = nullToEmptyString(extras.getCharSequence(NotificationCompat.EXTRA_SUB_TEXT));
                textSummary = nullToEmptyString(extras.getCharSequence(NotificationCompat.EXTRA_SUMMARY_TEXT));

                CharSequence[] lines = extras.getCharSequenceArray(NotificationCompat.EXTRA_TEXT_LINES);
                if (lines != null) {
                    for (CharSequence line : lines) {
                        textLines += line + "\n";
                    }
                    textLines = textLines.trim();
                }

            }

            jsonObject.put("title", title);
            jsonObject.put("titleBig", titleBig);
            jsonObject.put("text", text);
            jsonObject.put("textBig", textBig);
            jsonObject.put("textInfo", textInfo);
            jsonObject.put("textSub", textSub);
            jsonObject.put("textSummary", textSummary);
            jsonObject.put("textLines", textLines);
            jsonObject.put("tickerText", tickerText);
            jsonObject.put("packageName", packageName);
            jsonObject.put("postTime", postTime);
            jsonObject.put("isClearable", isClearable);
            jsonObject.put("id", id);
            jsonObject.put("key", key);
            jsonObject.put("tag", tag);
            jsonObject.put("sortKey", sortKey);
            jsonObject.put("group", "" + notification.getGroup());

            String fileName = "";
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                fileName = String.valueOf(LocalDateTime.now());
            } else  {
                fileName = String.valueOf(System.currentTimeMillis());
            }
            saveToAndroidDataFolder(postTime + ".txt", jsonObject.toString());

            if (eventSink != null) {
                eventSink.success(true);
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

    }

    void handleNotification(StatusBarNotification sbn) {
    }

    String nullToEmptyString(CharSequence charsequence) {
        if (charsequence == null) {
            return "";
        } else {
            return charsequence.toString();
        }
    }

    public void saveToAndroidDataFolder(String fileName, String fileContent) {
        // Get the app-specific directory
        File folder = new File(getFilesDir(), "notification_history");
        if(!folder.exists()) {
            folder.mkdir();
        }
        if (folder.exists()) {
            File file = new File(folder, fileName);

            FileOutputStream fos = null;
            try {
                // Write the content to the file
                fos = new FileOutputStream(file);
                fos.write(fileContent.getBytes());
                fos.close();

                System.out.println("File saved to: " + file.getAbsolutePath());
            } catch (IOException e) {
                e.printStackTrace();
            } finally {
                if (fos != null) {
                    try {
                        fos.close();
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }
            }
        } else {
            System.out.println("Unable to access external files directory.");
        }
    }
}
