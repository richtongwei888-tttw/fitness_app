package com.tongwei.myfitness

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private var pendingAvatarPickResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            AVATAR_PICKER_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickAvatarImage" -> pickAvatarImage(result)
                else -> result.notImplemented()
            }
        }
    }

    override fun getRenderMode(): RenderMode {
        return RenderMode.texture
    }

    private fun pickAvatarImage(result: MethodChannel.Result) {
        if (pendingAvatarPickResult != null) {
            result.error("avatar_pick_in_progress", "Avatar image picking is already in progress.", null)
            return
        }

        pendingAvatarPickResult = result

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "image/*"
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
        }

        try {
            startActivityForResult(
                Intent.createChooser(intent, "选择头像"),
                AVATAR_PICKER_REQUEST_CODE
            )
        } catch (error: ActivityNotFoundException) {
            pendingAvatarPickResult = null
            result.error("avatar_picker_unavailable", "No app can pick an image.", null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == AVATAR_PICKER_REQUEST_CODE) {
            val result = pendingAvatarPickResult
            pendingAvatarPickResult = null

            if (result == null) {
                super.onActivityResult(requestCode, resultCode, data)
                return
            }

            if (resultCode != Activity.RESULT_OK) {
                result.success(null)
                return
            }

            val uri = data?.data
            if (uri == null) {
                result.success(null)
                return
            }

            try {
                val takeFlags = data.flags and Intent.FLAG_GRANT_READ_URI_PERMISSION
                if (takeFlags != 0) {
                    contentResolver.takePersistableUriPermission(uri, takeFlags)
                }
            } catch (_: SecurityException) {
                // Some providers grant temporary read access only; copying below still works.
            }

            try {
                result.success(copyPickedImageToCache(uri))
            } catch (_: Exception) {
                result.error("avatar_copy_failed", "Failed to read the selected image.", null)
            }
            return
        }

        super.onActivityResult(requestCode, resultCode, data)
    }

    private fun copyPickedImageToCache(uri: Uri): String {
        val avatarCacheDirectory = File(cacheDir, "picked_avatars")
        if (!avatarCacheDirectory.exists()) {
            avatarCacheDirectory.mkdirs()
        }

        val targetFile = File(
            avatarCacheDirectory,
            "picked_avatar_${System.currentTimeMillis()}${imageExtension(uri)}"
        )

        contentResolver.openInputStream(uri).use { inputStream ->
            requireNotNull(inputStream) { "Unable to open selected image." }
            targetFile.outputStream().use { outputStream ->
                inputStream.copyTo(outputStream)
            }
        }

        return targetFile.absolutePath
    }

    private fun imageExtension(uri: Uri): String {
        val displayName = queryDisplayName(uri)
        val nameExtension = displayName
            ?.substringAfterLast('.', missingDelimiterValue = "")
            ?.lowercase()
        if (nameExtension in SUPPORTED_IMAGE_EXTENSIONS) {
            return ".$nameExtension"
        }

        return when (contentResolver.getType(uri)) {
            "image/png" -> ".png"
            "image/webp" -> ".webp"
            "image/heic" -> ".heic"
            "image/heif" -> ".heif"
            else -> ".jpg"
        }
    }

    private fun queryDisplayName(uri: Uri): String? {
        return contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            ?.use { cursor ->
                if (!cursor.moveToFirst()) {
                    return@use null
                }
                val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (index >= 0) cursor.getString(index) else null
            }
    }

    companion object {
        private const val AVATAR_PICKER_CHANNEL = "fitness_app/avatar_picker"
        private const val AVATAR_PICKER_REQUEST_CODE = 2101
        private val SUPPORTED_IMAGE_EXTENSIONS = setOf("jpg", "jpeg", "png", "webp", "heic", "heif")
    }
}
