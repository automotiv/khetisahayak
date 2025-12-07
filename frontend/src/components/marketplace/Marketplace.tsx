import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  TextField,
  InputAdornment,
  FormControl,
  Select,
  MenuItem,
  InputLabel,
  Stack,
  IconButton,
  Badge,
  Tabs,
  Tab,
  Card,
  CardContent,
  Chip,
  CircularProgress,
  Alert,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper
} from '@mui/material';
import {
  Search,
  ShoppingCart,
  TrendingUp,
  TrendingDown,
  Store,
  Storefront
} from '@mui/icons-material';
import ProductCard from './ProductCard';
import { QueryTypes } from '../../types/schema';
import { ProductCategory } from '../../types/enums';
import { externalApi, MarketPriceData } from '../../services/api';

interface MarketplaceProps {
  products: QueryTypes['marketplaceProducts'];
  state?: string;
}

const Marketplace: React.FC<MarketplaceProps> = ({ products, state = 'Maharashtra' }) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<ProductCategory | 'all'>('all');
  const [sortBy, setSortBy] = useState<'price' | 'rating' | 'name'>('name');
  const [cartCount, setCartCount] = useState(0);
  const [tabValue, setTabValue] = useState(0);

  // Live Mandi Prices State
  const [mandiPrices, setMandiPrices] = useState<MarketPriceData | null>(null);
  const [mandiLoading, setMandiLoading] = useState(false);
  const [selectedState, setSelectedState] = useState(state);
  const [selectedCommodity, setSelectedCommodity] = useState('');

  const states = [
    'Maharashtra', 'Gujarat', 'Rajasthan', 'Madhya Pradesh', 'Uttar Pradesh',
    'Punjab', 'Haryana', 'Karnataka', 'Tamil Nadu', 'Andhra Pradesh'
  ];

  const commodities = [
    '', 'Wheat', 'Rice', 'Onion', 'Tomato', 'Potato', 'Soyabean',
    'Cotton', 'Groundnut', 'Maize', 'Sugarcane'
  ];

  useEffect(() => {
    if (tabValue === 1) {
      fetchMandiPrices();
    }
  }, [tabValue, selectedState, selectedCommodity]);

  const fetchMandiPrices = async () => {
    try {
      setMandiLoading(true);
      const data = await externalApi.getMarketPrices(
        selectedCommodity || undefined,
        selectedState || undefined
      );
      setMandiPrices(data);
    } catch (error) {
      console.error('Failed to fetch mandi prices:', error);
    } finally {
      setMandiLoading(false);
    }
  };

  const filteredProducts = products.filter(product => {
    const matchesSearch = product.title.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesCategory = selectedCategory === 'all' || product.category === selectedCategory;
    return matchesSearch && matchesCategory;
  });

  const sortedProducts = [...filteredProducts].sort((a, b) => {
    switch (sortBy) {
      case 'price':
        return a.price - b.price;
      case 'rating':
        return b.rating - a.rating;
      case 'name':
        return a.title.localeCompare(b.title);
      default:
        return 0;
    }
  });

  const handleAddToCart = (productId: string) => {
    console.log('Adding to cart:', productId);
    setCartCount(prev => prev + 1);
  };

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
        <Typography variant="h4">
          Marketplace
        </Typography>
        <IconButton>
          <Badge badgeContent={cartCount} color="primary">
            <ShoppingCart />
          </Badge>
        </IconButton>
      </Box>

      {/* Tabs */}
      <Tabs value={tabValue} onChange={(_, v) => setTabValue(v)} sx={{ mb: 2 }}>
        <Tab icon={<Storefront />} label="Products" iconPosition="start" />
        <Tab
          icon={<Store />}
          label={
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              Mandi Prices
              <Chip label="Live" color="success" size="small" />
            </Box>
          }
          iconPosition="start"
        />
      </Tabs>

      {/* Products Tab */}
      {tabValue === 0 && (
        <>
          {/* Search and Filters */}
          <Stack spacing={2} sx={{ mb: 3 }}>
            <TextField
              fullWidth
              placeholder="Search products..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <Search />
                  </InputAdornment>
                ),
              }}
            />

            <Stack direction="row" spacing={2}>
              <FormControl size="small" sx={{ minWidth: 120 }}>
                <InputLabel>Category</InputLabel>
                <Select
                  value={selectedCategory}
                  label="Category"
                  onChange={(e) => setSelectedCategory(e.target.value as ProductCategory | 'all')}
                >
                  <MenuItem value="all">All Categories</MenuItem>
                  <MenuItem value={ProductCategory.SEEDS}>Seeds</MenuItem>
                  <MenuItem value={ProductCategory.FERTILIZERS}>Fertilizers</MenuItem>
                  <MenuItem value={ProductCategory.PESTICIDES}>Pesticides</MenuItem>
                  <MenuItem value={ProductCategory.TOOLS}>Tools</MenuItem>
                  <MenuItem value={ProductCategory.FRESH_PRODUCE}>Fresh Produce</MenuItem>
                  <MenuItem value={ProductCategory.SERVICES}>Services</MenuItem>
                </Select>
              </FormControl>

              <FormControl size="small" sx={{ minWidth: 120 }}>
                <InputLabel>Sort by</InputLabel>
                <Select
                  value={sortBy}
                  label="Sort by"
                  onChange={(e) => setSortBy(e.target.value as 'price' | 'rating' | 'name')}
                >
                  <MenuItem value="name">Name</MenuItem>
                  <MenuItem value="price">Price</MenuItem>
                  <MenuItem value="rating">Rating</MenuItem>
                </Select>
              </FormControl>
            </Stack>
          </Stack>

          {/* Products Grid */}
          <Box sx={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))',
            gap: 2
          }}>
            {sortedProducts.map((product) => (
              <ProductCard
                key={product.id}
                id={product.id}
                title={product.title}
                category={product.category}
                price={product.price}
                rating={product.rating}
                vendor={product.vendor}
                imageUrl={product.imageUrl}
                inStock={product.inStock}
                onAddToCart={handleAddToCart}
              />
            ))}
          </Box>

          {sortedProducts.length === 0 && (
            <Box sx={{ textAlign: 'center', py: 4 }}>
              <Typography variant="h6" color="text.secondary">
                No products found
              </Typography>
            </Box>
          )}
        </>
      )}

      {/* Mandi Prices Tab */}
      {tabValue === 1 && (
        <>
          {/* Filters */}
          <Stack direction="row" spacing={2} sx={{ mb: 3 }}>
            <FormControl size="small" sx={{ minWidth: 150 }}>
              <InputLabel>State</InputLabel>
              <Select
                value={selectedState}
                label="State"
                onChange={(e) => setSelectedState(e.target.value)}
              >
                {states.map(s => (
                  <MenuItem key={s} value={s}>{s}</MenuItem>
                ))}
              </Select>
            </FormControl>

            <FormControl size="small" sx={{ minWidth: 150 }}>
              <InputLabel>Commodity</InputLabel>
              <Select
                value={selectedCommodity}
                label="Commodity"
                onChange={(e) => setSelectedCommodity(e.target.value)}
              >
                <MenuItem value="">All Commodities</MenuItem>
                {commodities.filter(c => c).map(c => (
                  <MenuItem key={c} value={c}>{c}</MenuItem>
                ))}
              </Select>
            </FormControl>
          </Stack>

          {mandiLoading ? (
            <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
              <CircularProgress />
            </Box>
          ) : mandiPrices?.prices && mandiPrices.prices.length > 0 ? (
            <>
              <Alert severity="info" sx={{ mb: 2 }}>
                Showing {mandiPrices.prices.length} prices from {mandiPrices.source}
                {mandiPrices.cache?.hit && ' (Cached)'}
              </Alert>

              <TableContainer component={Paper} sx={{ maxHeight: 500 }}>
                <Table stickyHeader size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell>Commodity</TableCell>
                      <TableCell>Market</TableCell>
                      <TableCell align="right">Min (₹)</TableCell>
                      <TableCell align="right">Max (₹)</TableCell>
                      <TableCell align="right">Modal (₹)</TableCell>
                      <TableCell>Date</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {mandiPrices.prices.map((price, index) => (
                      <TableRow key={index} hover>
                        <TableCell>
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            <Typography variant="body2" fontWeight="medium">
                              {price.commodity}
                            </Typography>
                            {price.variety && price.variety !== 'Other' && (
                              <Chip label={price.variety} size="small" variant="outlined" />
                            )}
                          </Box>
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2">{price.market}</Typography>
                          <Typography variant="caption" color="text.secondary">
                            {price.district}
                          </Typography>
                        </TableCell>
                        <TableCell align="right">{price.minPrice?.toLocaleString()}</TableCell>
                        <TableCell align="right">{price.maxPrice?.toLocaleString()}</TableCell>
                        <TableCell align="right">
                          <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'flex-end', gap: 0.5 }}>
                            <Typography variant="body2" fontWeight="medium">
                              {price.modalPrice?.toLocaleString()}
                            </Typography>
                            {price.trend === 'up' ? (
                              <TrendingUp fontSize="small" color="success" />
                            ) : (
                              <TrendingDown fontSize="small" color="error" />
                            )}
                          </Box>
                        </TableCell>
                        <TableCell>
                          <Typography variant="caption">
                            {price.arrivalDate || price.lastUpdated}
                          </Typography>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>

              <Typography variant="caption" color="text.secondary" sx={{ mt: 2, display: 'block' }}>
                Prices in {mandiPrices.unit || 'INR per quintal'} | Source: {mandiPrices.source}
              </Typography>
            </>
          ) : (
            <Alert severity="warning">
              No mandi prices available for the selected filters. Try changing state or commodity.
            </Alert>
          )}
        </>
      )}
    </Box>
  );
};

export default Marketplace;
