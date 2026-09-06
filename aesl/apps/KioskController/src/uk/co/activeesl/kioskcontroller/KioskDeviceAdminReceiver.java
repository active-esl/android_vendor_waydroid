package uk.co.activeesl.kioskcontroller;

import android.app.admin.DeviceAdminReceiver;

/**
 * Android requires a DeviceAdminReceiver component before an app can be
 * provisioned as device owner. Policy is configured by KioskActivity only
 * after DevicePolicyManager confirms that ownership has been granted.
 */
public final class KioskDeviceAdminReceiver extends DeviceAdminReceiver {
}
