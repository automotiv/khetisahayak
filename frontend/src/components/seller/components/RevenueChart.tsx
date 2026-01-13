import React from 'react';
import { Box, Card, CardContent, Typography, Skeleton, useTheme, alpha, useMediaQuery } from '@mui/material';
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';
import { RevenueData } from '../../../types/seller';
import { formatCurrency } from '../../../utils/formatters';

interface RevenueChartProps {
  data: RevenueData[];
  loading?: boolean;
  title?: string;
  height?: number;
}

const CustomTooltip = (props: any) => {
  const { active, payload, label } = props;
  if (!active || !payload || !payload.length) return null;

  const data = payload[0].payload as RevenueData;
  const date = new Date(label as string);
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
        minWidth: 160,
      }}
    >
      <Typography
        variant="caption"
        sx={{ color: 'rgba(255,255,255,0.6)', display: 'block', mb: 1 }}
      >
        {formattedDate}
      </Typography>
      <Typography
        variant="h6"
        sx={{ color: '#4ADE80', fontWeight: 700, mb: 0.5 }}
      >
        {formatCurrency(data.revenue)}
      </Typography>
      <Typography variant="caption" sx={{ color: 'rgba(255,255,255,0.8)' }}>
        {data.orders} orders
      </Typography>
    </Box>
  );
};

const RevenueChart: React.FC<RevenueChartProps> = ({
  data,
  loading = false,
  title = 'Revenue Overview',
  height = 300,
}) => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'));

  const formatXAxis = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-IN', { day: 'numeric', month: 'short' });
  };

  const formatYAxis = (value: number) => {
    if (value >= 100000) return `${(value / 100000).toFixed(0)}L`;
    if (value >= 1000) return `${(value / 1000).toFixed(0)}K`;
    return value.toString();
  };

  if (loading) {
    return (
      <Card
        sx={{
          borderRadius: '20px',
          boxShadow: '0 4px 20px rgba(0,0,0,0.08)',
          height: '100%',
        }}
      >
        <CardContent sx={{ p: 3 }}>
          <Skeleton variant="text" width={180} height={32} sx={{ mb: 2 }} />
          <Skeleton variant="rectangular" height={height} sx={{ borderRadius: 2 }} />
        </CardContent>
      </Card>
    );
  }

  const totalRevenue = data.reduce((sum, item) => sum + item.revenue, 0);
  const totalOrders = data.reduce((sum, item) => sum + item.orders, 0);

  return (
    <Card
      sx={{
        borderRadius: '20px',
        boxShadow: '0 4px 20px rgba(0,0,0,0.08)',
        height: '100%',
        background: '#FFFFFF',
        border: `1px solid ${alpha('#2E7D32', 0.08)}`,
      }}
    >
      <CardContent sx={{ p: 3 }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 3 }}>
          <Box>
            <Typography
              variant="h6"
              sx={{
                fontWeight: 700,
                color: '#1a1a2e',
                mb: 0.5,
              }}
            >
              {title}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Last {data.length} days performance
            </Typography>
          </Box>

          <Box sx={{ textAlign: 'right' }}>
            <Typography
              variant="h5"
              sx={{
                fontWeight: 800,
                color: '#2E7D32',
                fontFamily: '"DM Sans", sans-serif',
              }}
            >
              {formatCurrency(totalRevenue)}
            </Typography>
            <Typography variant="caption" color="text.secondary">
              {totalOrders} total orders
            </Typography>
          </Box>
        </Box>

        <Box sx={{ width: '100%', height }}>
          <ResponsiveContainer>
            <AreaChart
              data={data}
              margin={{
                top: 10,
                right: isMobile ? 0 : 10,
                left: isMobile ? -20 : 0,
                bottom: 0,
              }}
            >
              <defs>
                <linearGradient id="revenueGradient" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#2E7D32" stopOpacity={0.4} />
                  <stop offset="50%" stopColor="#2E7D32" stopOpacity={0.15} />
                  <stop offset="100%" stopColor="#2E7D32" stopOpacity={0} />
                </linearGradient>
                <linearGradient id="strokeGradient" x1="0" y1="0" x2="1" y2="0">
                  <stop offset="0%" stopColor="#2E7D32" />
                  <stop offset="50%" stopColor="#4ADE80" />
                  <stop offset="100%" stopColor="#2E7D32" />
                </linearGradient>
              </defs>
              
              <CartesianGrid
                strokeDasharray="3 3"
                stroke={alpha('#1a1a2e', 0.06)}
                vertical={false}
              />
              
              <XAxis
                dataKey="date"
                tickFormatter={formatXAxis}
                tick={{ fontSize: 11, fill: alpha('#1a1a2e', 0.5) }}
                axisLine={{ stroke: alpha('#1a1a2e', 0.1) }}
                tickLine={false}
                interval={isMobile ? 2 : 1}
              />
              
              <YAxis
                tickFormatter={formatYAxis}
                tick={{ fontSize: 11, fill: alpha('#1a1a2e', 0.5) }}
                axisLine={false}
                tickLine={false}
                width={45}
              />
              
              <Tooltip content={<CustomTooltip />} />
              
              <Area
                type="monotone"
                dataKey="revenue"
                stroke="url(#strokeGradient)"
                strokeWidth={3}
                fill="url(#revenueGradient)"
                dot={false}
                activeDot={{
                  r: 6,
                  fill: '#2E7D32',
                  stroke: '#fff',
                  strokeWidth: 3,
                  style: { filter: 'drop-shadow(0 4px 8px rgba(46, 125, 50, 0.4))' },
                }}
              />
            </AreaChart>
          </ResponsiveContainer>
        </Box>
      </CardContent>
    </Card>
  );
};

export default RevenueChart;
