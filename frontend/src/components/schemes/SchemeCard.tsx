import React, { useState } from 'react';
import {
  Card,
  CardContent,
  Typography,
  Chip,
  Button,
  Box,
  Stack,
  IconButton,
  Collapse,
  Alert
} from '@mui/material';
import { 
  Bookmark, 
  BookmarkBorder, 
  ExpandMore, 
  ExpandLess, 
  Launch,
  AccessTime,
  CheckCircle
} from '@mui/icons-material';
import { SchemeType, SchemeLevel } from '../../types/enums';
import { formatSchemeType, formatDate } from '../../utils/formatters';

interface SchemeCardProps {
  id: string;
  name: string;
  type: SchemeType;
  level: SchemeLevel;
  description: string;
  eligibility: string;
  benefits: string;
  deadline: string;
  applicationUrl: string;
  isBookmarked: boolean;
  onBookmark?: (schemeId: string) => void;
  onApply?: (applicationUrl: string) => void;
}

const SchemeCard: React.FC<SchemeCardProps> = ({
  id,
  name,
  type,
  level,
  description,
  eligibility,
  benefits,
  deadline,
  applicationUrl,
  isBookmarked,
  onBookmark,
  onApply
}) => {
  const [expanded, setExpanded] = useState(false);

  const handleBookmark = () => {
    onBookmark?.(id);
  };

  const handleApply = () => {
    onApply?.(applicationUrl);
  };

  const isDeadlineNear = () => {
    const deadlineDate = new Date(deadline);
    const today = new Date();
    const diffTime = deadlineDate.getTime() - today.getTime();
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    return diffDays <= 7 && diffDays > 0;
  };

  const isDeadlinePassed = () => {
    const deadlineDate = new Date(deadline);
    const today = new Date();
    return deadlineDate < today;
  };

  const getSchemeTypeColor = (schemeType: SchemeType) => {
    switch (schemeType) {
      case SchemeType.SUBSIDY:
        return 'success';
      case SchemeType.LOAN:
        return 'info';
      case SchemeType.INSURANCE:
        return 'warning';
      case SchemeType.TRAINING:
        return 'secondary';
      default:
        return 'default';
    }
  };

  return (
    <Card>
      <CardContent>
        <Stack spacing={2}>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <Box sx={{ flexGrow: 1 }}>
              <Typography variant="h6" component="div" sx={{ mb: 1 }}>
                {name}
              </Typography>
              <Stack direction="row" spacing={1} sx={{ mb: 1 }}>
                <Chip 
                  label={formatSchemeType(type)}
                  size="small"
                  color={getSchemeTypeColor(type) as any}
                />
                <Chip 
                  label={level.toUpperCase()}
                  size="small"
                  variant="outlined"
                />
              </Stack>
            </Box>
            <IconButton onClick={handleBookmark}>
              {isBookmarked ? <Bookmark color="primary" /> : <BookmarkBorder />}
            </IconButton>
          </Box>

          <Typography variant="body2" color="text.secondary">
            {description}
          </Typography>

          {/* Deadline Alert */}
          {isDeadlineNear() && (
            <Alert severity="warning" icon={<AccessTime />}>
              Application closes in {Math.ceil((new Date(deadline).getTime() - new Date().getTime()) / (1000 * 60 * 60 * 24))} days
            </Alert>
          )}

          {isDeadlinePassed() && (
            <Alert severity="error">
              Application deadline has passed
            </Alert>
          )}

          {/* Expandable Details */}
          <Box>
            <Button
              onClick={() => setExpanded(!expanded)}
              endIcon={expanded ? <ExpandLess /> : <ExpandMore />}
              size="small"
            >
              {expanded ? 'Hide Details' : 'View Details'}
            </Button>
            
            <Collapse in={expanded}>
              <Stack spacing={2} sx={{ mt: 2 }}>
                <Box>
                  <Typography variant="subtitle2" gutterBottom>
                    Eligibility:
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    {eligibility}
                  </Typography>
                </Box>
                
                <Box>
                  <Typography variant="subtitle2" gutterBottom>
                    Benefits:
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    {benefits}
                  </Typography>
                </Box>
                
                <Box>
                  <Typography variant="subtitle2" gutterBottom>
                    Application Deadline:
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    {formatDate(new Date(deadline))}
                  </Typography>
                </Box>
              </Stack>
            </Collapse>
          </Box>

          {/* Action Buttons */}
          <Stack direction="row" spacing={2}>
            <Button
              variant="contained"
              startIcon={<Launch />}
              onClick={handleApply}
              disabled={isDeadlinePassed()}
              fullWidth
            >
              Apply Now
            </Button>
          </Stack>
        </Stack>
      </CardContent>
    </Card>
  );
};

export default SchemeCard;