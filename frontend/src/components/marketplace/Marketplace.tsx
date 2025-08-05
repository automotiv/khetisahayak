import React, { useState } from 'react';
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
  Chip,
  IconButton,
  Badge
} from '@mui/material';
import { Search, FilterList, ShoppingCart } from '@mui/icons-material';
import ProductCard from './ProductCard';
import { QueryTypes } from '../../types/schema';
import { ProductCategory } from '../../types/enums';

interface MarketplaceProps {
  products: QueryTypes['marketplaceProducts'];
}

const Marketplace: React.FC<MarketplaceProps> = ({ products }) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<ProductCategory | 'all'>('all');
  const [sortBy, setSortBy] = useState<'price' | 'rating' | 'name'>('name');
  const [cartCount, setCartCount] = useState(0);

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
    setCartCount(prev => prev + 1);
  };

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h4">
          Marketplace
        </Typography>
        <IconButton>
          <Badge badgeContent={cartCount} color="primary">
            <ShoppingCart />
          </Badge>
        </IconButton>
      </Box>

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
          <Typography variant="body2" color="text.secondary">
            Try adjusting your search or filters
          </Typography>
        </Box>
      )}
    </Box>
  );
};

export default Marketplace;