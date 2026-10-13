// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.imagepicker;

import androidx.core.content.FileProvider;

/**
 * Providing a custom {@code FileProvider} prevents manifest {@code <provider>} name collisions.
 *
 * <p>See https://developer.android.com/guide/topics/manifest/provider-element.html for details.
 */
public class ImagePickerFileProvider extends FileProvider {
  @Override
  public android.os.ParcelFileDescriptor openFile(android.net.Uri uri, String mode)
      throws java.io.FileNotFoundException {
    try {
      java.util.List<String> parts = uri.getPathSegments();
      if (parts.size() < 5 || !parts.get(0).equals("cached_files") || !parts.get(3).equals("payload"))
        throw new java.io.IOException("invalid_owner");
      java.io.File payload = OwnedImageStore.payload(getContext(), parts.get(1), parts.get(2), "picker");
      java.io.File file = payload;
      for (int i = 4; i < parts.size(); i++) {
        String part = parts.get(i);
        if (part.isEmpty() || part.equals(".") || part.equals("..") || part.contains("/") || part.contains("\\"))
          throw new java.io.IOException("invalid_owner");
        file = new java.io.File(file, part);
      }
      if (!file.getAbsoluteFile().equals(file.getCanonicalFile()) || !file.isFile())
        throw new java.io.IOException("invalid_owner");
      return super.openFile(uri, mode);
    } catch (Exception error) { throw new java.io.FileNotFoundException("owned_picker_unavailable"); }
  }
}
