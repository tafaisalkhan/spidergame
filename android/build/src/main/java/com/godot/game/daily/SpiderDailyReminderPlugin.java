package com.godot.game.daily;

import android.Manifest;
import android.app.Activity;
import android.app.AlarmManager;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.os.Build;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;

import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.Locale;

public final class SpiderDailyReminderPlugin extends GodotPlugin {
    private static final String NAME = "SpiderDailyReminder";
    private static final String PREFS = "spider_daily_reminder";
    private static final String CHANNEL = "daily_challenge";
    private static final String ACTION_REMIND = "com.godot.game.daily.REMIND";
    private static final int ALARM_ID = 7310;
    private static final int NOTIFICATION_ID = 7311;

    public SpiderDailyReminderPlugin(Godot godot) {
        super(godot);
    }

    @Override
    public String getPluginName() {
        return NAME;
    }

    @UsedByGodot
    public boolean remindersEnabled() {
        Activity activity = getActivity();
        return activity != null && preferences(activity).getBoolean("enabled", false) &&
                (Build.VERSION.SDK_INT < 33 ||
                        activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED);
    }

    @UsedByGodot
    public void enableReminders(boolean completedToday) {
        Activity activity = getActivity();
        if (activity == null) return;
        preferences(activity).edit().putBoolean("enabled", true).apply();
        syncReminder(completedToday);
        if (Build.VERSION.SDK_INT >= 33 &&
                activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
            activity.requestPermissions(new String[]{Manifest.permission.POST_NOTIFICATIONS}, 7312);
        }
    }

    @UsedByGodot
    public void syncReminder(boolean completedToday) {
        Activity activity = getActivity();
        if (activity == null) return;
        SharedPreferences prefs = preferences(activity);
        prefs.edit().putString("completed_day", completedToday ? dayKey() : "").apply();
        if (prefs.getBoolean("enabled", false)) scheduleNext(activity);
    }

    private static SharedPreferences preferences(Context context) {
        return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    }

    private static String dayKey() {
        return new SimpleDateFormat("yyyy-MM-dd", Locale.US).format(new Date());
    }

    private static PendingIntent alarmIntent(Context context) {
        Intent intent = new Intent(context, ReminderReceiver.class).setAction(ACTION_REMIND);
        return PendingIntent.getBroadcast(context, ALARM_ID, intent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
    }

    private static void scheduleNext(Context context) {
        AlarmManager manager = (AlarmManager) context.getSystemService(Context.ALARM_SERVICE);
        if (manager == null) return;
        Calendar next = Calendar.getInstance();
        next.set(Calendar.HOUR_OF_DAY, 18);
        next.set(Calendar.MINUTE, 0);
        next.set(Calendar.SECOND, 0);
        next.set(Calendar.MILLISECOND, 0);
        if (next.getTimeInMillis() <= System.currentTimeMillis()) next.add(Calendar.DAY_OF_YEAR, 1);
        manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next.getTimeInMillis(), alarmIntent(context));
    }

    private static void showReminder(Context context) {
        if (Build.VERSION.SDK_INT >= 33 &&
                context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) return;
        NotificationManager manager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
        if (manager == null) return;
        if (Build.VERSION.SDK_INT >= 26) {
            manager.createNotificationChannel(new NotificationChannel(CHANNEL, "Daily challenge reminders",
                    NotificationManager.IMPORTANCE_DEFAULT));
        }
        Intent launch = context.getPackageManager().getLaunchIntentForPackage(context.getPackageName());
        if (launch == null) return;
        PendingIntent openGame = PendingIntent.getActivity(context, 0, launch,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
        Notification.Builder builder = Build.VERSION.SDK_INT >= 26
                ? new Notification.Builder(context, CHANNEL) : new Notification.Builder(context);
        builder.setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle("Spider Territory daily challenge")
                .setContentText("Today's hunt is ready. Play your daily challenge!")
                .setContentIntent(openGame)
                .setAutoCancel(true);
        manager.notify(NOTIFICATION_ID, builder.build());
    }

    public static final class ReminderReceiver extends BroadcastReceiver {
        @Override
        public void onReceive(Context context, Intent intent) {
            if (!preferences(context).getBoolean("enabled", false)) return;
            if (Intent.ACTION_BOOT_COMPLETED.equals(intent.getAction())) {
                if (!dayKey().equals(preferences(context).getString("completed_day", ""))) {
                    showReminder(context);
                }
                scheduleNext(context);
            } else if (ACTION_REMIND.equals(intent.getAction())) {
                if (!dayKey().equals(preferences(context).getString("completed_day", ""))) {
                    showReminder(context);
                }
                scheduleNext(context);
            }
        }
    }
}
