import React from 'react';
import { Box, Typography, Card, CardContent, Stack, Button, Alert } from '@mui/material';
import { TrendingUp, Notifications, LocalHospital, School } from '@mui/icons-material';
import WeatherCard from '../weather/WeatherCard';
import { QueryTypes } from '../../types/schema';
import { formatDateTime } from '../../utils/formatters';

interface DashboardProps {
  weatherData: QueryTypes['weatherData'];
  diagnosisHistory: QueryTypes['diagnosisHistory'];
  userName: string;
}

const Dashboard: React.FC<DashboardProps> = ({ 
  weatherData, 
  diagnosisHistory,
  userName 
}) => {
  const latestDiagnosis = diagnosisHistory[0];

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Welcome back, {userName}!
      </Typography>

      <Stack spacing={3}>
        {/* Weather Overview */}
        <WeatherCard
          temperature={weatherData.current.temperature}
          humidity={weatherData.current.humidity}
          windSpeed={weatherData.current.windSpeed}
          condition={weatherData.current.condition}
          location="Khandala, Nashik"
        />

        {/* Quick Actions */}
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Quick Actions
            </Typography>
            <Stack direction="row" spacing={2}>
              <Button
                variant="outlined"
                startIcon={<LocalHospital />}
                fullWidth
              >
                Diagnose Crop
              </Button>
              <Button
                variant="outlined"
                startIcon={<TrendingUp />}
                fullWidth
              >
                Market Prices
              </Button>
              <Button
                variant="outlined"
                startIcon={<School />}
                fullWidth
              >
                Learn
              </Button>
            </Stack>
          </CardContent>
        </Card>

        {/* Recent Activity */}
        {latestDiagnosis && (
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Recent Diagnosis
              </Typography>
              <Box sx={{ display: 'flex', gap: 2 }}>
                <img 
                  src={latestDiagnosis.imageUrl}
                  alt="Recent diagnosis"
                  style={{ width: 80, height: 80, objectFit: 'cover', borderRadius: 8 }}
                />
                <Box sx={{ flexGrow: 1 }}>
                  <Typography variant="subtitle1" sx={{ fontWeight: 'medium' }}>
                    {latestDiagnosis.diagnosis}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    {latestDiagnosis.cropType} • {formatDateTime(new Date(latestDiagnosis.uploadDate))}
                  </Typography>
                  <Button size="small" sx={{ mt: 1 }}>
                    View Details
                  </Button>
                </Box>
              </Box>
            </CardContent>
          </Card>
        )}

        {/* Alerts */}
        <Alert severity="info" icon={<Notifications />}>
          New farming techniques article available in Education section
        </Alert>
      </Stack>
    </Box>
  );
};

export default Dashboard;