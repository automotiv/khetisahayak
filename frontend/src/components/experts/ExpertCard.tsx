import React from 'react';
import { 
  Card, 
  CardContent, 
  Avatar, 
  Typography, 
  Button, 
  Rating,
  Chip,
  Box,
  Stack
} from '@mui/material';
import { Chat, VideoCall, CheckCircle } from '@mui/icons-material';
import { formatCurrency } from '../../utils/formatters';

interface ExpertCardProps {
  id: string;
  name: string;
  specialization: string;
  rating: number;
  languages: string[];
  isAvailable: boolean;
  consultationFee: number;
  profileImage: string;
  onStartChat?: (expertId: string) => void;
  onScheduleCall?: (expertId: string) => void;
}

const ExpertCard: React.FC<ExpertCardProps> = ({
  id,
  name,
  specialization,
  rating,
  languages,
  isAvailable,
  consultationFee,
  profileImage,
  onStartChat,
  onScheduleCall
}) => {
  return (
    <Card>
      <CardContent>
        <Stack spacing={2}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
            <Avatar 
              src={profileImage} 
              alt={name}
              sx={{ width: 60, height: 60 }}
            />
            <Box sx={{ flexGrow: 1 }}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <Typography variant="h6">
                  {name}
                </Typography>
                <CheckCircle sx={{ fontSize: 20, color: 'success.main' }} />
              </Box>
              <Typography variant="body2" color="text.secondary">
                {specialization}
              </Typography>
            </Box>
          </Box>

          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <Rating value={rating} precision={0.1} size="small" readOnly />
            <Typography variant="body2" color="text.secondary">
              ({rating})
            </Typography>
          </Box>

          <Stack direction="row" spacing={1} sx={{ flexWrap: 'wrap' }}>
            {languages.map((language) => (
              <Chip 
                key={language}
                label={language}
                size="small"
                variant="outlined"
              />
            ))}
          </Stack>

          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <Typography variant="body2" color="text.secondary">
              Consultation: {formatCurrency(consultationFee)}
            </Typography>
            <Chip 
              label={isAvailable ? "Available" : "Busy"}
              color={isAvailable ? "success" : "default"}
              size="small"
            />
          </Box>

          <Stack direction="row" spacing={1}>
            <Button
              variant="outlined"
              startIcon={<Chat />}
              onClick={() => onStartChat?.(id)}
              disabled={!isAvailable}
              size="small"
              fullWidth
            >
              Chat
            </Button>
            <Button
              variant="contained"
              startIcon={<VideoCall />}
              onClick={() => onScheduleCall?.(id)}
              disabled={!isAvailable}
              size="small"
              fullWidth
            >
              Schedule Call
            </Button>
          </Stack>
        </Stack>
      </CardContent>
    </Card>
  );
};

export default ExpertCard;