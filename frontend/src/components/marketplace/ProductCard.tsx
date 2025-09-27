import React from 'react';
import { 
  Card, 
  CardMedia, 
  CardContent, 
  CardActions, 
  Typography, 
  Button, 
  Rating,
  Chip,
  Box,
  Stack
} from '@mui/material';
import { ShoppingCart, Verified } from '@mui/icons-material';
import { ProductCategory } from '../../types/enums';
import { formatCurrency } from '../../utils/formatters';

interface ProductCardProps {
  id: string;
  title: string;
  category: ProductCategory;
  price: number;
  rating: number;
  vendor: string;
  imageUrl: string;
  inStock: boolean;
  onAddToCart?: (productId: string) => void;
}

const ProductCard: React.FC<ProductCardProps> = ({
  id,
  title,
  category,
  price,
  rating,
  vendor,
  imageUrl,
  inStock,
  onAddToCart
}) => {
  const handleAddToCart = () => {
    onAddToCart?.(id);
  };

  return (
    <Card sx={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
      <CardMedia
        component="img"
        height="160"
        image={imageUrl}
        alt={title}
      />
      
      <CardContent sx={{ flexGrow: 1 }}>
        <Stack spacing={1}>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <Typography variant="h6" component="div" sx={{ fontSize: '1rem' }}>
              {title}
            </Typography>
            <Chip 
              label={category.replace('_', ' ')}
              size="small"
              color="primary"
              variant="outlined"
            />
          </Box>
          
          <Typography variant="h5" color="primary.main" sx={{ fontWeight: 'bold' }}>
            {formatCurrency(price)}
          </Typography>
          
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <Rating value={rating} precision={0.1} size="small" readOnly />
            <Typography variant="body2" color="text.secondary">
              ({rating})
            </Typography>
          </Box>
          
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <Verified sx={{ fontSize: 16, color: 'success.main' }} />
            <Typography variant="body2" color="text.secondary">
              {vendor}
            </Typography>
          </Box>
          
          {!inStock && (
            <Chip label="Out of Stock" color="error" size="small" />
          )}
        </Stack>
      </CardContent>
      
      <CardActions>
        <Button
          variant="contained"
          startIcon={<ShoppingCart />}
          onClick={handleAddToCart}
          disabled={!inStock}
          fullWidth
        >
          Add to Cart
        </Button>
      </CardActions>
    </Card>
  );
};

export default ProductCard;