import React, { useState } from 'react';
import { ThemeProvider } from '@mui/material/styles';
import { CssBaseline } from '@mui/material';
import AppLayout from './components/layout/AppLayout';
import Dashboard from './components/dashboard/Dashboard';
import WeatherForecast from './components/weather/WeatherForecast';
import CropDiagnostics from './components/diagnostics/CropDiagnostics';
import Marketplace from './components/marketplace/Marketplace';
import EducationalContent from './components/education/EducationalContent';
import ExpertConnect from './components/experts/ExpertConnect';
import CommunityForum from './components/forum/CommunityForum';
import DigitalLogbook from './components/logbook/DigitalLogbook';
import GovernmentSchemes from './components/schemes/GovernmentSchemes';
import Recommendations from './components/recommendations/Recommendations';
import SharingPlatform from './components/sharing/SharingPlatform';
import NotificationCenter from './components/notifications/NotificationCenter';
import UserProfile from './components/profile/UserProfile';
import LoginForm from './components/auth/LoginForm';
import theme from './theme/theme';
import { mockQuery } from './data/khetiSahayakMockData';
import { enhancedMockQuery, enhancedMockStore } from './data/enhancedKhetiSahayakMockData';

const App: React.FC = () => {
  const [currentTab, setCurrentTab] = useState(0);
  const [isAuthenticated, setIsAuthenticated] = useState(true); // Set to false to show login

  const handleLogin = (phone: string) => {
    console.log('Login successful:', phone);
    setIsAuthenticated(true);
  };

  const renderCurrentTab = () => {
    switch (currentTab) {
      case 0:
        return (
          <Dashboard
            weatherData={enhancedMockQuery.weatherData}
            diagnosisHistory={mockQuery.diagnosisHistory}
            userName={enhancedMockStore.user.name}
          />
        );
      case 1:
        return (
          <WeatherForecast
            weatherData={enhancedMockQuery.weatherData}
          />
        );
      case 2:
        return (
          <CropDiagnostics
            diagnosisHistory={mockQuery.diagnosisHistory}
          />
        );
      case 3:
        return (
          <Marketplace
            products={mockQuery.marketplaceProducts}
          />
        );
      case 4:
        return (
          <EducationalContent
            content={mockQuery.educationalContent}
          />
        );
      case 5:
        return (
          <ExpertConnect
            experts={mockQuery.experts}
          />
        );
      case 6:
        return (
          <CommunityForum
            posts={mockQuery.forumPosts}
          />
        );
      case 7:
        return (
          <DigitalLogbook
            entries={enhancedMockQuery.logbookEntries}
          />
        );
      case 8:
        return (
          <GovernmentSchemes
            schemes={enhancedMockQuery.governmentSchemes}
          />
        );
      case 9:
        return (
          <Recommendations
            recommendations={enhancedMockQuery.recommendations}
          />
        );
      case 10:
        return (
          <SharingPlatform
            equipment={enhancedMockQuery.equipmentListings}
            labor={enhancedMockQuery.laborProfiles}
          />
        );
      case 11:
        return (
          <NotificationCenter
            notifications={enhancedMockQuery.notifications}
          />
        );
      case 12:
        return (
          <UserProfile
            user={enhancedMockStore.user}
            farmProfile={enhancedMockStore.farmProfile}
            preferences={enhancedMockStore.userPreferences}
          />
        );
      default:
        return (
          <Dashboard
            weatherData={enhancedMockQuery.weatherData}
            diagnosisHistory={mockQuery.diagnosisHistory}
            userName={enhancedMockStore.user.name}
          />
        );
    }
  };

  if (!isAuthenticated) {
    return (
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <LoginForm onLogin={handleLogin} />
      </ThemeProvider>
    );
  }

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <AppLayout
        currentTab={currentTab}
        onTabChange={setCurrentTab}
        notificationCount={enhancedMockQuery.notifications.filter(n => !n.isRead).length}
      >
        {renderCurrentTab()}
      </AppLayout>
    </ThemeProvider>
  );
};

export default App;