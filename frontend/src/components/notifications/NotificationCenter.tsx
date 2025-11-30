import React, { useState } from 'react';
import {
  Box,
  Typography,
  List,
  ListItem,
  ListItemAvatar,
  ListItemText,
  ListItemSecondaryAction,
  Avatar,
  IconButton,
  Chip,
  Button,
  Stack,
  Tabs,
  Tab,
  Badge
} from '@mui/material';
import {
  Notifications,
  WbSunny,
  AccountBalance,
  ShoppingCart,
  People,
  Forum,
  MarkEmailRead,
  Delete,
  Settings
} from '@mui/icons-material';
import { formatDateTime } from '../../utils/formatters';

interface NotificationData {
  id: string;
  type: string;
  title: string;
  message: string;
  timestamp: string;
  isRead: boolean;
  priority: string;
}

interface NotificationCenterProps {
  notifications: NotificationData[];
}

const NotificationCenter: React.FC<NotificationCenterProps> = ({ notifications }) => {
  const [tabValue, setTabValue] = useState(0);
  const [readNotifications, setReadNotifications] = useState<Set<string>>(
    new Set(notifications.filter(n => n.isRead).map(n => n.id))
  );

  const getNotificationIcon = (type: string) => {
    switch (type) {
      case 'weather_alert':
        return <WbSunny sx={{ color: 'warning.main' }} />;
      case 'scheme_deadline':
        return <AccountBalance sx={{ color: 'info.main' }} />;
      case 'order_update':
        return <ShoppingCart sx={{ color: 'success.main' }} />;
      case 'expert_message':
        return <People sx={{ color: 'primary.main' }} />;
      case 'forum_reply':
        return <Forum sx={{ color: 'secondary.main' }} />;
      default:
        return <Notifications sx={{ color: 'grey.600' }} />;
    }
  };

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'high':
        return 'error';
      case 'medium':
        return 'warning';
      case 'low':
        return 'info';
      default:
        return 'default';
    }
  };

  const filteredNotifications = notifications.filter(notification => {
    switch (tabValue) {
      case 0: // All
        return true;
      case 1: // Unread
        return !readNotifications.has(notification.id);
      case 2: // Read
        return readNotifications.has(notification.id);
      default:
        return true;
    }
  });

  const handleMarkAsRead = (notificationId: string) => {
    setReadNotifications(prev => {
      const newSet = new Set(prev);
      newSet.add(notificationId);
      return newSet;
    });
  };

  const handleMarkAllAsRead = () => {
    setReadNotifications(new Set(notifications.map(n => n.id)));
  };

  const handleDeleteNotification = (notificationId: string) => {
    console.log('Deleting notification:', notificationId);
  };

  const unreadCount = notifications.filter(n => !readNotifications.has(n.id)).length;

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h4">
          Notifications
        </Typography>
        <IconButton>
          <Settings />
        </IconButton>
      </Box>

      {/* Action Buttons */}
      {unreadCount > 0 && (
        <Stack direction="row" spacing={2} sx={{ mb: 2 }}>
          <Button
            variant="outlined"
            startIcon={<MarkEmailRead />}
            onClick={handleMarkAllAsRead}
            size="small"
          >
            Mark All as Read
          </Button>
        </Stack>
      )}

      {/* Tabs */}
      <Tabs value={tabValue} onChange={(_, newValue) => setTabValue(newValue)} sx={{ mb: 2 }}>
        <Tab
          label={
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <span>All</span>
              <Badge badgeContent={notifications.length} color="primary" />
            </Box>
          }
        />
        <Tab
          label={
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <span>Unread</span>
              {unreadCount > 0 && <Badge badgeContent={unreadCount} color="error" />}
            </Box>
          }
        />
        <Tab label="Read" />
      </Tabs>

      {/* Notifications List */}
      <List>
        {filteredNotifications.map((notification) => (
          <ListItem
            key={notification.id}
            sx={{
              backgroundColor: readNotifications.has(notification.id) ? 'transparent' : 'action.hover',
              borderRadius: 1,
              mb: 1
            }}
          >
            <ListItemAvatar>
              <Avatar sx={{ backgroundColor: 'transparent' }}>
                {getNotificationIcon(notification.type)}
              </Avatar>
            </ListItemAvatar>

            <ListItemText
              primary={
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 0.5 }}>
                  <Typography variant="subtitle1">
                    {notification.title}
                  </Typography>
                  <Chip
                    label={notification.priority}
                    size="small"
                    color={getPriorityColor(notification.priority) as any}
                  />
                </Box>
              }
              secondary={
                <Box>
                  <Typography variant="body2" color="text.secondary" sx={{ mb: 0.5 }}>
                    {notification.message}
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    {formatDateTime(new Date(notification.timestamp))}
                  </Typography>
                </Box>
              }
            />

            <ListItemSecondaryAction>
              <Stack direction="row" spacing={1}>
                {!readNotifications.has(notification.id) && (
                  <IconButton
                    edge="end"
                    onClick={() => handleMarkAsRead(notification.id)}
                    size="small"
                  >
                    <MarkEmailRead />
                  </IconButton>
                )}
                <IconButton
                  edge="end"
                  onClick={() => handleDeleteNotification(notification.id)}
                  size="small"
                >
                  <Delete />
                </IconButton>
              </Stack>
            </ListItemSecondaryAction>
          </ListItem>
        ))}
      </List>

      {filteredNotifications.length === 0 && (
        <Box sx={{ textAlign: 'center', py: 4 }}>
          <Typography variant="h6" color="text.secondary">
            {tabValue === 1 ? 'No unread notifications' :
              tabValue === 2 ? 'No read notifications' : 'No notifications'}
          </Typography>
          <Typography variant="body2" color="text.secondary">
            {tabValue === 0 ? 'You\'ll see notifications here when they arrive' : ''}
          </Typography>
        </Box>
      )}
    </Box>
  );
};

export default NotificationCenter;