import React from 'react';
import { Box, Card, CardContent, Typography, Skeleton, useTheme, alpha } from '@mui/material';
import { TrendingUp, TrendingDown } from '@mui/icons-material';

interface StatCardProps {
  title: string;
  value: string | number;
  subtitle?: string;
  icon: React.ReactNode;
  trend?: number;
  trendLabel?: string;
  badge?: number;
  badgeColor?: 'error' | 'warning' | 'success' | 'info';
  color?: 'primary' | 'secondary' | 'success' | 'warning' | 'error' | 'info';
  loading?: boolean;
}

const StatCard: React.FC<StatCardProps> = ({
  title,
  value,
  subtitle,
  icon,
  trend,
  trendLabel,
  badge,
  badgeColor = 'error',
  color = 'primary',
  loading = false,
}) => {
  const theme = useTheme();
  const colorValue = theme.palette[color].main;

  if (loading) {
    return (
      <Card
        sx={{
          borderRadius: '20px',
          boxShadow: '0 4px 20px rgba(0,0,0,0.08)',
          transition: 'all 0.3s ease',
          height: '100%',
        }}
      >
        <CardContent sx={{ p: 3 }}>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 2 }}>
            <Skeleton variant="circular" width={56} height={56} />
            <Skeleton variant="text" width={60} />
          </Box>
          <Skeleton variant="text" width="60%" height={40} />
          <Skeleton variant="text" width="40%" />
        </CardContent>
      </Card>
    );
  }

  return (
    <Card
      sx={{
        borderRadius: '20px',
        boxShadow: '0 4px 20px rgba(0,0,0,0.08)',
        transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
        height: '100%',
        position: 'relative',
        overflow: 'visible',
        background: `linear-gradient(135deg, ${alpha(colorValue, 0.03)} 0%, #FFFFFF 100%)`,
        border: `1px solid ${alpha(colorValue, 0.1)}`,
        '&:hover': {
          transform: 'translateY(-4px)',
          boxShadow: `0 12px 28px ${alpha(colorValue, 0.15)}`,
        },
      }}
    >
      {badge !== undefined && badge > 0 && (
        <Box
          sx={{
            position: 'absolute',
            top: -8,
            right: -8,
            backgroundColor: theme.palette[badgeColor].main,
            color: '#fff',
            borderRadius: '12px',
            px: 1.5,
            py: 0.5,
            fontSize: '0.75rem',
            fontWeight: 700,
            boxShadow: `0 4px 12px ${alpha(theme.palette[badgeColor].main, 0.4)}`,
            zIndex: 1,
          }}
        >
          {badge}
        </Box>
      )}

      <CardContent sx={{ p: 3, pb: '24px !important' }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 2.5 }}>
          <Box
            sx={{
              width: 56,
              height: 56,
              borderRadius: '16px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              background: `linear-gradient(135deg, ${colorValue} 0%, ${alpha(colorValue, 0.8)} 100%)`,
              boxShadow: `0 8px 16px ${alpha(colorValue, 0.3)}`,
              color: '#fff',
              '& svg': {
                fontSize: 28,
              },
            }}
          >
            {icon}
          </Box>

          {trend !== undefined && (
            <Box
              sx={{
                display: 'flex',
                alignItems: 'center',
                gap: 0.5,
                px: 1.5,
                py: 0.5,
                borderRadius: '8px',
                backgroundColor: alpha(trend >= 0 ? theme.palette.success.main : theme.palette.error.main, 0.1),
                color: trend >= 0 ? theme.palette.success.main : theme.palette.error.main,
              }}
            >
              {trend >= 0 ? (
                <TrendingUp sx={{ fontSize: 16 }} />
              ) : (
                <TrendingDown sx={{ fontSize: 16 }} />
              )}
              <Typography variant="caption" fontWeight={700}>
                {trend >= 0 ? '+' : ''}{trend.toFixed(1)}%
              </Typography>
            </Box>
          )}
        </Box>

        <Typography
          variant="h4"
          sx={{
            fontWeight: 800,
            color: '#1a1a2e',
            mb: 0.5,
            fontFamily: '"DM Sans", sans-serif',
            letterSpacing: '-0.02em',
          }}
        >
          {value}
        </Typography>

        <Typography
          variant="body2"
          sx={{
            color: alpha('#1a1a2e', 0.6),
            fontWeight: 500,
            textTransform: 'uppercase',
            letterSpacing: '0.5px',
            fontSize: '0.75rem',
          }}
        >
          {title}
        </Typography>

        {(subtitle || trendLabel) && (
          <Typography
            variant="caption"
            sx={{
              color: alpha('#1a1a2e', 0.5),
              display: 'block',
              mt: 1,
            }}
          >
            {subtitle || trendLabel}
          </Typography>
        )}
      </CardContent>
    </Card>
  );
};

export default StatCard;
