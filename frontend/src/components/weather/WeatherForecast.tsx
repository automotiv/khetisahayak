import React, { useState } from 'react';
import { Box, Typography, Tabs, Tab, Card, CardContent, Stack, Alert } from '@mui/material';
import { Warning } from '@mui/icons-material';
import WeatherCard from './WeatherCard';
import { QueryTypes } from '../../types/schema';
import { formatTemperature, formatDate, formatTime } from '../../utils/formatters';

interface WeatherForecastProps {
  weatherData: QueryTypes['weatherData'];
}

const WeatherForecast: React.FC<WeatherForecastProps> = ({ weatherData }) => {
  const [tabValue, setTabValue] = useState(0);

  const handleTabChange = (_: React.SyntheticEvent, newValue: number) => {
    setTabValue(newValue);
  };

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Weather Forecast
      </Typography>

      {/* Weather Alert */}
      <Alert
        severity="warning"
        icon={<Warning />}
        sx={{ mb: 2 }}
      >
        Heavy rainfall expected in next 6 hours. Take necessary precautions for your crops.
      </Alert>

      {/* Current Weather */}
      <WeatherCard
        temperature={weatherData.current.temperature}
        humidity={weatherData.current.humidity}
        windSpeed={weatherData.current.windSpeed}
        condition={weatherData.current.condition}
        location="Khandala, Nashik"
      />

      {/* Forecast Tabs */}
      <Tabs value={tabValue} onChange={handleTabChange} sx={{ mb: 2 }}>
        <Tab label="Hourly" />
        <Tab label="7-Day Forecast" />
      </Tabs>

      {/* Hourly Forecast */}
      {tabValue === 0 && (
        <Stack spacing={1}>
          {weatherData.hourly.map((hour, index) => (
            <Card key={index} variant="outlined">
              <CardContent sx={{ py: 1 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <Typography variant="body2">
                    {formatTime(new Date(hour.time))}
                  </Typography>
                  <Typography variant="body2" sx={{ fontWeight: 'medium' }}>
                    {formatTemperature(hour.temperature)}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    {hour.precipitation}% rain
                  </Typography>
                </Box>
              </CardContent>
            </Card>
          ))}
        </Stack>
      )}

      {/* Daily Forecast */}
      {tabValue === 1 && (
        <Stack spacing={1}>
          {weatherData.daily.map((day, index) => (
            <Card key={index} variant="outlined">
              <CardContent sx={{ py: 1 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <Typography variant="body2">
                    {formatDate(new Date(day.date))}
                  </Typography>
                  <Box sx={{ display: 'flex', gap: 1 }}>
                    <Typography variant="body2" sx={{ fontWeight: 'medium' }}>
                      {formatTemperature(day.maxTemp)}
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      {formatTemperature(day.minTemp)}
                    </Typography>
                  </Box>
                  <Typography variant="body2" color="text.secondary">
                    {day.precipitation}% rain
                  </Typography>
                </Box>
              </CardContent>
            </Card>
          ))}
        </Stack>
      )}
    </Box>
  );
};

export default WeatherForecast;