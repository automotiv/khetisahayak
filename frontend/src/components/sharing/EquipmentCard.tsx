import React from 'react';
import {
  Card,
  CardMedia,
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
import { CalendarToday, LocationOn, Security } from '@mui/icons-material';
import { EquipmentType, EquipmentStatus } from '../../types/enums';
import { formatEquipmentType, formatCurrency } from '../../utils/formatters';

interface EquipmentCardProps {
  id: string;
  name: string;
  type: EquipmentType;
  owner: string;
  location: string;
  hourlyRate: number;
  dailyRate: number;
  securityDeposit: number;
  status: EquipmentStatus;
  rating: number;
  images: string[];
  description: string;
  onBook?: (equipmentId: string) => void;
  onViewDetails?: (equipmentId: string) => void;
}

const EquipmentCard: React.FC<EquipmentCardProps> = ({
  id,
  name,
  type,
  owner,
  location,
  hourlyRate,
  dailyRate,
  securityDeposit,
  status,
  rating,
  images,
  description,
  onBook,
  onViewDetails
}) => {
  const getStatusColor = (equipStatus: EquipmentStatus) => {
    switch (equipStatus) {
      case EquipmentStatus.AVAILABLE:
        return 'success';
      case EquipmentStatus.BOOKED:
        return 'error';
      case EquipmentStatus.MAINTENANCE:
        return 'warning';
      default:
        return 'default';
    }
  };

  const getStatusText = (equipStatus: EquipmentStatus) => {
    switch (equipStatus) {
      case EquipmentStatus.AVAILABLE:
        return 'Available';
      case EquipmentStatus.BOOKED:
        return 'Booked';
      case EquipmentStatus.MAINTENANCE:
        return 'Under Maintenance';
      case EquipmentStatus.UNAVAILABLE:
        return 'Unavailable';
      default:
        return 'Unknown';
    }
  };

  return (
    <Card sx={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
      <CardMedia
        component="img"
        height="160"
        image={images[0] || '/placeholder-equipment.jpg'}
        alt={name}
      />
      
      <CardContent sx={{ flexGrow: 1 }}>
        <Stack spacing={2}>
          <Box>
            <Typography variant="h6" component="div" gutterBottom>
              {name}
            </Typography>
            <Chip 
              label={formatEquipmentType(type)}
              size="small"
              color="primary"
              variant="outlined"
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

          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <Avatar sx={{ width: 24, height: 24 }}>
              {owner.charAt(0)}
            </Avatar>
            <Typography variant="body2" color="text.secondary">
              {owner}
            </Typography>
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
                {formatCurrency(hourlyRate)}/hr
              </Typography>
            </Box>
            <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
              <Typography variant="body2">Daily:</Typography>
              <Typography variant="body2" sx={{ fontWeight: 'medium' }}>
                {formatCurrency(dailyRate)}/day
              </Typography>
            </Box>
            <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
              <Typography variant="body2">Deposit:</Typography>
              <Typography variant="body2" sx={{ fontWeight: 'medium' }}>
                {formatCurrency(securityDeposit)}
              </Typography>
            </Box>
          </Stack>

          <Chip 
            label={getStatusText(status)}
            size="small"
            color={getStatusColor(status) as any}
          />
        </Stack>
      </CardContent>
      
      <CardActions>
        <Stack spacing={1} sx={{ width: '100%' }}>
          <Button
            variant="contained"
            startIcon={<CalendarToday />}
            onClick={() => onBook?.(id)}
            disabled={status !== EquipmentStatus.AVAILABLE}
            fullWidth
          >
            Book Equipment
          </Button>
          <Button
            variant="outlined"
            onClick={() => onViewDetails?.(id)}
            size="small"
            fullWidth
          >
            View Details
          </Button>
        </Stack>
      </CardActions>
    </Card>
  );
};

export default EquipmentCard;