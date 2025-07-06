// This is a mock for the s3.js utility file.
module.exports = {
  // Mock the upload function to return a predictable URL without actually uploading.
  uploadFileToS3: jest.fn().mockResolvedValue('https://fake-s3-url.com/diagnostics/mock-image.jpg'),
};