import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Grid,
  Card,
  CardContent,
  ToggleButton,
  ToggleButtonGroup,
  Skeleton,
  useTheme,
  alpha,
  useMediaQuery,
  Avatar,
  LinearProgress,
  Chip,
} from '@mui/material';
import {
  TrendingUp,
  TrendingDown,
  People,
  Repeat,
  Star,
  ShoppingBag,
} from '@mui/icons-material';
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
  TooltipProps,
} from 'recharts';
import { sellerApi } from '../../services/sellerApi';
import { AnalyticsData, AnalyticsPeriod } from '../../types/seller';
import { formatCurrency } from '../../utils/formatters';
import { OrderStatus } from '../../types/enums';

const periodOptions: { value: AnalyticsPeriod; label: string }[] = [
  { value: '7d', label: '7 Days' },
  { value: '30d', label: '30 Days' },
  { value: '90d', label: '90 Days' },
];

const statusColors: Record<OrderStatus, string> = {
  [OrderStatus.PENDING]: '#FF9800',
  [OrderStatus.CONFIRMED]: '#2196F3',
  [OrderStatus.SHIPPED]: '#4CAF50',
  [OrderStatus.DELIVERED]: '#2E7D32',
  [OrderStatus.CANCELLED]: '#F44336',
  [OrderStatus.RETURNED]: '#9E9E9E',
};

const CustomRevenueTooltip: React.FC<TooltipProps<number, string>> = ({ active, payload, label }) => {
  if (!active || !payload || !payload.length) return null;

  const date = new Date(label);
  const formattedDate = date.toLocaleDateString('en-IN', {
    weekday: 'short',
    day: 'numeric',
    month: 'short',
  });

  return (
    <Box
      sx={{
        background: 'linear-gradient(135deg, #1a1a2e 0%, #16213e 100%)',
        borderRadius: '12px',
        p: 2,
        boxShadow: '0 8px 32px rgba(0,0,0,0.3)',
        border: '1px solid rgba(255,255,255,0.1)',
      }}
    >
      <Typography variant="caption" sx={{ color: 'rgba(255,255,255,0.6)' }}>
        {formattedDate}
      </Typography>
      <Typography variant="h6" sx={{ color: '#4ADE80', fontWeight: 700 }}>
        {formatCurrency(payload[0].value as number)}
      </Typography>
      <Typography variant="caption" sx={{ color: 'rgba(255,255,255,0.8)' }}>
        {payload[0].payload.orders} orders
      </Typography>
    </Box>
  );
};

