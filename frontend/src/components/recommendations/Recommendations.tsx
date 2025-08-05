import React, { useState } from 'react';
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
  Alert
} from '@mui/material';
import { PriorityHigh, Schedule, CheckCircle } from '@mui/icons-material';
import RecommendationCard from './RecommendationCard';
import { RecommendationType, RecommendationPriority } from '../../types/enums';

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
}

const Recommendations: React.FC<RecommendationsProps> = ({ recommendations }) => {
  const [selectedType, setSelectedType] = useState<RecommendationType | 'all'>('all');
  const [selectedPriority, setSelectedPriority] = useState<RecommendationPriority | 'all'>('all');
  const [tabValue, setTabValue] = useState(0);
  const [followedRecommendations, setFollowedRecommendations] = useState<Set<string>>(
    new Set(recommendations.filter(r => r.isFollowed).map(r => r.id))
  );

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
    // Sort by priority first, then by due date
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
      <Tabs value={tabValue} onChange={(e, newValue) => setTabValue(newValue)} sx={{ mb: 2 }}>
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
      </Tabs>

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
    </Box>
  );
};

export default Recommendations;