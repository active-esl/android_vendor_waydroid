package uk.co.activeesl.kioskcontroller;

import android.app.Activity;
import android.app.admin.DevicePolicyManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.widget.TextView;

/** Home activity and the single place where kiosk policy is enabled. */
public final class KioskActivity extends Activity {
    private DevicePolicyManager devicePolicyManager;
    private ComponentName admin;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        devicePolicyManager = (DevicePolicyManager) getSystemService(Context.DEVICE_POLICY_SERVICE);
        admin = new ComponentName(this, KioskDeviceAdminReceiver.class);
        renderStatus();
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (devicePolicyManager.isDeviceOwnerApp(getPackageName())) {
            enableKioskPolicy();
            startLockTask();
        }
    }

    private void renderStatus() {
        TextView status = new TextView(this);
        status.setGravity(Gravity.CENTER);
        status.setTextSize(20);
        status.setPadding(48, 48, 48, 48);
        status.setText(devicePolicyManager.isDeviceOwnerApp(getPackageName())
                ? R.string.managed_message : R.string.unmanaged_message);
        status.setSystemUiVisibility(View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                | View.SYSTEM_UI_FLAG_FULLSCREEN
                | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION);
        setContentView(status);
    }

    private void enableKioskPolicy() {
        devicePolicyManager.setLockTaskPackages(admin, new String[] {getPackageName()});
        devicePolicyManager.setLockTaskFeatures(admin, DevicePolicyManager.LOCK_TASK_FEATURE_NONE);
        devicePolicyManager.setStatusBarDisabled(admin, true);

        IntentFilter home = new IntentFilter(Intent.ACTION_MAIN);
        home.addCategory(Intent.CATEGORY_HOME);
        home.addCategory(Intent.CATEGORY_DEFAULT);
        devicePolicyManager.addPersistentPreferredActivity(
                admin, home, new ComponentName(this, KioskActivity.class));
    }
}
