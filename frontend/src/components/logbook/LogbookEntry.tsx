import React, { useState } from 'react';
import {
  Card,
  CardContent,
  Typography,
  Chip,
  Box,
  Stack,
  IconButton,
  Menu,
  MenuItem
} from '@mui/material';
import { MoreVert, Edit, Delete, Photo } from '@mui/icons-material';
import { ActivityType } from '../../types/enums';
import { formatActivityType, formatCurrency, formatDateTime } from '../../utils/formatters';

interface LogbookEntryProps {
  id: string;
  activityType: ActivityType;
  cropType: string;
  date: string;
  notes: string;
  inputsUsed: Array<{
    type: string;
    quantity: number;
    unit: string;
    cost: number;
  }>;
  expenses: number;
  photos: string[];
  onEdit?: (entryId: string) => void;
  onDelete?: (entryId: string) => void;
}

const LogbookEntry: React.FC<LogbookEntryProps> = ({
  id,
  activityType,
  cropType,
  date,
  notes,
  inputsUsed,
  expenses,
  photos,
  onEdit,
  onDelete
}) => {
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);

  const handleMenuClick = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(event.currentTarget);
  };

  const handleMenuClose = () => {
    setAnchorEl(null);
  };

  const handleEdit = () => {
    handleMenuClose();
    onEdit?.(id);
  };

  const handleDelete = () => {
    handleMenuClose();
    onDelete?.(id);
  };

  const getActivityColor = (activity: ActivityType) => {
    switch (activity) {
      case ActivityType.PLANTING:
        return 'success';
      case ActivityType.IRRIGATION:
        return 'info';
      case ActivityType.FERTILIZING:
        return 'warning';
      case ActivityType.PEST_CONTROL:
        return 'error';
      case ActivityType.HARVESTING:
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
            <Box>
              <Typography variant="h6" component="div">
                {formatActivityType(activityType)}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                {cropType} • {formatDateTime(new Date(date))}
              </Typography>
            </Box>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <Chip 
                label={formatActivityType(activityType)}
                size="small"
                color={getActivityColor(activityType) as any}
              />
              <IconButton size="small" onClick={handleMenuClick}>
                <MoreVert />
              </IconButton>
            </Box>
          </Box>

          {notes && (
            <Typography variant="body2">
              {notes}
            </Typography>
          )}

          {inputsUsed.length > 0 && (
            <Box>
              <Typography variant="subtitle2" gutterBottom>
                Inputs Used:
              </Typography>
              <Stack spacing={1}>
                {inputsUsed.map((input, index) => (
                  <Box key={index} sx={{ display: 'flex', justifyContent: 'space-between' }}>
                    <Typography variant="body2">
                      {input.type}: {input.quantity} {input.unit}
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      {formatCurrency(input.cost)}
                    </Typography>
                  </Box>
                ))}
              </Stack>
            </Box>
          )}

          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <Typography variant="subtitle2" color="primary.main">
              Total Expense: {formatCurrency(expenses)}
            </Typography>
            {photos.length > 0 && (
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                <Photo sx={{ fontSize: 16, color: 'text.secondary' }} />
                <Typography variant="body2" color="text.secondary">
                  {photos.length} photo{photos.length > 1 ? 's' : ''}
                </Typography>
              </Box>
            )}
          </Box>
        </Stack>
      </CardContent>

      <Menu
        anchorEl={anchorEl}
        open={Boolean(anchorEl)}
        onClose={handleMenuClose}
      >
        <MenuItem onClick={handleEdit}>
          <Edit sx={{ mr: 1 }} /> Edit
        </MenuItem>
        <MenuItem onClick={handleDelete}>
          <Delete sx={{ mr: 1 }} /> Delete
        </MenuItem>
      </Menu>
    </Card>
  );
};

export default LogbookEntry;