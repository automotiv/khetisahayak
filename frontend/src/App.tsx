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
  const [weather, setWeather] = useState(enhancedMockQuery.weatherData);
  const [content, setContent] = useState(mockQuery.educationalContent);
  const [diagnostics] = useState(mockQuery.diagnosisHistory);
  const [equipment, setEquipment] = useState(enhancedMockQuery.equipmentListings);
  const [news, setNews] = useState<any[]>([]);

  // Helper to map API weather to Enum
  const mapWeatherCondition = (apiCondition: string): any => {
    const condition = apiCondition?.toLowerCase() || '';
    if (condition.includes('clear') || condition.includes('sun')) return 'sunny';
    if (condition.includes('rain') || condition.includes('drizzle')) return 'rainy';
    if (condition.includes('cloud')) return 'cloudy';
    if (condition.includes('storm')) return 'stormy';
    if (condition.includes('fog') || condition.includes('mist')) return 'foggy';
    if (condition.includes('wind')) return 'windy';
    return 'cloudy';
  };

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);
        const lat = 19.9975;
        const lon = 73.7898;

        const [productsData, contentData, equipmentData, weatherRes, newsRes] = await Promise.all([
          khetiApi.getProducts().catch(e => {
            console.error("Failed to fetch products", e);
            return { data: mockQuery.marketplaceProducts };
          }),
          khetiApi.getEducationalContent().catch(e => {
            console.error("Failed to fetch content", e);
            return { data: mockQuery.educationalContent };
          }),
          khetiApi.getEquipmentListings().catch(e => {
            console.error("Failed to fetch equipment", e);
            return { data: enhancedMockQuery.equipmentListings };
          }),
          khetiApi.getWeather(lat, lon).catch(e => {
            console.error("Failed to fetch weather", e);
            return null;
          }),
          khetiApi.getNews().catch(e => {
            console.error("Failed to fetch news", e);
            return { data: [] };
          })
        ]);

        // Transform API products to match expected format
        const transformProducts = (apiProducts: any[]) => {
          return apiProducts.map((p: any) => ({
            id: p.id,
            title: p.name || p.title,
            category: (p.category || 'seeds').toLowerCase().replace(/\s+/g, '_'),
            price: parseFloat(p.price) || 0,
            rating: p.rating || 4.0,
            vendor: p.seller_name || p.vendor || 'Kheti Sahayak',
            imageUrl: p.image_urls?.[0] || p.imageUrl || '/placeholder-product.png',
            inStock: p.is_available ?? p.inStock ?? (p.stock_quantity > 0)
          }));
        };

        if (productsData && productsData.products) {
          setProducts(transformProducts(productsData.products));
        } else if (productsData && productsData.data) {
          setProducts(transformProducts(productsData.data));
        }

        if (contentData && contentData.data) {
          setContent(contentData.data);
        }

        if (equipmentData && equipmentData.data) {
          setEquipment(equipmentData.data);
        }

        if (newsRes && newsRes.data) {
          setNews(newsRes.data);
        }

        if (weatherRes && weatherRes.success) {
          setWeather({
            current: {
              temperature: weatherRes.current.temp,
              humidity: weatherRes.current.humidity,
              windSpeed: weatherRes.current.wind_speed,
              condition: mapWeatherCondition(weatherRes.current.weather),
              precipitation: 0,
              uvIndex: 0
            },
            daily: enhancedMockQuery.weatherData.daily,
            hourly: enhancedMockQuery.weatherData.hourly
          });
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
            news={news}
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
            news={news}
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
