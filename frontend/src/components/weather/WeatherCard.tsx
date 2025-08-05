import React from 'react';
import { Card, CardContent, Typography, Box, Stack } from '@mui/material';
import { WbSunny, Cloud, Opacity, Air } from '@mui/icons-material';
import { WeatherCondition } from '../../types/enums';
import { formatTemperature, formatHumidity, formatWindSpeed, formatWeatherCondition } from '../../utils/formatters';

interface WeatherCardProps {
  temperature: number;
  humidity: number;
  windSpeed: number;
  condition: WeatherCondition;
  location?: string;
}

const getWeatherIcon = (condition: WeatherCondition) => {
  switch (condition) {
    case WeatherCondition.SUNNY:
      return <WbSunny sx={{ fontSize: 48, color: 'warning.main' }} />;
    case WeatherCondition.CLOUDY:
      return <Cloud sx={{ fontSize: 48, color: 'grey.600' }} />;
    case WeatherCondition.RAINY:
      return <Opacity sx={{ fontSize: 48, color: 'info.main' }} />;
    default:
      return <Cloud sx={{ fontSize: 48, color: 'grey.600' }} />;
  }
};

const WeatherCard: React.FC<WeatherCardProps> = ({
  temperature,
  humidity,
  windSpeed,
  condition,
  location = "Current Location"
}) => {
  return (
    <Card sx={{ mb: 2 }}>
      <CardContent>
        <Stack spacing={2}>
          <Typography variant="h6" color="text.secondary">
            {location}
          </Typography>
          
          <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <Box>
              <Typography variant="h3" component="div" sx={{ fontWeight: 'bold' }}>
                {formatTemperature(temperature)}
              </Typography>
              <Typography variant="body1" color="text.secondary">
                {formatWeatherCondition(condition)}
              </Typography>
            </Box>
            {getWeatherIcon(condition)}
          </Box>
          
          <Stack direction="row" spacing={3}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <Opacity sx={{ fontSize: 20, color: 'info.main' }} />
              <Typography variant="body2">
                {formatHumidity(humidity)}
              </Typography>
            </Box>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <Air sx={{ fontSize: 20, color: 'grey.600' }} />
              <Typography variant="body2">
                {formatWindSpeed(windSpeed)}
              </Typography>
            </Box>
          </Stack>
        </Stack>
      </CardContent>
    </Card>
  );
};

export default WeatherCard;