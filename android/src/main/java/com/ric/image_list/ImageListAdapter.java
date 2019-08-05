package com.ric.image_list;

import android.graphics.Color;
import android.net.Uri;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.animation.Interpolator;
import android.widget.ImageView;

import androidx.annotation.NonNull;
import androidx.core.view.ViewCompat;
import androidx.recyclerview.widget.RecyclerView;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodChannel;


public class ImageListAdapter
        extends RecyclerView.Adapter<RecyclerView.ViewHolder> {
    private Uri[] pickerImages;
    public ArrayList<Uri> selectedImages = new ArrayList<>();
    private OnPhotoActionListener actionListener;
    private final int maxSelected;
    private final MethodChannel methodChannel;

    public ImageListAdapter(Uri[] pickerImages, int maxSelected, MethodChannel methodChannel) {
        this.methodChannel = methodChannel;
        this.pickerImages = pickerImages;
        this.maxSelected = maxSelected;
    }

    @NonNull
    @Override
    public RecyclerView.ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view;
        view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.thumb_item, parent, false);
        return new ViewHolderImage(view);
    }

    @Override
    public void onBindViewHolder(final RecyclerView.ViewHolder holder, final int position) {
        final ViewHolderImage vh = (ViewHolderImage) holder;
        final Uri image = pickerImages[position];
        vh.item.setTag(image);
        vh.btnThumbCount.unselect();
        vh.btnThumbCount.setCircleColor(Color.GREEN);
        vh.btnThumbCount.setTextColor(Color.BLACK);
        vh.btnThumbCount.setStrokeColor(Color.WHITE);

        initState(selectedImages.indexOf(image), vh);
        if (image != null
                && vh.imgThumbImage != null)
            new GlideAdapter()
                    .loadImage(vh.imgThumbImage, image);
        vh.imgThumbImage.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Boolean selected = onCheckStateChange(vh.item, image);
                Log.d("tag", "selected => " + selected);
                if (selected != null) {
                    Map<String, Object> params = new HashMap<String, Object>();
                    params.put("count", selectedImages.size());
                    methodChannel.invokeMethod("onImageTapped", params);
                }
            }
        });
    }

    private void initState(int selectedIndex, ViewHolderImage vh) {
        if (selectedIndex != -1) {
            animScale(vh.imgThumbImage, true, false, vh.overlay);
            updateRadioButton(vh.btnThumbCount, String.valueOf(selectedIndex + 1));
        } else {
            animScale(vh.imgThumbImage, false, false, vh.overlay);
        }
    }

    private Boolean onCheckStateChange(View v, Uri image) {
        ArrayList<Uri> pickedImages = selectedImages;
        boolean isContained = pickedImages.contains(image);
        if (maxSelected == pickedImages.size()
                && !isContained) {
            return null;
        }
        ImageView imgThumbImage = v.findViewById(R.id.img_thumb_image);
        RadioWithTextButton btnThumbCount = v.findViewById(R.id.btn_thumb_count);
        View overlay = v.findViewById(R.id.overlay);
        if (isContained) {
            pickedImages.remove(image);
            btnThumbCount.unselect();
        } else {
            pickedImages.add(image);
            updateRadioButton(btnThumbCount, String.valueOf(pickedImages.size()));
        }
        animScale(imgThumbImage, !isContained, true, overlay);

        return !isContained;
    }

    private void updateRadioButton(RadioWithTextButton v, String text) {
        v.setText(text);
    }

    void updateRadioButton(ImageView imageView, View overlay, RadioWithTextButton v, String text, boolean isSelected) {
        if (isSelected) {
            animScale(imageView, isSelected, false, overlay);
            v.setText(text);
        } else {
            v.unselect();
        }
    }

    private void animScale(final View view,
                           final boolean isSelected,
                           final boolean isAnimation,
                           final View overlay) {
        int duration = 100;
        if (!isAnimation) duration = 0;
        final float toScale = 0.95f;

        if (view.getTag(R.id.isViewAnimating) != null && Boolean.valueOf(view.getTag(R.id.isViewAnimating).toString()))
            return;
        final float alpha = isSelected ? 0.3f : 0.0f;

        ViewCompat.animate(view)
                .setDuration(duration)
                .withStartAction(new Runnable() {
                    @Override
                    public void run() {
                        overlay.setAlpha(alpha);
                        view.setTag(R.id.isViewAnimating, true);
                    }
                })
                .setInterpolator(new Interpolator() {
                    @Override
                    public float getInterpolation(float input) {
                        if (input <= 0.5f) {
                            return input * 2f;
                        } else {
                            return 1f - ((input - 0.5f) * 2f);
                        }
                    }
                })
                .scaleX(toScale)
                .scaleY(toScale)
                .withEndAction(new Runnable() {
                    @Override
                    public void run() {
                        view.setTag(R.id.isViewAnimating, false);
                        overlay.setAlpha(alpha);
                        if (isAnimation && !isSelected) actionListener.onDeselect();
                    }
                })
                .start();

    }

    @Override
    public int getItemCount() {
        int count;
        if (pickerImages == null) count = 0;
        else count = pickerImages.length;
        return count;
    }

    public void setActionListener(OnPhotoActionListener actionListener) {
        this.actionListener = actionListener;
    }

    public interface OnPhotoActionListener {
        void onDeselect();
    }

    public class ViewHolderImage extends RecyclerView.ViewHolder {
        View item;
        ImageView imgThumbImage;
        RadioWithTextButton btnThumbCount;
        View overlay;

        public ViewHolderImage(View view) {
            super(view);
            item = view;
            imgThumbImage = view.findViewById(R.id.img_thumb_image);
            btnThumbCount = view.findViewById(R.id.btn_thumb_count);
            overlay = view.findViewById(R.id.overlay);
        }
    }
}
