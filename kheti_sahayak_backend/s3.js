const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const dotenv = require('dotenv');

dotenv.config();

const s3Client = new S3Client({
  region: process.env.AWS_REGION,
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  },
});

const uploadFileToS3 = async (fileBuffer, fileName, mimetype) => {
  // Check if AWS credentials are provided
  if (!process.env.AWS_ACCESS_KEY_ID || !process.env.AWS_SECRET_ACCESS_KEY || !process.env.AWS_S3_BUCKET_NAME) {
    console.warn('AWS credentials missing. Using mock S3 upload.');
    // Return a mock URL (e.g., a placeholder image or a local URL if we were serving static files)
    // For demo purposes, we'll return a random Unsplash image based on the filename hash or just a static one
    return `https://images.unsplash.com/photo-1585314062340-f1a5a7c9328d?w=400&mock=true&file=${encodeURIComponent(fileName)}`;
  }

  const uploadParams = {
    Bucket: process.env.AWS_S3_BUCKET_NAME,
    Key: fileName,
    Body: fileBuffer,
    ContentType: mimetype,
  };

  try {
    const command = new PutObjectCommand(uploadParams);
    await s3Client.send(command);
    return `https://${process.env.AWS_S3_BUCKET_NAME}.s3.${process.env.AWS_REGION}.amazonaws.com/${fileName}`;
  } catch (err) {
    console.error('Error uploading to S3:', err);
    throw new Error('Failed to upload file to S3');
  }
};

module.exports = { uploadFileToS3 };