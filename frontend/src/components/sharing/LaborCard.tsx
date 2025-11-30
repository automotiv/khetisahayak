import React from 'react';
import {
  Card,
  CardContent,
  CardActions,
  Typography,
  Button,
  Rating,
  Chip,
  Box,
  Stack,
  Avatar
} from '@mui/material';
import { Work, LocationOn } from '@mui/icons-material';
import { LaborSkill } from '../../types/enums';
import { formatLaborSkill, formatCurrency } from '../../utils/formatters';

interface LaborCardProps {
  id: string;
  name: string;
  skills: LaborSkill[];
  experience: number;
  location: string;
  dailyWage: number;
  hourlyWage: number;
  rating: number;
  isAvailable: boolean;
  profileImage: string;
  description: string;
  onHire?: (laborId: string) => void;
  onViewProfile?: (laborId: string) => void;
}

const LaborCard: React.FC<LaborCardProps> = ({
  id,
  name,
  skills,
  experience,
  location,
  dailyWage,
  hourlyWage,
  rating,
  isAvailable,
  profileImage,
  description,
  onHire,
  onViewProfile
}) => {
  const getSkillColor = (skill: LaborSkill) => {
    switch (skill) {
      case LaborSkill.TRACTOR_OPERATION:
        return 'primary';
      case LaborSkill.PLANTING:
        return 'success';
      case LaborSkill.HARVESTING:
        return 'warning';
      case LaborSkill.MACHINERY_REPAIR:
        return 'error';
      default:
        return 'default';
    }
  };

  return (
    <Card sx={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
      <CardContent sx={{ flexGrow: 1 }}>
        <Stack spacing={2}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
            <Avatar
              src={profileImage}
              alt={name}
              sx={{ width: 50, height: 50 }}
            />
            <Box sx={{ flexGrow: 1 }}>
              <Typography variant="h6" component="div">
                {name}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                {experience} years experience
              </Typography>
            </Box>
            <Chip
              label={isAvailable ? "Available" : "Busy"}
              size="small"
              color={isAvailable ? "success" : "default"}
            />
          </Box>

          <Typography variant="body2" color="text.secondary" sx={{
            display: '-webkit-box',
            WebkitLineClamp: 2,
            WebkitBoxOrient: 'vertical',
            overflow: 'hidden'
          }}>
            {description}
          </Typography>

          <Box>
            <Typography variant="subtitle2" gutterBottom>
              Skills:
            </Typography>
            <Stack direction="row" spacing={1} sx={{ flexWrap: 'wrap', gap: 1 }}>
              {skills.map((skill) => (
                <Chip
                  key={skill}
                  label={formatLaborSkill(skill)}
                  size="small"
                  color={getSkillColor(skill) as any}
                  variant="outlined"
                />
              ))}
            </Stack>
          </Box>

          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <LocationOn sx={{ fontSize: 16, color: 'text.secondary' }} />
            <Typography variant="body2" color="text.secondary">
              {location}
            </Typography>
          </Box>

          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <Rating value={rating} precision={0.1} size="small" readOnly />
            <Typography variant="body2" color="text.secondary">
              ({rating})
            </Typography>
          </Box>

          <Stack spacing={1}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
              <Typography variant="body2">Hourly:</Typography>
              <Typography variant="body2" sx={{ fontWeight: 'medium' }}>
                {formatCurrency(hourlyWage)}/hr
              </Typography>
            </Box>
            <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
              <Typography variant="body2">Daily:</Typography>
              <Typography variant="body2" sx={{ fontWeight: 'medium' }}>
                {formatCurrency(dailyWage)}/day
              </Typography>
            </Box>
          </Stack>
        </Stack>
      </CardContent>

      <CardActions>
        <Stack spacing={1} sx={{ width: '100%' }}>
          <Button
            variant="contained"
            startIcon={<Work />}
            onClick={() => onHire?.(id)}
            disabled={!isAvailable}
            fullWidth
          >
            Hire Worker
          </Button>
          <Button
            variant="outlined"
            onClick={() => onViewProfile?.(id)}
            size="small"
            fullWidth
          >
            View Profile
          </Button>
        </Stack>
      </CardActions>
    </Card>
  );
};

export default LaborCard;