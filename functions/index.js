const {onObjectFinalized} = require("firebase-functions/v2/storage");
const {logger} = require("firebase-functions");
const admin = require("firebase-admin");
const {Storage} = require("@google-cloud/storage");
const path = require("path");
const os = require("os");
const fs = require("fs");
const ffmpeg = require("fluent-ffmpeg");
const ffmpeg_static = require("ffmpeg-static");
const ffprobe_static = require("ffprobe-static");

// Initialize Firebase Admin SDK
admin.initializeApp();
const db = admin.firestore();
const storage = new Storage();

// Set ffmpeg paths
ffmpeg.setFfmpegPath(ffmpeg_static);
ffmpeg.setFfprobePath(ffprobe_static.path);

// --- Configuration ---
const MAX_FILE_SIZE_BYTES = 100 * 1024 * 1024; // 100 MB

exports.processVideoUpload = onObjectFinalized(async (event) => {
      const object = event.data; // The event payload is different in V2
      const filePath = object.name; // e.g., 'uploads/userId/chatId/messageId.mp4'
      const contentType = object.contentType;
      const bucket = storage.bucket(object.bucket);

      // --- Exit if not a video or not in the 'uploads' folder ---
      if (!contentType.startsWith("video/") || !filePath.startsWith("uploads/")) {
        return logger.log("Not a video or not in uploads folder. Exiting.");
      }

      // --- 1. Validate File Size ---
      if (object.size > MAX_FILE_SIZE_BYTES) {
        logger.error(
            `File too large: ${object.size} bytes. Deleting.`,
        );
        await bucket.file(filePath).delete();
        return logger.log("Deleted oversized file.");
      }

      // Correctly parse chatId and messageId from the file path
      const pathParts = filePath.split("/");
      const chatId = pathParts[2];
      const fileName = pathParts[3];
      const messageId = path.basename(fileName, path.extname(fileName));

      const tempFilePath = path.join(os.tmpdir(), fileName);
      const tempThumbnailPath = path.join(os.tmpdir(), `thumb_${path.basename(fileName, path.extname(fileName))}.jpg`);

      try {
        // Download video to temp directory
        await bucket.file(filePath).download({destination: tempFilePath});
        logger.log("Video downloaded to", tempFilePath);

        // --- 2. Get Aspect Ratio & 3. Generate Thumbnail ---
        const aspectRatio = await getVideoAspectRatio(tempFilePath);
        await generateThumbnail(tempFilePath, tempThumbnailPath);
        logger.log("Thumbnail created at", tempThumbnailPath);

        // --- 4. Upload new files and get public URLs ---
        const permanentVideoPath = `chat_media/${chatId}/${messageId}.mp4`;
        const permanentThumbPath = `chat_media/${chatId}/${messageId}_thumb.jpg`;

        const [videoUploadResponse] = await bucket.upload(tempFilePath, {
          destination: permanentVideoPath,
          metadata: {contentType: "video/mp4"},
        });
        const [thumbUploadResponse] = await bucket.upload(tempThumbnailPath, {
          destination: permanentThumbPath,
          metadata: {contentType: "image/jpeg"},
        });

        const videoUrl = await videoUploadResponse.getSignedUrl({
          action: "read",
          expires: "03-09-2491",
        }).then((urls) => urls[0]);

        const thumbnailUrl = await thumbUploadResponse.getSignedUrl({
          action: "read",
          expires: "03-09-2491",
        }).then((urls) => urls[0]);

        // --- 5. Create Firestore message document ---
        const messageRef = db.collection("chats").doc(chatId)
            .collection("messages").doc(messageId);

        await messageRef.update({
          videoUrl: videoUrl,
          thumbnailUrl: thumbnailUrl,
          aspectRatio: aspectRatio,
          status: "complete", // Update status from 'uploading' to 'complete'
        });
        logger.log("Firestore document updated:", messageRef.path);

        // --- 6. Cleanup ---
        await bucket.file(filePath).delete(); // Delete original from uploads/
        fs.unlinkSync(tempFilePath); // Delete local temp files
        fs.unlinkSync(tempThumbnailPath);

        return logger.log("Processing complete.");
      } catch (error) {
        logger.error("Error processing video:", error);
        // If something fails, update the message status to 'failed'
        const messageRef = db.collection("chats").doc(chatId)
            .collection("messages").doc(messageId);
        await messageRef.update({status: "failed"});
        return null;
      }
    });

/**
 * Extracts the aspect ratio of a video file.
 * @param {string} filePath Local path to the video file.
 * @return {Promise<number>} The aspect ratio (width / height).
 */
function getVideoAspectRatio(filePath) {
  return new Promise((resolve, reject) => {
    ffmpeg.ffprobe(filePath, (err, metadata) => {
      if (err) {
        reject(err);
        return;
      }
      const stream = metadata.streams.find((s) => s.codec_type === "video");
      if (!stream) {
        reject(new Error("No video stream found"));
        return;
      }
      const aspectRatio = stream.width / stream.height;
      resolve(aspectRatio);
    });
  });
}

/**
 * Generates a thumbnail from a video file.
 * @param {string} inputPath Local path to the input video.
 * @param {string} outputPath Local path to save the output thumbnail.
 * @return {Promise<void>}
 */
function generateThumbnail(inputPath, outputPath) {
  return new Promise((resolve, reject) => {
    ffmpeg(inputPath)
        .on("end", () => resolve())
        .on("error", (err) => reject(err))
        .screenshots({
          count: 1,
          timemarks: ["00:00:00.000"],
          filename: path.basename(outputPath),
          folder: path.dirname(outputPath),
        });
  });
}

/**
 * Cloud Function to process uploaded videos.
 *
 * This function is triggered when a new video is uploaded to the
 * 'uploads/{userId}/{chatId}/{messageId}.mp4' path in Cloud Storage.
 *
 * It performs the following actions:
 * 1. Validates the video file size.
 * 2. Generates a thumbnail from the first frame of the video.
 * 3. Extracts the video's aspect ratio.
 * 4. Moves the video and thumbnail to a permanent 'chat_media/' location.
 * 5. Creates a new message document in Firestore with video/thumbnail URLs
 *    and aspect ratio.
 * 6. Deletes the original uploaded file.
 */
// TODO: Implement the function logic here 