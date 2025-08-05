import React, { useState } from 'react';
import { 
  Box, 
  AppBar, 
  Toolbar, 
  Typography, 
  IconButton, 
  Badge, 
  BottomNavigation, 
  BottomNavigationAction,
  Drawer,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  Divider
} from '@mui/material';
import { 
  Notifications, 
  Menu, 
  AccountCircle,
  Dashboard,
  WbSunny,
  LocalHospital,
  Storefront,
  School,
  People,
  ChatBubbleOutline,
  Book,
  AccountBalance,
  Lightbulb,
  Share,
  Settings
} from '@mui/icons-material';

interface AppLayoutProps {
  children: React.ReactNode;
  currentTab: number;
  onTabChange: (newValue: number) => void;
  notificationCount?: number;
  showExtendedNavigation?: boolean;
}

const AppLayout: React.FC<AppLayoutProps> = ({ 
  children, 
  currentTab, 
  onTabChange, 
  notificationCount = 0,
  showExtendedNavigation = false
}) => {
  const [sideMenuOpen, setSideMenuOpen] = useState(false);

  const handleSideMenuItemClick = (tabIndex: number) => {
    onTabChange(tabIndex);
    setSideMenuOpen(false);
  };

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', minHeight: '100vh' }}>
      {/* Top App Bar */}
      <AppBar position="fixed" sx={{ zIndex: (theme) => theme.zIndex.drawer + 1 }}>
        <Toolbar>
          <IconButton
            edge="start"
            color="inherit"
            aria-label="menu"
            onClick={() => setSideMenuOpen(!sideMenuOpen)}
            sx={{ mr: 2 }}
          >
            <Menu />
          </IconButton>
          
          <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
            Kheti Sahayak
          </Typography>
          
          <IconButton color="inherit">
            <Badge badgeContent={notificationCount} color="error">
              <Notifications />
            </Badge>
          </IconButton>
          
          <IconButton color="inherit">
            <AccountCircle />
          </IconButton>
        </Toolbar>
      </AppBar>

      {/* Main Content */}
      <Box 
        component="main" 
        sx={{ 
          flexGrow: 1, 
          mt: 8, 
          mb: 8, 
          px: 2, 
          py: 1,
          backgroundColor: 'background.default'
        }}
      >
        {children}
      </Box>

      {/* Side Drawer */}
      <Drawer
        anchor="left"
        open={sideMenuOpen}
        onClose={() => setSideMenuOpen(false)}
      >
        <Box sx={{ width: 280, pt: 8 }}>
          <List>
            <ListItem button onClick={() => handleSideMenuItemClick(0)}>
              <ListItemIcon><Dashboard /></ListItemIcon>
              <ListItemText primary="Dashboard" />
            </ListItem>
            <ListItem button onClick={() => handleSideMenuItemClick(1)}>
              <ListItemIcon><WbSunny /></ListItemIcon>
              <ListItemText primary="Weather" />
            </ListItem>
            <ListItem button onClick={() => handleSideMenuItemClick(2)}>
              <ListItemIcon><LocalHospital /></ListItemIcon>
              <ListItemText primary="Crop Diagnostics" />
            </ListItem>
            <ListItem button onClick={() => handleSideMenuItemClick(3)}>
              <ListItemIcon><Storefront /></ListItemIcon>
              <ListItemText primary="Marketplace" />
            </ListItem>
            <ListItem button onClick={() => handleSideMenuItemClick(4)}>
              <ListItemIcon><School /></ListItemIcon>
              <ListItemText primary="Education" />
            </ListItem>
            <ListItem button onClick={() => handleSideMenuItemClick(5)}>
              <ListItemIcon><People /></ListItemIcon>
              <ListItemText primary="Expert Connect" />
            </ListItem>
            <ListItem button onClick={() => handleSideMenuItemClick(6)}>
              <ListItemIcon><ChatBubbleOutline /></ListItemIcon>
              <ListItemText primary="Community" />
            </ListItem>
            
            <Divider sx={{ my: 1 }} />
            
            <ListItem button onClick={() => handleSideMenuItemClick(7)}>
              <ListItemIcon><Book /></ListItemIcon>
              <ListItemText primary="Digital Logbook" />
            </ListItem>
            <ListItem button onClick={() => handleSideMenuItemClick(8)}>
              <ListItemIcon><AccountBalance /></ListItemIcon>
              <ListItemText primary="Government Schemes" />
            </ListItem>
            <ListItem button onClick={() => handleSideMenuItemClick(9)}>
              <ListItemIcon><Lightbulb /></ListItemIcon>
              <ListItemText primary="Recommendations" />
            </ListItem>
            <ListItem button onClick={() => handleSideMenuItemClick(10)}>
              <ListItemIcon><Share /></ListItemIcon>
              <ListItemText primary="Equipment & Labor" />
            </ListItem>
            <ListItem button onClick={() => handleSideMenuItemClick(11)}>
              <ListItemIcon>
                <Badge badgeContent={notificationCount} color="error">
                  <Notifications />
                </Badge>
              </ListItemIcon>
              <ListItemText primary="Notifications" />
            </ListItem>
            <ListItem button onClick={() => handleSideMenuItemClick(12)}>
              <ListItemIcon><AccountCircle /></ListItemIcon>
              <ListItemText primary="Profile" />
            </ListItem>
          </List>
        </Box>
      </Drawer>

      {/* Bottom Navigation */}
      <BottomNavigation
        value={currentTab > 6 ? -1 : currentTab}
        onChange={(event, newValue) => onTabChange(newValue)}
        sx={{
          position: 'fixed',
          bottom: 0,
          left: 0,
          right: 0,
          zIndex: (theme) => theme.zIndex.drawer + 1,
          borderTop: 1,
          borderColor: 'divider'
        }}
      >
        <BottomNavigationAction 
          label="Dashboard" 
          icon={<Dashboard />} 
        />
        <BottomNavigationAction 
          label="Weather" 
          icon={<WbSunny />} 
        />
        <BottomNavigationAction 
          label="Diagnostics" 
          icon={<LocalHospital />} 
        />
        <BottomNavigationAction 
          label="Marketplace" 
          icon={<Storefront />} 
        />
        <BottomNavigationAction 
          label="Education" 
          icon={<School />} 
        />
        <BottomNavigationAction 
          label="More" 
          icon={<Menu />}
          onClick={() => setSideMenuOpen(true)}
        />
      </BottomNavigation>
    </Box>
  );
};

export default AppLayout;