const SellerAnalytics: React.FC = () => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'));

  const [loading, setLoading] = useState(true);
  const [period, setPeriod] = useState<AnalyticsPeriod>('30d');
  const [analytics, setAnalytics] = useState<AnalyticsData | null>(null);

  useEffect(() => {
    const fetchAnalytics = async () => {
      try {
        setLoading(true);
        const data = await sellerApi.getAnalytics(period);
        setAnalytics(data);
      } catch (error) {
        console.error('Failed to fetch analytics:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchAnalytics();
  }, [period]);

  const handlePeriodChange = (_: React.MouseEvent<HTMLElement>, newPeriod: AnalyticsPeriod | null) => {
    if (newPeriod) setPeriod(newPeriod);
  };

  const formatXAxis = (dateString: string) => {
    const date = new Date(dateString);
    if (period === '7d') {
      return date.toLocaleDateString('en-IN', { weekday: 'short' });
    }
    return date.toLocaleDateString('en-IN', { day: 'numeric', month: 'short' });
  };

  const formatYAxis = (value: number) => {
    if (value >= 100000) return `${(value / 100000).toFixed(0)}L`;
    if (value >= 1000) return `${(value / 1000).toFixed(0)}K`;
    return value.toString();
  };

  const MetricCard: React.FC<{
    title: string;
    value: string | number;
    subtitle?: string;
    icon: React.ReactNode;
    trend?: number;
    color: string;
  }> = ({ title, value, subtitle, icon, trend, color }) => (
    <Card
      sx={{
        borderRadius: '16px',
        boxShadow: '0 4px 16px rgba(0,0,0,0.06)',
        height: '100%',
        border: `1px solid ${alpha(color, 0.1)}`,
      }}
    >
      <CardContent sx={{ p: 2.5 }}>
        <Box sx={{ display: 'flex', alignItems: 'flex-start', gap: 2 }}>
          <Box
            sx={{
              width: 44,
              height: 44,
              borderRadius: '12px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              backgroundColor: alpha(color, 0.1),
              color: color,
            }}
          >
            {icon}
          </Box>
          <Box sx={{ flex: 1 }}>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 0.5 }}>
              {title}
            </Typography>
            <Box sx={{ display: 'flex', alignItems: 'baseline', gap: 1 }}>
              <Typography variant="h5" fontWeight={700}>
                {value}
              </Typography>
              {trend !== undefined && (
                <Chip
                  icon={trend >= 0 ? <TrendingUp sx={{ fontSize: 14 }} /> : <TrendingDown sx={{ fontSize: 14 }} />}
                  label={`${trend >= 0 ? '+' : ''}${trend.toFixed(1)}%`}
                  size="small"
                  sx={{
                    height: 22,
                    fontSize: '0.7rem',
                    fontWeight: 700,
                    backgroundColor: alpha(trend >= 0 ? '#4CAF50' : '#F44336', 0.1),
                    color: trend >= 0 ? '#4CAF50' : '#F44336',
                    '& .MuiChip-icon': { color: 'inherit' },
                  }}
                />
              )}
            </Box>
            {subtitle && (
              <Typography variant="caption" color="text.secondary">
                {subtitle}
              </Typography>
            )}
          </Box>
        </Box>
      </CardContent>
    </Card>
  );

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
          background: 'linear-gradient(135deg, #2196F3 0%, #1565C0 50%, #2196F3 100%)',
          borderRadius: { xs: 0, md: '0 0 32px 32px' },
          px: { xs: 2, md: 4 },
          pt: { xs: 3, md: 4 },
          pb: { xs: 3, md: 4 },
          position: 'relative',
          overflow: 'hidden',
        }}
      >
        <Box
          sx={{
            position: 'absolute',
            top: -60,
            right: -60,
            width: 200,
            height: 200,
            borderRadius: '50%',
            background: 'rgba(255,255,255,0.08)',
          }}
        />

        <Box sx={{ position: 'relative', zIndex: 1 }}>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 2 }}>
            <Box>
              <Typography
                variant={isMobile ? 'h5' : 'h4'}
                sx={{
                  color: '#fff',
                  fontWeight: 800,
                  fontFamily: '"DM Sans", sans-serif',
                }}
              >
                Analytics
              </Typography>
              <Typography variant="body2" sx={{ color: 'rgba(255,255,255,0.8)' }}>
                Track your business performance and insights
              </Typography>
            </Box>

            <ToggleButtonGroup
              value={period}
              exclusive
              onChange={handlePeriodChange}
              size="small"
              sx={{
                backgroundColor: 'rgba(255,255,255,0.15)',
                borderRadius: '12px',
                '& .MuiToggleButton-root': {
                  color: 'rgba(255,255,255,0.7)',
                  border: 'none',
                  px: 2,
                  py: 0.75,
                  fontWeight: 600,
                  textTransform: 'none',
                  '&.Mui-selected': {
                    color: '#2196F3',
                    backgroundColor: '#fff',
                    borderRadius: '10px !important',
                    '&:hover': {
                      backgroundColor: '#fff',
                    },
                  },
                  '&:hover': {
                    backgroundColor: 'rgba(255,255,255,0.1)',
                  },
                },
              }}
            >
              {periodOptions.map((opt) => (
                <ToggleButton key={opt.value} value={opt.value}>
                  {opt.label}
                </ToggleButton>
              ))}
            </ToggleButtonGroup>
          </Box>
        </Box>
      </Box>

      <Box sx={{ px: { xs: 2, md: 4 }, mt: 3 }}>
        {loading ? (
          <Grid container spacing={2}>
            {[...Array(4)].map((_, i) => (
              <Grid item xs={6} md={3} key={i}>
                <Skeleton variant="rectangular" height={120} sx={{ borderRadius: '16px' }} />
              </Grid>
            ))}
          </Grid>
        ) : analytics && (
          <>
            <Grid container spacing={2} sx={{ mb: 3 }}>
              <Grid item xs={6} md={3}>
                <MetricCard
                  title="Total Revenue"
                  value={formatCurrency(analytics.periodComparison.currentRevenue)}
                  trend={analytics.periodComparison.changePercent}
                  icon={<TrendingUp />}
                  color="#2E7D32"
                />
              </Grid>
              <Grid item xs={6} md={3}>
                <MetricCard
                  title="Total Orders"
                  value={analytics.periodComparison.currentOrders}
                  trend={analytics.periodComparison.ordersChangePercent}
                  icon={<ShoppingBag />}
                  color="#FF9800"
                />
              </Grid>
              <Grid item xs={6} md={3}>
                <MetricCard
                  title="Total Customers"
                  value={analytics.customerStats.totalCustomers}
                  subtitle={`${analytics.customerStats.newCustomers} new this period`}
                  icon={<People />}
                  color="#2196F3"
                />
              </Grid>
              <Grid item xs={6} md={3}>
                <MetricCard
                  title="Repeat Rate"
                  value={`${analytics.customerStats.repeatRate}%`}
                  subtitle={`${analytics.customerStats.repeatCustomers} repeat customers`}
                  icon={<Repeat />}
                  color="#9C27B0"
                />
              </Grid>
            </Grid>

            <Card
              sx={{
                borderRadius: '20px',
                boxShadow: '0 4px 20px rgba(0,0,0,0.08)',
                mb: 3,
              }}
            >
              <CardContent sx={{ p: 3 }}>
                <Typography variant="h6" fontWeight={700} sx={{ mb: 2 }}>
                  Revenue Trend
                </Typography>
                <Box sx={{ width: '100%', height: isMobile ? 220 : 300 }}>
                  <ResponsiveContainer>
                    <AreaChart
                      data={analytics.revenueByDay}
                      margin={{ top: 10, right: 10, left: isMobile ? -20 : 0, bottom: 0 }}
                    >
                      <defs>
                        <linearGradient id="analyticsGradient" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="0%" stopColor="#2196F3" stopOpacity={0.4} />
                          <stop offset="100%" stopColor="#2196F3" stopOpacity={0} />
                        </linearGradient>
                      </defs>
                      <CartesianGrid strokeDasharray="3 3" stroke={alpha('#1a1a2e', 0.06)} vertical={false} />
                      <XAxis
                        dataKey="date"
                        tickFormatter={formatXAxis}
                        tick={{ fontSize: 11, fill: alpha('#1a1a2e', 0.5) }}
                        axisLine={{ stroke: alpha('#1a1a2e', 0.1) }}
                        tickLine={false}
                        interval={period === '7d' ? 0 : 'preserveStartEnd'}
                      />
                      <YAxis
                        tickFormatter={formatYAxis}
                        tick={{ fontSize: 11, fill: alpha('#1a1a2e', 0.5) }}
                        axisLine={false}
                        tickLine={false}
                        width={45}
                      />
                      <Tooltip content={<CustomRevenueTooltip />} />
                      <Area
                        type="monotone"
                        dataKey="revenue"
                        stroke="#2196F3"
                        strokeWidth={3}
                        fill="url(#analyticsGradient)"
                        dot={false}
                        activeDot={{ r: 6, fill: '#2196F3', stroke: '#fff', strokeWidth: 3 }}
                      />
                    </AreaChart>
                  </ResponsiveContainer>
                </Box>
              </CardContent>
            </Card>

            <Grid container spacing={3}>
              <Grid item xs={12} md={6}>
                <Card
                  sx={{
                    borderRadius: '20px',
                    boxShadow: '0 4px 20px rgba(0,0,0,0.08)',
                    height: '100%',
                  }}
                >
                  <CardContent sx={{ p: 3 }}>
                    <Typography variant="h6" fontWeight={700} sx={{ mb: 2 }}>
                      Top Products
                    </Typography>
                    <Box sx={{ width: '100%', height: 280 }}>
                      <ResponsiveContainer>
                        <BarChart
                          data={analytics.topProducts.slice(0, 5)}
                          layout="vertical"
                          margin={{ top: 5, right: 30, left: 0, bottom: 5 }}
                        >
                          <CartesianGrid strokeDasharray="3 3" stroke={alpha('#1a1a2e', 0.06)} horizontal={false} />
                          <XAxis
                            type="number"
                            tickFormatter={formatYAxis}
                            tick={{ fontSize: 11, fill: alpha('#1a1a2e', 0.5) }}
                            axisLine={false}
                            tickLine={false}
                          />
                          <YAxis
                            type="category"
                            dataKey="name"
                            tick={{ fontSize: 11, fill: alpha('#1a1a2e', 0.7) }}
                            axisLine={false}
                            tickLine={false}
                            width={100}
                          />
                          <Tooltip
                            formatter={(value: number) => [formatCurrency(value), 'Revenue']}
                            contentStyle={{
                              borderRadius: '12px',
                              border: 'none',
                              boxShadow: '0 4px 16px rgba(0,0,0,0.15)',
                            }}
                          />
                          <Bar
                            dataKey="revenue"
                            fill="#2E7D32"
                            radius={[0, 8, 8, 0]}
                            barSize={24}
                          />
                        </BarChart>
                      </ResponsiveContainer>
                    </Box>
                  </CardContent>
                </Card>
              </Grid>

              <Grid item xs={12} md={6}>
                <Card
                  sx={{
                    borderRadius: '20px',
                    boxShadow: '0 4px 20px rgba(0,0,0,0.08)',
                    height: '100%',
                  }}
                >
                  <CardContent sx={{ p: 3 }}>
                    <Typography variant="h6" fontWeight={700} sx={{ mb: 2 }}>
                      Order Status
                    </Typography>
                    <Grid container spacing={2}>
                      <Grid item xs={6}>
                        <Box sx={{ width: '100%', height: 200 }}>
                          <ResponsiveContainer>
                            <PieChart>
                              <Pie
                                data={analytics.ordersByStatus}
                                cx="50%"
                                cy="50%"
                                innerRadius={50}
                                outerRadius={80}
                                paddingAngle={3}
                                dataKey="count"
                              >
                                {analytics.ordersByStatus.map((entry, index) => (
                                  <Cell key={`cell-${index}`} fill={statusColors[entry.status]} />
                                ))}
                              </Pie>
                              <Tooltip
                                formatter={(value: number, _name: string, props: any) => [
                                  `${value} orders (${props.payload.percentage}%)`,
                                  props.payload.status,
                                ]}
                                contentStyle={{
                                  borderRadius: '12px',
                                  border: 'none',
                                  boxShadow: '0 4px 16px rgba(0,0,0,0.15)',
                                }}
                              />
                            </PieChart>
                          </ResponsiveContainer>
                        </Box>
                      </Grid>
                      <Grid item xs={6}>
                        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1.5 }}>
                          {analytics.ordersByStatus.map((status) => (
                            <Box key={status.status}>
                              <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
                                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                  <Box
                                    sx={{
                                      width: 10,
                                      height: 10,
                                      borderRadius: '3px',
                                      backgroundColor: statusColors[status.status],
                                    }}
                                  />
                                  <Typography variant="caption" sx={{ textTransform: 'capitalize' }}>
                                    {status.status}
                                  </Typography>
                                </Box>
                                <Typography variant="caption" fontWeight={600}>
                                  {status.count}
                                </Typography>
                              </Box>
                              <LinearProgress
                                variant="determinate"
                                value={status.percentage}
                                sx={{
                                  height: 4,
                                  borderRadius: 2,
                                  backgroundColor: alpha(statusColors[status.status], 0.15),
                                  '& .MuiLinearProgress-bar': {
                                    backgroundColor: statusColors[status.status],
                                    borderRadius: 2,
                                  },
                                }}
                              />
                            </Box>
                          ))}
                        </Box>
                      </Grid>
                    </Grid>
                  </CardContent>
                </Card>
              </Grid>
            </Grid>

            <Card
              sx={{
                borderRadius: '20px',
                boxShadow: '0 4px 20px rgba(0,0,0,0.08)',
                mt: 3,
              }}
            >
              <CardContent sx={{ p: 3 }}>
                <Typography variant="h6" fontWeight={700} sx={{ mb: 2 }}>
                  Best Selling Products
                </Typography>
                <Grid container spacing={2}>
                  {analytics.topProducts.map((product, index) => (
                    <Grid item xs={12} sm={6} md={4} key={product.id}>
                      <Box
                        sx={{
                          display: 'flex',
                          alignItems: 'center',
                          gap: 2,
                          p: 2,
                          borderRadius: '14px',
                          backgroundColor: alpha('#f8faf9', 0.8),
                          border: `1px solid ${alpha('#1a1a2e', 0.06)}`,
                        }}
                      >
                        <Box sx={{ position: 'relative' }}>
                          <Avatar
                            src={product.image}
                            sx={{
                              width: 56,
                              height: 56,
                              borderRadius: '12px',
                              backgroundColor: alpha('#2E7D32', 0.1),
                            }}
                          >
                            {product.name.charAt(0)}
                          </Avatar>
                          <Box
                            sx={{
                              position: 'absolute',
                              top: -6,
                              left: -6,
                              width: 20,
                              height: 20,
                              borderRadius: '6px',
                              backgroundColor: index < 3 ? '#FF9800' : '#9E9E9E',
                              color: '#fff',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center',
                              fontSize: '0.7rem',
                              fontWeight: 700,
                            }}
                          >
                            {index + 1}
                          </Box>
                        </Box>
                        <Box sx={{ flex: 1, minWidth: 0 }}>
                          <Typography
                            variant="body2"
                            fontWeight={600}
                            sx={{
                              overflow: 'hidden',
                              textOverflow: 'ellipsis',
                              whiteSpace: 'nowrap',
                            }}
                          >
                            {product.name}
                          </Typography>
                          <Typography variant="caption" color="text.secondary">
                            {product.totalSold} sold
                          </Typography>
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mt: 0.5 }}>
                            <Star sx={{ fontSize: 14, color: '#FF9800' }} />
                            <Typography variant="caption" fontWeight={600}>
                              {product.rating}
                            </Typography>
                          </Box>
                        </Box>
                        <Typography variant="body2" fontWeight={700} color="#2E7D32">
                          {formatCurrency(product.revenue)}
                        </Typography>
                      </Box>
                    </Grid>
                  ))}
                </Grid>
              </CardContent>
            </Card>
          </>
        )}
      </Box>
    </Box>
  );
};

export default SellerAnalytics;
