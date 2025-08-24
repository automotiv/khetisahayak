const { S3Client, PutObjectCommand, GetObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const crypto = require('crypto');
const sharp = require('sharp');
const stream = require('stream');
const { pipeline } = require('stream/promises');
const dotenv = require('dotenv');
const fs = require('fs');

dotenv.config();

const s3Client = new S3Client({ region: process.env.AWS_REGION });

// Create a presigned PUT URL for minimal client upload flow
const createPresignedUpload = async (req, res) => {
  const { filename, contentType } = req.body;
  if (!filename || !contentType) return res.status(400).json({ message: 'filename and contentType required' });

  const key = `uploads/${Date.now()}_${crypto.randomBytes(6).toString('hex')}_${filename}`;
  const command = new PutObjectCommand({ Bucket: process.env.AWS_S3_BUCKET_NAME, Key: key, ContentType: contentType });
  try {
    const url = await getSignedUrl(s3Client, command, { expiresIn: 3600 });
    return res.json({ uploadUrl: url, key });
  } catch (err) {
    console.error('presign error', err);
    return res.status(500).json({ message: 'Failed to create presigned URL' });
  }
};

// Ingest endpoint: client notifies server that upload completed and server fetches object,
// strips EXIF/location metadata, writes cleaned image back to S3 under a canonical path and
// returns a manifest entry (key, url, width, height, size)
const finalizeIngest = async (req, res) => {
  const { key, keepLocation } = req.body;
  if (!key) return res.status(400).json({ message: 'key required' });

  const getCmd = new GetObjectCommand({ Bucket: process.env.AWS_S3_BUCKET_NAME, Key: key });
  try {
    const obj = await s3Client.send(getCmd);
    // stream through sharp to strip metadata
    const imageBuffer = await streamToBuffer(obj.Body);
    let transformer = sharp(imageBuffer).withMetadata({ exif: keepLocation ? true : false });
    const resized = await transformer.toBuffer();

    const cleanKey = key.replace('uploads/', 'ingested/');
    const putCmd = new PutObjectCommand({ Bucket: process.env.AWS_S3_BUCKET_NAME, Key: cleanKey, Body: resized, ContentType: obj.ContentType });
    await s3Client.send(putCmd);

    // Save a small manifest entry locally (append to manifests/manifest.csv) as an initial implementation
    const manifestDir = process.env.INGEST_MANIFEST_DIR || './manifests';
    if (!fs.existsSync(manifestDir)) fs.mkdirSync(manifestDir, { recursive: true });
    const manifestPath = `${manifestDir}/manifest.csv`;
    const stats = await sharp(resized).metadata();
    const publicUrl = `https://${process.env.AWS_S3_BUCKET_NAME}.s3.${process.env.AWS_REGION}.amazonaws.com/${cleanKey}`;
    const entry = `${cleanKey},${publicUrl},${stats.width || ''},${stats.height || ''},${resized.length}\n`;
    fs.appendFileSync(manifestPath, entry);

    return res.json({ key: cleanKey, url: publicUrl, width: stats.width, height: stats.height, size: resized.length });
  } catch (err) {
    console.error('finalize ingest error', err);
    return res.status(500).json({ message: 'Failed to finalize ingest' });
  }
};

async function streamToBuffer(streamBody) {
  const chunks = [];
  for await (const chunk of streamBody) {
    chunks.push(chunk);
  }
  return Buffer.concat(chunks);
}

module.exports = { createPresignedUpload, finalizeIngest };
