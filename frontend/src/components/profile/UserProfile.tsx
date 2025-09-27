import React, { useState } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Avatar,
  Button,
  Stack,
  Divider,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  ListItemSecondaryAction,
  Switch,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Chip
} from '@mui/material';
import {
  Edit,
  Settings,
  Notifications,
  Language,
  Security,
  Help,
  Info,
  ExitToApp,
  Person,
  Agriculture,
  LocationOn,
  WbSunny,
  AccountBalance,
  ShoppingCart,
  People,
  Forum,
  Schedule
} from '@mui/icons-material';

interface UserProfileProps {
  user: {
    id: string;
    name: string;
    phone?: string;
    location: {
      village: string;
      district: string;
      state: string;
    };
    crops: string[];
    isVerified: boolean;
  };
  farmProfile: {
    farmSize: number;
    soilType: string;
    irrigationType: string;
  };
  preferences: {
    notificationSettings: {
      weatherAlerts: boolean;
      schemeUpdates: boolean;
      marketplaceUpdates: boolean;
      expertMessages: boolean;
      forumReplies: boolean;
      logbookReminders: boolean;
    };
    language: string;
  };
}

const UserProfile: React.FC<UserProfileProps> = ({ user, farmProfile, preferences }) => {
  const [editDialogOpen, setEditDialogOpen] = useState(false);
  const [editedName, setEditedName] = useState(user.name);
  const [notificationSettings, setNotificationSettings] = useState(preferences.notificationSettings);

  const handleEditProfile = () => {
    setEditDialogOpen(true);
  };

  const handleSaveProfile = () => {
    console.log('Saving profile changes');
    setEditDialogOpen(false);
  };

  const handleNotificationToggle = (setting: keyof typeof notificationSettings) => {
    setNotificationSettings(prev => ({
      ...prev,
      [setting]: !prev[setting]
    }));
  };

  const handleLogout = () => {
    console.log('Logging out');
  };

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Profile
      </Typography>

      {/* User Info Card */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Stack spacing={3}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
              <Avatar sx={{ width: 80, height: 80, backgroundColor: 'primary.main' }}>
                {user.name.charAt(0)}
              </Avatar>
              <Box sx={{ flexGrow: 1 }}>
                <Typography variant="h5" gutterBottom>
                  {user.name}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  {user.location.village}, {user.location.district}, {user.location.state}
                </Typography>
                {user.isVerified && (
                  <Chip label="Verified Farmer" color="success" size="small" sx={{ mt: 1 }} />
                )}
              </Box>
              <IconButton onClick={handleEditProfile}>
                <Edit />
              </IconButton>
            </Box>

            <Divider />

            <Stack spacing={2}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <Agriculture sx={{ color: 'primary.main' }} />
                <Typography variant="body1">
                  Farm Size: {farmProfile.farmSize} acres
                </Typography>
              </Box>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <LocationOn sx={{ color: 'primary.main' }} />
                <Typography variant="body1">
                  Soil: {farmProfile.soilType} | Irrigation: {farmProfile.irrigationType}
                </Typography>
              </Box>
              <Box>
                <Typography variant="body2" color="text.secondary" gutterBottom>
                  Primary Crops:
                </Typography>
                <Stack direction="row" spacing={1}>
                  {user.crops.map((crop) => (
                    <Chip key={crop} label={crop} size="small" variant="outlined" />
                  ))}
                </Stack>
              </Box>
            </Stack>
          </Stack>
        </CardContent>
      </Card>

      {/* Settings */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Notification Settings
          </Typography>
          <List>
            <ListItem>
              <ListItemIcon>
                <WbSunny />
              </ListItemIcon>
              <ListItemText primary="Weather Alerts" />
              <ListItemSecondaryAction>
                <Switch
                  checked={notificationSettings.weatherAlerts}
                  onChange={() => handleNotificationToggle('weatherAlerts')}
                />
              </ListItemSecondaryAction>
            </ListItem>
            
            <ListItem>
              <ListItemIcon>
                <AccountBalance />
              </ListItemIcon>
              <ListItemText primary="Government Scheme Updates" />
              <ListItemSecondaryAction>
                <Switch
                  checked={notificationSettings.schemeUpdates}
                  onChange={() => handleNotificationToggle('schemeUpdates')}
                />
              </ListItemSecondaryAction>
            </ListItem>
            
            <ListItem>
              <ListItemIcon>
                <ShoppingCart />
              </ListItemIcon>
              <ListItemText primary="Marketplace Updates" />
              <ListItemSecondaryAction>
                <Switch
                  checked={notificationSettings.marketplaceUpdates}
                  onChange={() => handleNotificationToggle('marketplaceUpdates')}
                />
              </ListItemSecondaryAction>
            </ListItem>
            
            <ListItem>
              <ListItemIcon>
                <People />
              </ListItemIcon>
              <ListItemText primary="Expert Messages" />
              <ListItemSecondaryAction>
                <Switch
                  checked={notificationSettings.expertMessages}
                  onChange={() => handleNotificationToggle('expertMessages')}
                />
              </ListItemSecondaryAction>
            </ListItem>
            
            <ListItem>
              <ListItemIcon>
                <Forum />
              </ListItemIcon>
              <ListItemText primary="Forum Replies" />
              <ListItemSecondaryAction>
                <Switch
                  checked={notificationSettings.forumReplies}
                  onChange={() => handleNotificationToggle('forumReplies')}
                />
              </ListItemSecondaryAction>
            </ListItem>
            
            <ListItem>
              <ListItemIcon>
                <Schedule />
              </ListItemIcon>
              <ListItemText primary="Logbook Reminders" />
              <ListItemSecondaryAction>
                <Switch
                  checked={notificationSettings.logbookReminders}
                  onChange={() => handleNotificationToggle('logbookReminders')}
                />
              </ListItemSecondaryAction>
            </ListItem>
          </List>
        </CardContent>
      </Card>

      {/* App Settings */}
      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            App Settings
          </Typography>
          <List>
            <ListItem disablePadding>
              <ListItemButton>
              <ListItemIcon>
                <Language />
              </ListItemIcon>
              <ListItemText 
                primary="Language" 
                secondary={preferences.language}
              />
              </ListItemButton>
            </ListItem>
            
            <ListItem disablePadding>
              <ListItemButton>
              <ListItemIcon>
                <Security />
              </ListItemIcon>
              <ListItemText primary="Privacy & Security" />
              </ListItemButton>
            </ListItem>
            
            <ListItem disablePadding>
              <ListItemButton>
              <ListItemIcon>
                <Help />
              </ListItemIcon>
              <ListItemText primary="Help & Support" />
              </ListItemButton>
            </ListItem>
            
            <ListItem disablePadding>
              <ListItemButton>
              <ListItemIcon>
                <Info />
              </ListItemIcon>
              <ListItemText primary="About Kheti Sahayak" />
              </ListItemButton>
            </ListItem>
            
            <Divider sx={{ my: 1 }} />
            
            <ListItem disablePadding>
              <ListItemButton onClick={handleLogout}>
              <ListItemIcon>
                <ExitToApp sx={{ color: 'error.main' }} />
              </ListItemIcon>
              <ListItemText 
                primary="Logout" 
                sx={{ color: 'error.main' }}
              />
              </ListItemButton>
            </ListItem>
          </List>
        </CardContent>
      </Card>

      {/* Edit Profile Dialog */}
      <Dialog open={editDialogOpen} onClose={() => setEditDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Edit Profile</DialogTitle>
        <DialogContent>
          <Stack spacing={3} sx={{ mt: 1 }}>
            <TextField
              fullWidth
              label="Full Name"
              value={editedName}
              onChange={(e) => setEditedName(e.target.value)}
            />
            <TextField
              fullWidth
              label="Phone Number"
              value={user.phone || ''}
              disabled
              helperText="Contact support to change phone number"
            />
            <TextField
              fullWidth
              label="Location"
              value={`${user.location.village}, ${user.location.district}, ${user.location.state}`}
              disabled
              helperText="Contact support to change location"
            />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setEditDialogOpen(false)}>Cancel</Button>
          <Button variant="contained" onClick={handleSaveProfile}>Save Changes</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default UserProfile;