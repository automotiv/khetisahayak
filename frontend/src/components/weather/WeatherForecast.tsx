import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Tabs,
  Tab,
  Card,
  CardContent,
  Stack,
  Alert,
  CircularProgress,
  Chip,
  Divider,
  Grid
} from '@mui/material';
import {
  Warning,
  Opacity,
  WbSunny,
  Grass,
  Thermostat,
  WaterDrop
} from '@mui/icons-material';
import WeatherCard from './WeatherCard';
import { QueryTypes } from '../../types/schema';
import { formatTemperature, formatDate, formatTime } from '../../utils/formatters';
import { externalApi, AgroWeatherData } from '../../services/api';

interface WeatherForecastProps {
  weatherData: QueryTypes['weatherData'];
  lat?: number;
  lon?: number;
}

const WeatherForecast: React.FC<WeatherForecastProps> = ({
  weatherData,
  lat = 19.9975,
  lon = 73.7898
}) => {
  const [tabValue, setTabValue] = useState(0);
  const [agroWeather, setAgroWeather] = useState<AgroWeatherData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchAgroWeather = async () => {
      try {
        setLoading(true);
        const data = await externalApi.getAgroWeather(lat, lon);
        setAgroWeather(data);
      } catch (error) {
        console.error('Failed to fetch agro weather:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchAgroWeather();
  }, [lat, lon]);

  const handleTabChange = (_: React.SyntheticEvent, newValue: number) => {
    setTabValue(newValue);
  };

  // Get agricultural insights from live data
  const insights = agroWeather?.agriculturalInsights || [];
  const highSeverityInsights = insights.filter(i => i.severity === 'high');

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Weather Forecast
      </Typography>

      {/* Weather Alerts from Live API */}
      {highSeverityInsights.length > 0 ? (
        highSeverityInsights.map((insight, index) => (
          <Alert
            key={index}
            severity="warning"
            icon={<Warning />}
            sx={{ mb: 1 }}
          >
            {insight.message}
          </Alert>
        ))
      ) : (
        <Alert severity="info" sx={{ mb: 2 }}>
          Weather conditions are favorable for farming activities.
        </Alert>
      )}

      {/* Current Weather */}
      <WeatherCard
        temperature={agroWeather?.current?.temperature || weatherData.current.temperature}
        humidity={agroWeather?.current?.humidity || weatherData.current.humidity}
        windSpeed={agroWeather?.current?.windSpeed || weatherData.current.windSpeed}
        condition={weatherData.current.condition}
        location="Nashik, Maharashtra"
      />

      {/* Agricultural Data Cards */}
      {agroWeather && (
        <Box sx={{ my: 2 }}>
          <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <Grass color="success" /> Agricultural Conditions
            <Chip label="Live" color="success" size="small" sx={{ ml: 1 }} />
          </Typography>

          <Grid container spacing={2}>
            <Grid item xs={6} sm={3}>
              <Card variant="outlined">
                <CardContent sx={{ textAlign: 'center', py: 1.5 }}>
                  <Opacity color="primary" />
                  <Typography variant="h6">
                    {((agroWeather.current.soilMoisture || 0) * 100).toFixed(0)}%
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    Soil Moisture
                  </Typography>
                </CardContent>
              </Card>
            </Grid>

            <Grid item xs={6} sm={3}>
              <Card variant="outlined">
                <CardContent sx={{ textAlign: 'center', py: 1.5 }}>
                  <Thermostat color="error" />
                  <Typography variant="h6">
                    {agroWeather.current.soilTemperature?.toFixed(1) || '--'}°C
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    Soil Temp
                  </Typography>
                </CardContent>
              </Card>
            </Grid>

            <Grid item xs={6} sm={3}>
              <Card variant="outlined">
                <CardContent sx={{ textAlign: 'center', py: 1.5 }}>
                  <WbSunny color="warning" />
                  <Typography variant="h6">
                    {agroWeather.daily?.[0]?.uvIndexMax?.toFixed(1) || '--'}
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    UV Index
                  </Typography>
                </CardContent>
              </Card>
            </Grid>

            <Grid item xs={6} sm={3}>
              <Card variant="outlined">
                <CardContent sx={{ textAlign: 'center', py: 1.5 }}>
                  <WaterDrop color="info" />
                  <Typography variant="h6">
                    {agroWeather.daily?.[0]?.evapotranspiration?.toFixed(1) || '--'}mm
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    ET₀ (Water Need)
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
          </Grid>
        </Box>
      )}

      {/* Forecast Tabs */}
      <Tabs value={tabValue} onChange={handleTabChange} sx={{ mb: 2 }}>
        <Tab label="Hourly" />
        <Tab label="7-Day Forecast" />
        <Tab label="Farm Insights" />
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

      {/* Daily Forecast with Live Data */}
      {tabValue === 1 && (
        <Stack spacing={1}>
          {loading ? (
            <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
              <CircularProgress />
            </Box>
          ) : (
            (agroWeather?.daily || weatherData.daily).map((day: any, index: number) => (
              <Card key={index} variant="outlined">
                <CardContent sx={{ py: 1.5 }}>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <Typography variant="body2" sx={{ minWidth: 80 }}>
                      {formatDate(new Date(day.date))}
                    </Typography>
                    <Box sx={{ display: 'flex', gap: 1, alignItems: 'center' }}>
                      <Typography variant="body2" sx={{ fontWeight: 'medium' }}>
                        {formatTemperature(day.tempMax || day.maxTemp)}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        {formatTemperature(day.tempMin || day.minTemp)}
                      </Typography>
                    </Box>
                    <Box sx={{ display: 'flex', gap: 1, alignItems: 'center' }}>
                      <WaterDrop fontSize="small" color="info" />
                      <Typography variant="body2" color="text.secondary">
                        {day.precipitationProbability || day.precipitation}%
                      </Typography>
                    </Box>
                    {day.uvIndexMax && (
                      <Chip
                        label={`UV ${day.uvIndexMax.toFixed(0)}`}
                        size="small"
                        color={day.uvIndexMax > 7 ? 'error' : day.uvIndexMax > 5 ? 'warning' : 'success'}
                      />
                    )}
                  </Box>
                </CardContent>
              </Card>
            ))
          )}
        </Stack>
      )}

      {/* Farm Insights Tab */}
      {tabValue === 2 && (
        <Stack spacing={2}>
          {loading ? (
            <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
              <CircularProgress />
            </Box>
          ) : insights.length > 0 ? (
            insights.map((insight, index) => (
              <Alert
                key={index}
                severity={insight.severity === 'high' ? 'error' : insight.severity === 'medium' ? 'warning' : 'info'}
              >
                <Typography variant="body2" fontWeight="medium">
                  {insight.type.replace(/_/g, ' ').toUpperCase()}
                </Typography>
                <Typography variant="body2">{insight.message}</Typography>
                {insight.message_hi && (
                  <Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>
                    {insight.message_hi}
                  </Typography>
                )}
              </Alert>
            ))
          ) : (
            <Alert severity="success">
              <Typography variant="body2">
                All conditions are favorable for your crops. No special actions needed.
              </Typography>
            </Alert>
          )}

          <Divider sx={{ my: 1 }} />

          <Typography variant="caption" color="text.secondary">
            Data source: {agroWeather?.source || 'Open-Meteo API'}
            {agroWeather?.cache?.hit && ' (Cached)'}
          </Typography>
        </Stack>
      )}
    </Box>
  );
};

export default WeatherForecast;
