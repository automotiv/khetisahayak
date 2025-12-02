import React, { useState, useEffect } from 'react';
import { ThemeProvider } from '@mui/material/styles';
import { CssBaseline, CircularProgress, Box } from '@mui/material';
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
import { khetiApi } from './services/api';

const App: React.FC = () => {
  const [currentTab, setCurrentTab] = useState(0);
  const [isAuthenticated, setIsAuthenticated] = useState(true);

  // Data State
  const [loading, setLoading] = useState(true);
  const [products, setProducts] = useState(mockQuery.marketplaceProducts);
  const [weather] = useState(enhancedMockQuery.weatherData);
  const [content, setContent] = useState(mockQuery.educationalContent);
  const [diagnostics] = useState(mockQuery.diagnosisHistory);
  const [equipment, setEquipment] = useState(enhancedMockQuery.equipmentListings);

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);
        // Fetch data in parallel
        const [productsData, contentData, equipmentData] = await Promise.all([
          khetiApi.getProducts().catch(e => {
            console.error("Failed to fetch products", e);
            return { data: mockQuery.marketplaceProducts }; // Fallback
          }),
          khetiApi.getEducationalContent().catch(e => {
            console.error("Failed to fetch content", e);
            return { data: mockQuery.educationalContent }; // Fallback
          }),
          khetiApi.getEquipmentListings().catch(e => {
            console.error("Failed to fetch equipment", e);
            return { data: enhancedMockQuery.equipmentListings }; // Fallback
          })
        ]);

        if (productsData && productsData.products) {
          setProducts(productsData.products);
        } else if (productsData && productsData.data) {
          setProducts(productsData.data);
        }

        if (contentData && contentData.data) {
          setContent(contentData.data);
        }

        if (equipmentData && equipmentData.data) {
          setEquipment(equipmentData.data);
        }
      } catch (err) {
        console.error("Error fetching data:", err);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  const handleLogin = (phone: string) => {
    console.log('Login successful:', phone);
    setIsAuthenticated(true);
  };

  const renderCurrentTab = () => {
    if (loading) {
      return (
        <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '50vh' }}>
          <CircularProgress />
        </Box>
      );
    }

    switch (currentTab) {
      case 0:
        return (
          <Dashboard
            weatherData={weather}
            diagnosisHistory={diagnostics}
            userName={enhancedMockStore.user.name}
          />
        );
      case 1:
        return (
          <WeatherForecast
            weatherData={weather}
          />
        );
      case 2:
        return (
          <CropDiagnostics
            diagnosisHistory={diagnostics}
          />
        );
      case 3:
        return (
          <Marketplace
            products={products}
          />
        );
      case 4:
        return (
          <EducationalContent
            content={content}
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
            equipment={equipment}
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
            weatherData={weather}
            diagnosisHistory={diagnostics}
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