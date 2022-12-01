package com.ric.image_list;

import android.Manifest;
import android.content.Context;
import android.os.Build;
import android.widget.Toast;

import com.karumi.dexter.Dexter;
import com.karumi.dexter.MultiplePermissionsReport;
import com.karumi.dexter.PermissionToken;
import com.karumi.dexter.listener.PermissionRequest;
import com.karumi.dexter.listener.multi.MultiplePermissionsListener;

import java.util.List;

public class PermissionCheck {
    public final int PERMISSION_STORAGE = 28;
    private Context context;

    public PermissionCheck(Context context) {
        this.context = context;
    }

    public boolean CheckStoragePermission(OnPermissionChecked callback) {
        if (Build.VERSION.SDK_INT < 33) {
            Dexter.withContext(this.context)
                    .withPermissions(Manifest.permission.WRITE_EXTERNAL_STORAGE, Manifest.permission.READ_EXTERNAL_STORAGE)
                    .withListener(new MultiplePermissionsListener() {
                        @Override
                        public void onPermissionsChecked(MultiplePermissionsReport report) {
                            callback.onPermissionChecked(report);
                        }

                        @Override
                        public void onPermissionRationaleShouldBeShown(List<PermissionRequest> permissions, PermissionToken token) {
                            token.continuePermissionRequest();
                        }
                    })
                    .check();
        } else {
            Dexter.withContext(this.context)
                    .withPermissions(Manifest.permission.READ_MEDIA_IMAGES, Manifest.permission.READ_MEDIA_VIDEO)
                    .withListener(new MultiplePermissionsListener() {
                        @Override
                        public void onPermissionsChecked(MultiplePermissionsReport report) {
                            callback.onPermissionChecked(report);
                        }

                        @Override
                        public void onPermissionRationaleShouldBeShown(List<PermissionRequest> permissions, PermissionToken token) {
                            token.continuePermissionRequest();
                        }
                    })
                    .check();
        }

        return false;
    }


    public void showPermissionDialog() {
        Toast.makeText(context, R.string.msg_permission, Toast.LENGTH_SHORT).show();
    }


}
