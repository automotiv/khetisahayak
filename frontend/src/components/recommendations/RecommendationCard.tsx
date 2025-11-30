import React, { useState } from 'react';
import {
  Card,
  CardContent,
  Typography,
  Button,
  Chip,
  Box,
  Stack,
  Alert,
  IconButton
} from '@mui/material';
import {
  ThumbUp,
  ThumbDown,
  CheckCircle,
  Schedule,
  PriorityHigh,
  WaterDrop,
  Nature,
  BugReport,
  Agriculture,
  TrendingUp,
  Storage
} from '@mui/icons-material';
import { RecommendationType, RecommendationPriority } from '../../types/enums';
import { formatRecommendationPriority, formatDateTime } from '../../utils/formatters';

interface RecommendationCardProps {
  id: string;
  type: RecommendationType;
  priority: RecommendationPriority;
  title: string;
  description: string;
  reasoning: string;
  actionRequired: boolean;
  dueDate: string;
  isFollowed: boolean;
  onFollow?: (recommendationId: string) => void;
  onFeedback?: (recommendationId: string, helpful: boolean) => void;
}

const RecommendationCard: React.FC<RecommendationCardProps> = ({
  id,
  type,
  priority,
  title,
  description,
  reasoning,
  actionRequired,
  dueDate,
  isFollowed,
  onFollow,
  onFeedback
}) => {
  const [feedbackGiven, setFeedbackGiven] = useState(false);

  const getRecommendationIcon = (recType: RecommendationType) => {
    switch (recType) {
      case RecommendationType.IRRIGATION:
        return <WaterDrop sx={{ color: 'info.main' }} />;
      case RecommendationType.FERTILIZATION:
        return <Nature sx={{ color: 'success.main' }} />;
      case RecommendationType.PEST_MANAGEMENT:
        return <BugReport sx={{ color: 'error.main' }} />;
      case RecommendationType.CROP_SELECTION:
        return <Agriculture sx={{ color: 'primary.main' }} />;
      case RecommendationType.MARKET_TIMING:
        return <TrendingUp sx={{ color: 'secondary.main' }} />;
      case RecommendationType.STORAGE:
        return <Storage sx={{ color: 'warning.main' }} />;
      default:
        return <PriorityHigh sx={{ color: 'grey.600' }} />;
    }
  };

  const getPriorityColor = (prio: RecommendationPriority) => {
    switch (prio) {
      case RecommendationPriority.HIGH:
        return 'error';
      case RecommendationPriority.MEDIUM:
        return 'warning';
      case RecommendationPriority.LOW:
        return 'info';
      default:
        return 'default';
    }
  };

  const handleFollow = () => {
    onFollow?.(id);
  };

  const handleFeedback = (helpful: boolean) => {
    setFeedbackGiven(true);
    onFeedback?.(id, helpful);
  };

  const isDue = new Date(dueDate) <= new Date();

  return (
    <Card sx={{
      border: actionRequired && isDue ? 2 : 0,
      borderColor: actionRequired && isDue ? 'error.main' : 'transparent'
    }}>
      <CardContent>
        <Stack spacing={2}>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              {getRecommendationIcon(type)}
              <Typography variant="h6" component="div">
                {title}
              </Typography>
            </Box>
            <Chip
              label={formatRecommendationPriority(priority)}
              size="small"
              color={getPriorityColor(priority) as any}
            />
          </Box>

          <Typography variant="body1">
            {description}
          </Typography>

          <Alert severity="info" sx={{ backgroundColor: 'grey.50' }}>
            <Typography variant="body2">
              <strong>Why:</strong> {reasoning}
            </Typography>
          </Alert>

          {actionRequired && (
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <Schedule sx={{ fontSize: 16, color: isDue ? 'error.main' : 'warning.main' }} />
              <Typography variant="body2" color={isDue ? 'error.main' : 'warning.main'}>
                {isDue ? 'Action needed now' : `Due: ${formatDateTime(new Date(dueDate))}`}
              </Typography>
            </Box>
          )}

          <Stack direction="row" spacing={2}>
            <Button
              variant={isFollowed ? "outlined" : "contained"}
              startIcon={isFollowed ? <CheckCircle /> : undefined}
              onClick={handleFollow}
              disabled={isFollowed}
              fullWidth
            >
              {isFollowed ? 'Followed' : 'Follow Recommendation'}
            </Button>
          </Stack>

          {/* Feedback Section */}
          {!feedbackGiven && (
            <Box>
              <Typography variant="body2" color="text.secondary" gutterBottom>
                Was this recommendation helpful?
              </Typography>
              <Stack direction="row" spacing={1}>
                <IconButton
                  size="small"
                  onClick={() => handleFeedback(true)}
                  sx={{ color: 'success.main' }}
                >
                  <ThumbUp />
                </IconButton>
                <IconButton
                  size="small"
                  onClick={() => handleFeedback(false)}
                  sx={{ color: 'error.main' }}
                >
                  <ThumbDown />
                </IconButton>
              </Stack>
            </Box>
          )}

          {feedbackGiven && (
            <Typography variant="body2" color="success.main">
              Thank you for your feedback!
            </Typography>
          )}
        </Stack>
      </CardContent>
    </Card>
  );
};

export default RecommendationCard;