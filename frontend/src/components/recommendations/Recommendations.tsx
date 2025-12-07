import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  FormControl,
  Select,
  MenuItem,
  InputLabel,
  Stack,
  Tabs,
  Tab,
  Alert,
  Card,
  CardContent,
  Chip,
  CircularProgress,
  Grid,
  LinearProgress,
  Divider
} from '@mui/material';
import {
  PriorityHigh,
  Schedule,
  CheckCircle,
  CalendarMonth,
  Grass,
  Agriculture
} from '@mui/icons-material';
import RecommendationCard from './RecommendationCard';
import { RecommendationType, RecommendationPriority } from '../../types/enums';
import { externalApi, CropCalendarData } from '../../services/api';

interface RecommendationData {
  id: string;
  type: RecommendationType;
  priority: RecommendationPriority;
  title: string;
  description: string;
  reasoning: string;
  actionRequired: boolean;
  dueDate: string;
  isFollowed: boolean;
}

interface RecommendationsProps {
  recommendations: RecommendationData[];
  lat?: number;
  lon?: number;
}

const Recommendations: React.FC<RecommendationsProps> = ({
  recommendations,
  lat = 19.9975,
  lon = 73.7898
}) => {
  const [selectedType, setSelectedType] = useState<RecommendationType | 'all'>('all');
  const [selectedPriority, setSelectedPriority] = useState<RecommendationPriority | 'all'>('all');
  const [tabValue, setTabValue] = useState(0);
  const [followedRecommendations, setFollowedRecommendations] = useState<Set<string>>(
    new Set(recommendations.filter(r => r.isFollowed).map(r => r.id))
  );

  // Crop Calendar State
  const [cropCalendar, setCropCalendar] = useState<CropCalendarData | null>(null);
  const [calendarLoading, setCalendarLoading] = useState(false);

  useEffect(() => {
    if (tabValue === 3) {
      fetchCropCalendar();
    }
  }, [tabValue, lat, lon]);

  const fetchCropCalendar = async () => {
    try {
      setCalendarLoading(true);
      const data = await externalApi.getCropCalendar(lat, lon);
      setCropCalendar(data);
    } catch (error) {
      console.error('Failed to fetch crop calendar:', error);
    } finally {
      setCalendarLoading(false);
    }
  };

  const filteredRecommendations = recommendations.filter(rec => {
    const matchesType = selectedType === 'all' || rec.type === selectedType;
    const matchesPriority = selectedPriority === 'all' || rec.priority === selectedPriority;

    let matchesTab = true;
    switch (tabValue) {
      case 0: // All
        matchesTab = true;
        break;
      case 1: // Action Required
        matchesTab = rec.actionRequired && !followedRecommendations.has(rec.id);
        break;
      case 2: // Followed
        matchesTab = followedRecommendations.has(rec.id);
        break;
    }

    return matchesType && matchesPriority && matchesTab;
  });

  const sortedRecommendations = [...filteredRecommendations].sort((a, b) => {
    const priorityOrder = { high: 3, medium: 2, low: 1 };
    const aPriority = priorityOrder[a.priority];
    const bPriority = priorityOrder[b.priority];

    if (aPriority !== bPriority) {
      return bPriority - aPriority;
    }

    return new Date(a.dueDate).getTime() - new Date(b.dueDate).getTime();
  });

  const handleFollow = (recommendationId: string) => {
    setFollowedRecommendations(prev => {
      const newSet = new Set(prev);
      newSet.add(recommendationId);
      return newSet;
    });
  };

  const handleFeedback = (recommendationId: string, helpful: boolean) => {
    console.log('Feedback for recommendation:', recommendationId, 'Helpful:', helpful);
  };

  const urgentCount = recommendations.filter(r =>
    r.actionRequired &&
    r.priority === RecommendationPriority.HIGH &&
    !followedRecommendations.has(r.id)
  ).length;

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'Sowing Time': return 'success';
      case 'Growing': return 'info';
      case 'Harvest Time': return 'warning';
      case 'Off Season': return 'default';
      default: return 'default';
    }
  };

  const getProgressValue = (status: string) => {
    switch (status) {
      case 'Sowing Time': return 15;
      case 'Growing': return 50;
      case 'Harvest Time': return 85;
      case 'Off Season': return 0;
      default: return 0;
    }
  };

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Recommendations
      </Typography>

      {/* Urgent Alert */}
      {urgentCount > 0 && (
        <Alert
          severity="warning"
          icon={<PriorityHigh />}
          sx={{ mb: 2 }}
        >
          You have {urgentCount} urgent recommendation{urgentCount > 1 ? 's' : ''} requiring immediate action
        </Alert>
      )}

      {/* Tabs */}
      <Tabs value={tabValue} onChange={(_, newValue) => setTabValue(newValue)} sx={{ mb: 2 }}>
        <Tab label="All" />
        <Tab
          label={
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <Schedule />
              <span>Action Required</span>
            </Box>
          }
        />
        <Tab
          label={
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <CheckCircle />
              <span>Followed</span>
            </Box>
          }
        />
        <Tab
          label={
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <CalendarMonth />
              <span>Crop Calendar</span>
              <Chip label="Live" color="success" size="small" />
            </Box>
          }
        />
      </Tabs>

      {/* Recommendations Tabs (0, 1, 2) */}
      {tabValue < 3 && (
        <>
          {/* Filters */}
          <Stack direction="row" spacing={2} sx={{ mb: 3 }}>
            <FormControl size="small" sx={{ minWidth: 150 }}>
              <InputLabel>Type</InputLabel>
              <Select
                value={selectedType}
                label="Type"
                onChange={(e) => setSelectedType(e.target.value as RecommendationType | 'all')}
              >
                <MenuItem value="all">All Types</MenuItem>
                <MenuItem value={RecommendationType.IRRIGATION}>Irrigation</MenuItem>
                <MenuItem value={RecommendationType.FERTILIZATION}>Fertilization</MenuItem>
                <MenuItem value={RecommendationType.PEST_MANAGEMENT}>Pest Management</MenuItem>
                <MenuItem value={RecommendationType.CROP_SELECTION}>Crop Selection</MenuItem>
                <MenuItem value={RecommendationType.MARKET_TIMING}>Market Timing</MenuItem>
                <MenuItem value={RecommendationType.STORAGE}>Storage</MenuItem>
              </Select>
            </FormControl>

            <FormControl size="small" sx={{ minWidth: 120 }}>
              <InputLabel>Priority</InputLabel>
              <Select
                value={selectedPriority}
                label="Priority"
                onChange={(e) => setSelectedPriority(e.target.value as RecommendationPriority | 'all')}
              >
                <MenuItem value="all">All Priorities</MenuItem>
                <MenuItem value={RecommendationPriority.HIGH}>High</MenuItem>
                <MenuItem value={RecommendationPriority.MEDIUM}>Medium</MenuItem>
                <MenuItem value={RecommendationPriority.LOW}>Low</MenuItem>
              </Select>
            </FormControl>
          </Stack>

          {/* Recommendations List */}
          <Stack spacing={2}>
            {sortedRecommendations.map((recommendation) => (
              <RecommendationCard
                key={recommendation.id}
                id={recommendation.id}
                type={recommendation.type}
                priority={recommendation.priority}
                title={recommendation.title}
                description={recommendation.description}
                reasoning={recommendation.reasoning}
                actionRequired={recommendation.actionRequired}
                dueDate={recommendation.dueDate}
                isFollowed={followedRecommendations.has(recommendation.id)}
                onFollow={handleFollow}
                onFeedback={handleFeedback}
              />
            ))}
          </Stack>

          {sortedRecommendations.length === 0 && (
            <Box sx={{ textAlign: 'center', py: 4 }}>
              <Typography variant="h6" color="text.secondary">
                No recommendations found
              </Typography>
              <Typography variant="body2" color="text.secondary">
                {tabValue === 2 ? 'You haven\'t followed any recommendations yet' : 'Check back later for new recommendations'}
              </Typography>
            </Box>
          )}
        </>
      )}

      {/* Crop Calendar Tab */}
      {tabValue === 3 && (
        <>
          {calendarLoading ? (
            <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
              <CircularProgress />
            </Box>
          ) : cropCalendar ? (
            <>
              {/* Location & Season Info */}
              <Card sx={{ mb: 3, bgcolor: 'success.light' }}>
                <CardContent>
                  <Stack direction="row" spacing={3} alignItems="center">
                    <Agriculture sx={{ fontSize: 40, color: 'success.dark' }} />
                    <Box>
                      <Typography variant="h6" color="success.dark">
                        {cropCalendar.calendar.season} Season
                      </Typography>
                      <Typography variant="body2" color="success.dark">
                        {cropCalendar.currentMonth} | {cropCalendar.location.climateZone}
                      </Typography>
                    </Box>
                  </Stack>
                </CardContent>
              </Card>

              {/* Crop Cards */}
              <Typography variant="h6" gutterBottom>
                <Grass sx={{ mr: 1, verticalAlign: 'middle' }} />
                Recommended Crops for Your Region
              </Typography>

              <Grid container spacing={2} sx={{ mb: 3 }}>
                {cropCalendar.calendar.crops.map((crop, index) => (
                  <Grid item xs={12} sm={6} md={4} key={index}>
                    <Card variant="outlined">
                      <CardContent>
                        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 1 }}>
                          <Typography variant="h6">{crop.name}</Typography>
                          <Chip
                            label={crop.status}
                            size="small"
                            color={getStatusColor(crop.status) as any}
                          />
                        </Box>

                        <Box sx={{ mb: 2 }}>
                          <Typography variant="caption" color="text.secondary">
                            Growth Progress
                          </Typography>
                          <LinearProgress
                            variant="determinate"
                            value={getProgressValue(crop.status)}
                            sx={{ height: 8, borderRadius: 4 }}
                          />
                        </Box>

                        <Stack spacing={0.5}>
                          <Typography variant="body2">
                            <strong>Sowing:</strong> {crop.sowingStart} - {crop.sowingEnd}
                          </Typography>
                          <Typography variant="body2">
                            <strong>Harvest:</strong> {crop.harvestStart} - {crop.harvestEnd}
                          </Typography>
                        </Stack>
                      </CardContent>
                    </Card>
                  </Grid>
                ))}
              </Grid>

              {/* Recommendations */}
              {cropCalendar.recommendations && cropCalendar.recommendations.length > 0 && (
                <Box>
                  <Typography variant="h6" gutterBottom>
                    Seasonal Recommendations
                  </Typography>
                  <Stack spacing={1}>
                    {cropCalendar.recommendations.map((rec, index) => (
                      <Alert key={index} severity="info" icon={<CheckCircle />}>
                        {rec}
                      </Alert>
                    ))}
                  </Stack>
                </Box>
              )}

              <Divider sx={{ my: 2 }} />
              <Typography variant="caption" color="text.secondary">
                Location: {cropCalendar.location.lat.toFixed(2)}°N, {cropCalendar.location.lon.toFixed(2)}°E | Climate Zone: {cropCalendar.location.climateZone}
              </Typography>
            </>
          ) : (
            <Alert severity="warning">
              Unable to fetch crop calendar. Please try again later.
            </Alert>
          )}
        </>
      )}
    </Box>
  );
};

export default Recommendations;
