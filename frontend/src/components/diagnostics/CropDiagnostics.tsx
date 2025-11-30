import React, { useState } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Button,
  Stack,
  LinearProgress,
  Chip,
  Alert,
  CardMedia
} from '@mui/material';
import { CameraAlt, PhotoLibrary, Send } from '@mui/icons-material';
import { formatConfidenceScore, formatDateTime } from '../../utils/formatters';
import { QueryTypes } from '../../types/schema';

interface CropDiagnosticsProps {
  diagnosisHistory: QueryTypes['diagnosisHistory'];
}

const CropDiagnostics: React.FC<CropDiagnosticsProps> = ({ diagnosisHistory }) => {
  const [selectedImage, setSelectedImage] = useState<File | null>(null);
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);

  const handleImageUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      setSelectedImage(file);
    }
  };

  const handleAnalyze = () => {
    if (!selectedImage) return;

    setIsAnalyzing(true);
    setUploadProgress(0);

    // Simulate upload progress
    const interval = setInterval(() => {
      setUploadProgress(prev => {
        if (prev >= 100) {
          clearInterval(interval);
          setIsAnalyzing(false);
          return 100;
        }
        return prev + 10;
      });
    }, 200);
  };

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Crop Diagnostics
      </Typography>

      {/* Image Upload Section */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Upload Crop Image
          </Typography>

          {selectedImage ? (
            <Box sx={{ mb: 2 }}>
              <img
                src={URL.createObjectURL(selectedImage)}
                alt="Selected crop"
                style={{ width: '100%', maxHeight: 200, objectFit: 'cover', borderRadius: 8 }}
              />
            </Box>
          ) : (
            <Box
              sx={{
                border: '2px dashed',
                borderColor: 'grey.300',
                borderRadius: 2,
                p: 4,
                textAlign: 'center',
                mb: 2
              }}
            >
              <Typography variant="body1" color="text.secondary">
                Select an image of your crop to analyze
              </Typography>
            </Box>
          )}

          <Stack direction="row" spacing={2} sx={{ mb: 2 }}>
            <Button
              variant="outlined"
              startIcon={<CameraAlt />}
              component="label"
              fullWidth
            >
              Take Photo
              <input
                type="file"
                accept="image/*"
                capture="environment"
                hidden
                onChange={handleImageUpload}
              />
            </Button>

            <Button
              variant="outlined"
              startIcon={<PhotoLibrary />}
              component="label"
              fullWidth
            >
              Choose from Gallery
              <input
                type="file"
                accept="image/*"
                hidden
                onChange={handleImageUpload}
              />
            </Button>
          </Stack>

          {isAnalyzing && (
            <Box sx={{ mb: 2 }}>
              <Typography variant="body2" gutterBottom>
                Analyzing image...
              </Typography>
              <LinearProgress variant="determinate" value={uploadProgress} />
            </Box>
          )}

          <Button
            variant="contained"
            startIcon={<Send />}
            onClick={handleAnalyze}
            disabled={!selectedImage || isAnalyzing}
            fullWidth
          >
            Analyze Crop
          </Button>
        </CardContent>
      </Card>

      {/* Diagnosis History */}
      <Typography variant="h6" gutterBottom>
        Recent Diagnoses
      </Typography>

      <Stack spacing={2}>
        {diagnosisHistory.map((diagnosis) => (
          <Card key={diagnosis.id}>
            <CardMedia
              component="img"
              height="140"
              image={diagnosis.imageUrl}
              alt="Crop diagnosis"
            />
            <CardContent>
              <Stack spacing={1}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <Typography variant="h6">
                    {diagnosis.diagnosis}
                  </Typography>
                  <Chip
                    label={formatConfidenceScore(diagnosis.confidence)}
                    color="success"
                    size="small"
                  />
                </Box>

                <Typography variant="body2" color="text.secondary">
                  {diagnosis.cropType} • {formatDateTime(new Date(diagnosis.uploadDate))}
                </Typography>

                <Alert severity="info" sx={{ mt: 1 }}>
                  Apply sulfur-based fungicide and ensure proper ventilation around plants.
                </Alert>
              </Stack>
            </CardContent>
          </Card>
        ))}
      </Stack>
    </Box>
  );
};

export default CropDiagnostics;