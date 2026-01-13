import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Grid,
  Card,
  CardContent,
  Button,
  useTheme,
  alpha,
  useMediaQuery,
  Chip,
} from '@mui/material';
import {
  ShoppingBag,
  AttachMoney,
  Inventory2,
  Star,
  Add,
  LocalShipping,
  TrendingUp,
  Assessment,
  Settings,
} from '@mui/icons-material';
import StatCard from './components/StatCard';
import RevenueChart from './components/RevenueChart';
import OrdersTable from './components/OrdersTable';
import { sellerApi } from '../../services/sellerApi';
import { SellerStats, SellerOrder, RevenueData } from '../../types/seller';
import { OrderStatus } from '../../types/enums';
import { formatCurrency } from '../../utils/formatters';

interface SellerDashboardProps {
  sellerName?: string;
  onNavigate?: (tab: string) => void;
}

const SellerDashboard: React.FC<SellerDashboardProps> = ({
  sellerName = 'Farmer',
  onNavigate,
}) => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'));
  const isTablet = useMediaQuery(theme.breakpoints.down('md'));

  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState<SellerStats | null>(null);
  const [recentOrders, setRecentOrders] = useState<SellerOrder[]>([]);
  const [revenueData, setRevenueData] = useState<RevenueData[]>([]);

  useEffect(() => {
    const fetchDashboardData = async () => {
      try {
        setLoading(true);
        const [statsData, ordersData, revenue] = await Promise.all([
          sellerApi.getDashboard(),
          sellerApi.getOrders({ limit: 5 }),
          sellerApi.getRevenue('7d'),
        ]);

        setStats(statsData);
        setRecentOrders(ordersData.data);
        setRevenueData(revenue);
      } catch (error) {
        console.error('Failed to fetch dashboard data:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchDashboardData();
  }, []);

  const handleConfirmOrder = async (orderId: string) => {
    try {
      await sellerApi.updateOrderStatus(orderId, OrderStatus.CONFIRMED);
      const updatedOrders = await sellerApi.getOrders({ limit: 5 });
      setRecentOrders(updatedOrders.data);
    } catch (error) {
      console.error('Failed to confirm order:', error);
    }
  };

  const handleShipOrder = async (orderId: string) => {
    try {
      await sellerApi.updateOrderStatus(orderId, OrderStatus.SHIPPED);
      const updatedOrders = await sellerApi.getOrders({ limit: 5 });
      setRecentOrders(updatedOrders.data);
    } catch (error) {
      console.error('Failed to ship order:', error);
    }
  };

  const handleDeliverOrder = async (orderId: string) => {
    try {
      await sellerApi.updateOrderStatus(orderId, OrderStatus.DELIVERED);
      const updatedOrders = await sellerApi.getOrders({ limit: 5 });
      setRecentOrders(updatedOrders.data);
    } catch (error) {
      console.error('Failed to deliver order:', error);
    }
  };

  const getGreeting = () => {
    const hour = new Date().getHours();
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  };

  const quickActions = [
    { icon: <Add />, label: 'Add Product', color: '#2E7D32', action: () => onNavigate?.('inventory') },
    { icon: <LocalShipping />, label: 'Process Orders', color: '#FF9800', action: () => onNavigate?.('orders') },
    { icon: <Assessment />, label: 'View Analytics', color: '#2196F3', action: () => onNavigate?.('analytics') },
    { icon: <Settings />, label: 'Settings', color: '#9C27B0', action: () => {} },
  ];

  return (
    <Box
      sx={{
        minHeight: '100vh',
        background: 'linear-gradient(180deg, #F8FAF9 0%, #EDF5EE 100%)',
        pb: 4,
      }}
    >
      <Box
        sx={{
          background: 'linear-gradient(135deg, #2E7D32 0%, #1B5E20 50%, #2E7D32 100%)',
          borderRadius: { xs: 0, md: '0 0 32px 32px' },
          px: { xs: 2, md: 4 },
          pt: { xs: 3, md: 4 },
          pb: { xs: 8, md: 10 },
          mb: { xs: -6, md: -7 },
          position: 'relative',
          overflow: 'hidden',
        }}
      >
        <Box
          sx={{
            position: 'absolute',
            top: -100,
            right: -100,
            width: 300,
            height: 300,
            borderRadius: '50%',
            background: 'rgba(255,255,255,0.05)',
          }}
        />
        <Box
          sx={{
            position: 'absolute',
            bottom: -50,
            left: -50,
            width: 200,
            height: 200,
            borderRadius: '50%',
            background: 'rgba(255,255,255,0.03)',
          }}
        />

        <Box sx={{ position: 'relative', zIndex: 1 }}>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 1 }}>
            <Box>
              <Typography
                variant="body2"
                sx={{ color: 'rgba(255,255,255,0.8)', mb: 0.5 }}
              >
                {getGreeting()}
              </Typography>
              <Typography
                variant={isMobile ? 'h5' : 'h4'}
                sx={{
                  color: '#fff',
                  fontWeight: 800,
                  fontFamily: '"DM Sans", sans-serif',
                }}
              >
                {sellerName}
              </Typography>
            </Box>
            <Chip
              label="Seller Dashboard"
              size="small"
              sx={{
                backgroundColor: 'rgba(255,255,255,0.15)',
                color: '#fff',
                fontWeight: 600,
                backdropFilter: 'blur(10px)',
              }}
            />
          </Box>

          <Typography
            variant="body2"
            sx={{ color: 'rgba(255,255,255,0.7)', maxWidth: 400 }}
          >
            Manage your products, track orders, and grow your agricultural business
          </Typography>
        </Box>
      </Box>

      <Box sx={{ px: { xs: 2, md: 4 }, position: 'relative', zIndex: 2 }}>
        <Grid container spacing={2}>
          <Grid item xs={6} sm={6} md={3}>
            <StatCard
              title="Total Orders"
              value={stats?.totalOrders || 0}
              icon={<ShoppingBag />}
              badge={stats?.pendingOrders}
              badgeColor="warning"
              color="primary"
              loading={loading}
              subtitle={`${stats?.pendingOrders || 0} pending`}
            />
          </Grid>
          <Grid item xs={6} sm={6} md={3}>
            <StatCard
              title="Revenue"
              value={formatCurrency(stats?.totalRevenue || 0)}
              icon={<AttachMoney />}
              trend={stats?.revenueChange}
              trendLabel="vs last month"
              color="success"
              loading={loading}
            />
          </Grid>
          <Grid item xs={6} sm={6} md={3}>
            <StatCard
              title="Products"
              value={stats?.totalProducts || 0}
              icon={<Inventory2 />}
              badge={stats?.lowStockProducts}
              badgeColor="error"
              color="secondary"
              loading={loading}
              subtitle={`${stats?.lowStockProducts || 0} low stock`}
            />
          </Grid>
          <Grid item xs={6} sm={6} md={3}>
            <StatCard
              title="Rating"
              value={`${stats?.averageRating || 0}`}
              icon={<Star />}
              color="warning"
              loading={loading}
              subtitle={`${stats?.totalReviews || 0} reviews`}
            />
          </Grid>
        </Grid>

        <Grid container spacing={3} sx={{ mt: 1 }}>
          <Grid item xs={12} lg={8}>
            <RevenueChart
              data={revenueData}
              loading={loading}
              title="Revenue (Last 7 Days)"
              height={isMobile ? 220 : 280}
            />
          </Grid>

          <Grid item xs={12} lg={4}>
            <Card
              sx={{
                borderRadius: '20px',
                boxShadow: '0 4px 20px rgba(0,0,0,0.08)',
                height: '100%',
                background: '#FFFFFF',
                border: `1px solid ${alpha('#FF9800', 0.1)}`,
              }}
            >
              <CardContent sx={{ p: 3 }}>
                <Typography variant="h6" fontWeight={700} sx={{ mb: 2.5 }}>
                  Quick Actions
                </Typography>
                <Grid container spacing={1.5}>
                  {quickActions.map((action, index) => (
                    <Grid item xs={6} key={index}>
                      <Button
                        fullWidth
                        onClick={action.action}
                        sx={{
                          py: 2,
                          px: 1.5,
                          borderRadius: '14px',
                          flexDirection: 'column',
                          gap: 1,
                          backgroundColor: alpha(action.color, 0.08),
                          color: action.color,
                          border: `1px solid ${alpha(action.color, 0.15)}`,
                          transition: 'all 0.2s ease',
                          '&:hover': {
                            backgroundColor: alpha(action.color, 0.15),
                            transform: 'translateY(-2px)',
                            boxShadow: `0 4px 12px ${alpha(action.color, 0.2)}`,
                          },
                        }}
                      >
                        <Box
                          sx={{
                            width: 40,
                            height: 40,
                            borderRadius: '12px',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            backgroundColor: alpha(action.color, 0.15),
                          }}
                        >
                          {React.cloneElement(action.icon, { sx: { fontSize: 22 } })}
                        </Box>
                        <Typography
                          variant="caption"
                          fontWeight={600}
                          sx={{ textTransform: 'none' }}
                        >
                          {action.label}
                        </Typography>
                      </Button>
                    </Grid>
                  ))}
                </Grid>
              </CardContent>
            </Card>
          </Grid>
        </Grid>

        <Box sx={{ mt: 3 }}>
          <Box
            sx={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              mb: 2,
            }}
          >
            <Typography variant="h6" fontWeight={700}>
              Recent Orders
            </Typography>
            <Button
              variant="text"
              endIcon={<TrendingUp />}
              onClick={() => onNavigate?.('orders')}
              sx={{ color: '#2E7D32', fontWeight: 600 }}
            >
              View All
            </Button>
          </Box>

          <OrdersTable
            orders={recentOrders}
            loading={loading}
            onConfirmOrder={handleConfirmOrder}
            onShipOrder={handleShipOrder}
            onDeliverOrder={handleDeliverOrder}
            compact={isTablet}
          />
        </Box>
      </Box>
    </Box>
  );
};

export default SellerDashboard;
