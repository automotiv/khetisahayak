import React, { useState, useEffect } from 'react';
import { Box, Typography, Card, CardContent, Stack, Chip, CircularProgress } from '@mui/material';
import { TrendingUp, TrendingDown, Store } from '@mui/icons-material';
import { externalApi, MarketPriceData } from '../../services/api';

const MarketPriceWidget: React.FC = () => {
  const [prices, setPrices] = useState<MarketPriceData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchPrices = async () => {
      try {
        setLoading(true);
        const data = await externalApi.getMarketPrices(undefined, 'Maharashtra');
        setPrices(data);
      } catch (error) {
        console.error('Failed to fetch market prices:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchPrices();
  }, []);

  if (loading) {
    return (
      <Card>
        <CardContent sx={{ display: 'flex', justifyContent: 'center', py: 3 }}>
          <CircularProgress size={24} />
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardContent>
        <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <Store color="primary" /> Mandi Prices
          <Chip label="Live" color="success" size="small" />
        </Typography>

        {prices?.prices && prices.prices.length > 0 ? (
          <Stack spacing={1}>
            {prices.prices.slice(0, 5).map((price, index) => (
              <Box
                key={index}
                sx={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  borderBottom: index < 4 ? 1 : 0,
                  borderColor: 'divider',
                  pb: 0.5
                }}
              >
                <Typography variant="body2" fontWeight="medium">
                  {price.commodity}
                </Typography>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                  <Typography variant="body2">
                    {price.modalPrice?.toLocaleString()}
                  </Typography>
                  {price.trend === 'up' ? (
                    <TrendingUp fontSize="small" color="success" />
                  ) : (
                    <TrendingDown fontSize="small" color="error" />
                  )}
                </Box>
              </Box>
            ))}
          </Stack>
        ) : (
          <Typography variant="body2" color="text.secondary">
            No price data available.
          </Typography>
        )}

        <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mt: 1 }}>
          Prices in INR/Quintal | {prices?.source || 'data.gov.in'}
        </Typography>
      </CardContent>
    </Card>
  );
};

export default MarketPriceWidget;
