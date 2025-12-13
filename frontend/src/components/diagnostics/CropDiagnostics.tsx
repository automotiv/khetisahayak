import React, { useState, useEffect } from 'react';
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
  CardMedia,
  Tabs,
  Tab,
  CircularProgress,
  Divider,
  List,
  ListItem,
  ListItemIcon,
  ListItemText
} from '@mui/material';
import {
  CameraAlt,
  PhotoLibrary,
  Send,
  BugReport,
  Warning,
  CheckCircle,
  Shield
} from '@mui/icons-material';
import { formatConfidenceScore, formatDateTime } from '../../utils/formatters';
import { QueryTypes } from '../../types/schema';
import { externalApi, PestAlertData } from '../../services/api';

interface CropDiagnosticsProps {
  diagnosisHistory: QueryTypes['diagnosisHistory'];
  lat?: number;
  lon?: number;
}

const CropDiagnostics: React.FC<CropDiagnosticsProps> = ({
  diagnosisHistory,
  lat = 19.9975,
  lon = 73.7898
}) => {
  const [selectedImage, setSelectedImage] = useState<File | null>(null);
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [tabValue, setTabValue] = useState(0);

  // Pest Alerts State
  const [pestAlerts, setPestAlerts] = useState<PestAlertData | null>(null);
  const [pestLoading, setPestLoading] = useState(false);

  useEffect(() => {
    if (tabValue === 1) {
      fetchPestAlerts();
    }
  }, [tabValue, lat, lon]);

  const fetchPestAlerts = async () => {
    try {
      setPestLoading(true);
      const data = await externalApi.getPestAlerts(lat, lon);
      setPestAlerts(data);
    } catch (error) {
      console.error('Failed to fetch pest alerts:', error);
    } finally {
      setPestLoading(false);
    }
  };

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

  const getRiskColor = (risk: string) => {
    switch (risk) {
      case 'High': return 'error';
      case 'Medium': return 'warning';
      case 'Low': return 'success';
      default: return 'default';
    }
  };

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Crop Diagnostics
      </Typography>

      {/* Tabs */}
      <Tabs value={tabValue} onChange={(_, v) => setTabValue(v)} sx={{ mb: 2 }}>
        <Tab icon={<CameraAlt />} label="Disease Detection" iconPosition="start" />
        <Tab
          icon={<BugReport />}
          label={
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              Pest Alerts
              <Chip label="Live" color="success" size="small" />
            </Box>
          }
          iconPosition="start"
        />
      </Tabs>

      {/* Disease Detection Tab */}
      {tabValue === 0 && (
        <>
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
        </>
      )}

      {/* Pest Alerts Tab */}
      {tabValue === 1 && (
        <>
          {pestLoading ? (
            <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
              <CircularProgress />
            </Box>
          ) : pestAlerts ? (
            <>
              {/* Current Conditions */}
              <Card sx={{ mb: 3 }}>
                <CardContent>
                  <Typography variant="h6" gutterBottom>
                    Current Conditions
                  </Typography>
                  <Stack direction="row" spacing={3}>
                    <Box>
                      <Typography variant="caption" color="text.secondary">Temperature</Typography>
                      <Typography variant="h6">{pestAlerts.currentConditions.temperature}°C</Typography>
                    </Box>
                    <Box>
                      <Typography variant="caption" color="text.secondary">Humidity</Typography>
                      <Typography variant="h6">{pestAlerts.currentConditions.humidity}%</Typography>
                    </Box>
                    <Box>
                      <Typography variant="caption" color="text.secondary">Precipitation</Typography>
                      <Typography variant="h6">{pestAlerts.currentConditions.precipitation}mm</Typography>
                    </Box>
                  </Stack>
                </CardContent>
              </Card>

              {/* Pest Alerts */}
              {pestAlerts.alerts && pestAlerts.alerts.length > 0 ? (
                <Stack spacing={2}>
                  <Typography variant="h6">
                    <Warning color="warning" sx={{ mr: 1, verticalAlign: 'middle' }} />
                    Active Pest Alerts
                  </Typography>

                  {pestAlerts.alerts.map((alert, index) => (
                    <Alert
                      key={index}
                      severity={alert.risk === 'High' ? 'error' : alert.risk === 'Medium' ? 'warning' : 'info'}
                      icon={<BugReport />}
                    >
                      <Box>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 0.5 }}>
                          <Typography variant="subtitle2">{alert.pest}</Typography>
                          <Chip
                            label={`${alert.risk} Risk`}
                            size="small"
                            color={getRiskColor(alert.risk) as any}
                          />
                        </Box>
                        <Typography variant="body2">{alert.message}</Typography>
                        {alert.message_hi && (
                          <Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>
                            {alert.message_hi}
                          </Typography>
                        )}
                        {alert.affectedCrops && alert.affectedCrops.length > 0 && (
                          <Box sx={{ mt: 1 }}>
                            <Typography variant="caption" color="text.secondary">
                              Affected crops: {alert.affectedCrops.join(', ')}
                            </Typography>
                          </Box>
                        )}
                      </Box>
                    </Alert>
                  ))}
                </Stack>
              ) : (
                <Alert severity="success" icon={<CheckCircle />}>
                  <Typography variant="body2">
                    No pest alerts at this time. Weather conditions are favorable.
                  </Typography>
                </Alert>
              )}

              {/* Preventive Measures */}
              {pestAlerts.preventiveMeasures && pestAlerts.preventiveMeasures.length > 0 && (
                <Box sx={{ mt: 3 }}>
                  <Typography variant="h6" gutterBottom>
                    <Shield color="primary" sx={{ mr: 1, verticalAlign: 'middle' }} />
                    Preventive Measures
                  </Typography>
                  <List dense>
                    {pestAlerts.preventiveMeasures.map((measure, index) => (
                      <ListItem key={index}>
                        <ListItemIcon>
                          <CheckCircle color="success" fontSize="small" />
                        </ListItemIcon>
                        <ListItemText primary={measure} />
                      </ListItem>
                    ))}
                  </List>
                </Box>
              )}

              <Divider sx={{ my: 2 }} />
              <Typography variant="caption" color="text.secondary">
                Source: {pestAlerts.source} | Location: {pestAlerts.location.lat.toFixed(2)}°N, {pestAlerts.location.lon.toFixed(2)}°E
              </Typography>
            </>
          ) : (
            <Alert severity="warning">
              Unable to fetch pest alerts. Please try again later.
            </Alert>
          )}
        </>
      )}
    </Box>
  );
};

export default CropDiagnostics;
