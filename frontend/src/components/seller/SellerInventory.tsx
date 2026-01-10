import React, { useState, useEffect, useCallback } from 'react';
import {
  Box,
  Typography,
  TextField,
  InputAdornment,
  Grid,
  Card,
  CardContent,
  CardMedia,
  CardActions,
  Button,
  Chip,
  Stack,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Skeleton,
  useTheme,
  alpha,
  useMediaQuery,
  Snackbar,
  Alert,
  Tooltip,
  Avatar,
  Rating,
  Pagination,
  Checkbox,
  FormControlLabel,
  Menu,
  MenuItem,
  ListItemIcon,
  ListItemText,
} from '@mui/material';
import {
  Search,
  FilterList,
  Add,
  Edit,
  Inventory,
  Warning,
  ErrorOutline,
  CheckCircle,
  MoreVert,
  Remove,
  Refresh,
  Download,
  Delete,
  Visibility,
} from '@mui/icons-material';
import { sellerApi } from '../../services/sellerApi';
import { SellerProduct, InventoryFilter, PaginatedResponse } from '../../types/seller';
import { formatCurrency } from '../../utils/formatters';

const stockFilters = [
  { value: 'all', label: 'All Products', icon: <Inventory />, color: '#1a1a2e' },
  { value: 'in_stock', label: 'In Stock', icon: <CheckCircle />, color: '#4CAF50' },
  { value: 'low_stock', label: 'Low Stock', icon: <Warning />, color: '#FF9800' },
  { value: 'out_of_stock', label: 'Out of Stock', icon: <ErrorOutline />, color: '#F44336' },
];

const SellerInventory: React.FC = () => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'));
  const isTablet = useMediaQuery(theme.breakpoints.down('md'));

  const [loading, setLoading] = useState(true);
  const [products, setProducts] = useState<SellerProduct[]>([]);
  const [pagination, setPagination] = useState({ page: 1, totalPages: 1, total: 0 });
  const [filters, setFilters] = useState<InventoryFilter>({
    stockStatus: 'all',
    search: '',
    page: 1,
    limit: 12,
  });
  const [selectedProducts, setSelectedProducts] = useState<string[]>([]);
  const [stockDialog, setStockDialog] = useState<{ open: boolean; product: SellerProduct | null }>({
    open: false,
    product: null,
  });
  const [newStockQuantity, setNewStockQuantity] = useState<number>(0);
  const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({
    open: false,
    message: '',
    severity: 'success',
  });
  const [menuAnchor, setMenuAnchor] = useState<null | HTMLElement>(null);

  const fetchProducts = useCallback(async () => {
    try {
      setLoading(true);
      const response: PaginatedResponse<SellerProduct> = await sellerApi.getInventory(filters);
      setProducts(response.data);
      setPagination({
        page: response.page,
        totalPages: response.totalPages,
        total: response.total,
      });
    } catch (error) {
      console.error('Failed to fetch inventory:', error);
      setSnackbar({ open: true, message: 'Failed to load inventory', severity: 'error' });
    } finally {
      setLoading(false);
    }
  }, [filters]);

  useEffect(() => {
    fetchProducts();
  }, [fetchProducts]);

  const handleSearchChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setFilters(prev => ({ ...prev, search: event.target.value, page: 1 }));
  };

  const handleFilterChange = (stockStatus: InventoryFilter['stockStatus']) => {
    setFilters(prev => ({ ...prev, stockStatus, page: 1 }));
  };

  const handlePageChange = (_: React.ChangeEvent<unknown>, page: number) => {
    setFilters(prev => ({ ...prev, page }));
  };

  const handleOpenStockDialog = (product: SellerProduct) => {
    setStockDialog({ open: true, product });
    setNewStockQuantity(product.stockQuantity);
  };

  const handleCloseStockDialog = () => {
    setStockDialog({ open: false, product: null });
    setNewStockQuantity(0);
  };

  const handleUpdateStock = async () => {
    if (!stockDialog.product) return;
    
    try {
      await sellerApi.updateStock(stockDialog.product.id, newStockQuantity);
      await fetchProducts();
      setSnackbar({ open: true, message: 'Stock updated successfully', severity: 'success' });
      handleCloseStockDialog();
    } catch (error) {
      console.error('Failed to update stock:', error);
      setSnackbar({ open: true, message: 'Failed to update stock', severity: 'error' });
    }
  };

  const handleSelectProduct = (productId: string) => {
    setSelectedProducts(prev => 
      prev.includes(productId) 
        ? prev.filter(id => id !== productId)
        : [...prev, productId]
    );
  };

  const handleSelectAll = () => {
    if (selectedProducts.length === products.length) {
      setSelectedProducts([]);
    } else {
      setSelectedProducts(products.map(p => p.id));
    }
  };

  const getStockStatus = (product: SellerProduct) => {
    if (product.stockQuantity === 0) return { label: 'Out of Stock', color: '#F44336', bg: '#FFEBEE' };
    if (product.stockQuantity <= product.lowStockThreshold) return { label: 'Low Stock', color: '#FF9800', bg: '#FFF3E0' };
    return { label: 'In Stock', color: '#4CAF50', bg: '#E8F5E9' };
  };

  const getFilterCount = (status: InventoryFilter['stockStatus']) => {
    if (status === 'all') return pagination.total;
    return products.filter(p => {
      if (status === 'out_of_stock') return p.stockQuantity === 0;
      if (status === 'low_stock') return p.stockQuantity > 0 && p.stockQuantity <= p.lowStockThreshold;
      if (status === 'in_stock') return p.stockQuantity > p.lowStockThreshold;
      return true;
    }).length;
  };

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
          background: 'linear-gradient(135deg, #9C27B0 0%, #7B1FA2 50%, #9C27B0 100%)',
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
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <Box>
              <Typography
                variant={isMobile ? 'h5' : 'h4'}
                sx={{
                  color: '#fff',
                  fontWeight: 800,
                  fontFamily: '"DM Sans", sans-serif',
                }}
              >
                Inventory
              </Typography>
              <Typography variant="body2" sx={{ color: 'rgba(255,255,255,0.8)' }}>
                Manage your product stock levels
              </Typography>
            </Box>

            <Box sx={{ display: 'flex', gap: 1 }}>
              <Button
                variant="contained"
                startIcon={<Add />}
                sx={{
                  backgroundColor: 'rgba(255,255,255,0.2)',
                  color: '#fff',
                  borderRadius: '12px',
                  textTransform: 'none',
                  fontWeight: 600,
                  backdropFilter: 'blur(10px)',
                  '&:hover': {
                    backgroundColor: 'rgba(255,255,255,0.3)',
                  },
                }}
              >
                {!isMobile && 'Add Product'}
              </Button>
              <IconButton
                onClick={(e) => setMenuAnchor(e.currentTarget)}
                sx={{
                  backgroundColor: 'rgba(255,255,255,0.15)',
                  color: '#fff',
                  '&:hover': { backgroundColor: 'rgba(255,255,255,0.25)' },
                }}
              >
                <MoreVert />
              </IconButton>
            </Box>
          </Box>
        </Box>
      </Box>

      <Menu
        anchorEl={menuAnchor}
        open={Boolean(menuAnchor)}
        onClose={() => setMenuAnchor(null)}
        PaperProps={{ sx: { borderRadius: '12px', minWidth: 180 } }}
      >
        <MenuItem onClick={() => { fetchProducts(); setMenuAnchor(null); }}>
          <ListItemIcon><Refresh fontSize="small" /></ListItemIcon>
          <ListItemText>Refresh</ListItemText>
        </MenuItem>
        <MenuItem onClick={() => setMenuAnchor(null)}>
          <ListItemIcon><Download fontSize="small" /></ListItemIcon>
          <ListItemText>Export</ListItemText>
        </MenuItem>
      </Menu>

      <Box sx={{ px: { xs: 2, md: 4 }, mt: 3 }}>
        <Card
          sx={{
            borderRadius: '20px',
            boxShadow: '0 4px 20px rgba(0,0,0,0.08)',
            mb: 3,
            overflow: 'visible',
          }}
        >
          <CardContent sx={{ p: 2.5 }}>
            <Stack spacing={2}>
              <TextField
                fullWidth
                placeholder="Search products by name, category..."
                value={filters.search}
                onChange={handleSearchChange}
                size="small"
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <Search sx={{ color: 'text.secondary' }} />
                    </InputAdornment>
                  ),
                }}
                sx={{
                  '& .MuiOutlinedInput-root': {
                    borderRadius: '12px',
                    backgroundColor: alpha('#f8faf9', 0.8),
                    '& fieldset': {
                      borderColor: alpha('#1a1a2e', 0.1),
                    },
                  },
                }}
              />

              <Stack direction="row" spacing={1} flexWrap="wrap" useFlexGap>
                {stockFilters.map((filter) => (
                  <Chip
                    key={filter.value}
                    icon={React.cloneElement(filter.icon, { sx: { fontSize: 18 } })}
                    label={
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                        {filter.label}
                        <Box
                          component="span"
                          sx={{
                            backgroundColor: alpha(filter.color, 0.15),
                            color: filter.color,
                            borderRadius: '6px',
                            px: 0.75,
                            py: 0.25,
                            fontSize: '0.7rem',
                            fontWeight: 700,
                            ml: 0.5,
                          }}
                        >
                          {getFilterCount(filter.value as InventoryFilter['stockStatus'])}
                        </Box>
                      </Box>
                    }
                    onClick={() => handleFilterChange(filter.value as InventoryFilter['stockStatus'])}
                    variant={filters.stockStatus === filter.value ? 'filled' : 'outlined'}
                    sx={{
                      borderRadius: '10px',
                      fontWeight: 600,
                      borderColor: filters.stockStatus === filter.value ? filter.color : alpha('#1a1a2e', 0.15),
                      backgroundColor: filters.stockStatus === filter.value ? alpha(filter.color, 0.1) : 'transparent',
                      color: filters.stockStatus === filter.value ? filter.color : 'text.secondary',
                      '& .MuiChip-icon': {
                        color: filters.stockStatus === filter.value ? filter.color : 'text.secondary',
                      },
                      '&:hover': {
                        backgroundColor: alpha(filter.color, 0.1),
                      },
                    }}
                  />
                ))}
              </Stack>
            </Stack>
          </CardContent>
        </Card>

        {selectedProducts.length > 0 && (
          <Card
            sx={{
              borderRadius: '16px',
              boxShadow: '0 4px 20px rgba(0,0,0,0.08)',
              mb: 3,
              backgroundColor: alpha('#9C27B0', 0.05),
              border: `1px solid ${alpha('#9C27B0', 0.2)}`,
            }}
          >
            <CardContent sx={{ p: 2, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                <FormControlLabel
                  control={
                    <Checkbox
                      checked={selectedProducts.length === products.length}
                      indeterminate={selectedProducts.length > 0 && selectedProducts.length < products.length}
                      onChange={handleSelectAll}
                    />
                  }
                  label={`${selectedProducts.length} selected`}
                />
              </Box>
              <Stack direction="row" spacing={1}>
                <Button size="small" startIcon={<Edit />} sx={{ textTransform: 'none' }}>
                  Bulk Edit
                </Button>
                <Button size="small" color="error" startIcon={<Delete />} sx={{ textTransform: 'none' }}>
                  Delete
                </Button>
              </Stack>
            </CardContent>
          </Card>
        )}

        {loading ? (
          <Grid container spacing={2}>
            {[...Array(6)].map((_, i) => (
              <Grid item xs={12} sm={6} md={4} lg={3} key={i}>
                <Card sx={{ borderRadius: '16px' }}>
                  <Skeleton variant="rectangular" height={160} />
                  <CardContent>
                    <Skeleton variant="text" width="80%" />
                    <Skeleton variant="text" width="60%" />
                    <Skeleton variant="text" width="40%" />
                  </CardContent>
                </Card>
              </Grid>
            ))}
          </Grid>
        ) : products.length === 0 ? (
          <Box
            sx={{
              textAlign: 'center',
              py: 8,
              px: 3,
              backgroundColor: alpha(theme.palette.grey[100], 0.5),
              borderRadius: '20px',
            }}
          >
            <Inventory sx={{ fontSize: 72, color: alpha('#1a1a2e', 0.2), mb: 2 }} />
            <Typography variant="h5" fontWeight={700} gutterBottom>
              No products found
            </Typography>
            <Typography variant="body1" color="text.secondary" sx={{ mb: 3 }}>
              {filters.search || filters.stockStatus !== 'all'
                ? 'Try adjusting your search or filters'
                : 'Start adding products to your inventory'}
            </Typography>
            <Button
              variant="contained"
              startIcon={<Add />}
              sx={{
                backgroundColor: '#9C27B0',
                borderRadius: '12px',
                textTransform: 'none',
                fontWeight: 600,
                px: 4,
              }}
            >
              Add Your First Product
            </Button>
          </Box>
        ) : (
          <Grid container spacing={2}>
            {products.map((product) => {
              const stockStatus = getStockStatus(product);
              const isSelected = selectedProducts.includes(product.id);

              return (
                <Grid item xs={12} sm={6} md={4} lg={3} key={product.id}>
                  <Card
                    sx={{
                      borderRadius: '16px',
                      boxShadow: isSelected ? `0 0 0 2px #9C27B0` : '0 4px 16px rgba(0,0,0,0.06)',
                      transition: 'all 0.2s ease',
                      height: '100%',
                      display: 'flex',
                      flexDirection: 'column',
                      position: 'relative',
                      overflow: 'visible',
                      '&:hover': {
                        transform: 'translateY(-4px)',
                        boxShadow: '0 12px 28px rgba(0,0,0,0.12)',
                      },
                    }}
                  >
                    <Checkbox
                      checked={isSelected}
                      onChange={() => handleSelectProduct(product.id)}
                      sx={{
                        position: 'absolute',
                        top: 8,
                        left: 8,
                        zIndex: 2,
                        backgroundColor: 'rgba(255,255,255,0.9)',
                        borderRadius: '8px',
                        '&:hover': { backgroundColor: '#fff' },
                      }}
                    />

                    <Box sx={{ position: 'relative' }}>
                      <CardMedia
                        component="img"
                        height={140}
                        image={product.images[0] || '/placeholder-product.png'}
                        alt={product.name}
                        sx={{
                          objectFit: 'cover',
                          borderRadius: '16px 16px 0 0',
                        }}
                      />
                      <Chip
                        label={stockStatus.label}
                        size="small"
                        sx={{
                          position: 'absolute',
                          top: 8,
                          right: 8,
                          backgroundColor: stockStatus.bg,
                          color: stockStatus.color,
                          fontWeight: 700,
                          fontSize: '0.7rem',
                        }}
                      />
                      {product.originalPrice && product.originalPrice > product.price && (
                        <Chip
                          label={`${Math.round((1 - product.price / product.originalPrice) * 100)}% OFF`}
                          size="small"
                          sx={{
                            position: 'absolute',
                            bottom: 8,
                            left: 8,
                            backgroundColor: '#F44336',
                            color: '#fff',
                            fontWeight: 700,
                            fontSize: '0.65rem',
                          }}
                        />
                      )}
                    </Box>

                    <CardContent sx={{ flexGrow: 1, p: 2 }}>
                      <Typography
                        variant="subtitle1"
                        fontWeight={700}
                        sx={{
                          overflow: 'hidden',
                          textOverflow: 'ellipsis',
                          whiteSpace: 'nowrap',
                          mb: 0.5,
                        }}
                      >
                        {product.name}
                      </Typography>

                      <Chip
                        label={product.category}
                        size="small"
                        variant="outlined"
                        sx={{
                          borderRadius: '6px',
                          fontSize: '0.7rem',
                          height: 22,
                          textTransform: 'capitalize',
                          mb: 1,
                        }}
                      />

                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
                        <Typography variant="h6" fontWeight={800} color="#2E7D32">
                          {formatCurrency(product.price)}
                        </Typography>
                        {product.originalPrice && product.originalPrice > product.price && (
                          <Typography
                            variant="body2"
                            color="text.secondary"
                            sx={{ textDecoration: 'line-through' }}
                          >
                            {formatCurrency(product.originalPrice)}
                          </Typography>
                        )}
                      </Box>

                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1.5 }}>
                        <Rating value={product.rating} precision={0.1} size="small" readOnly />
                        <Typography variant="caption" color="text.secondary">
                          ({product.reviewCount})
                        </Typography>
                      </Box>

                      <Box
                        sx={{
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'space-between',
                          p: 1.5,
                          borderRadius: '10px',
                          backgroundColor: alpha(stockStatus.color, 0.08),
                          border: `1px solid ${alpha(stockStatus.color, 0.15)}`,
                        }}
                      >
                        <Box>
                          <Typography variant="caption" color="text.secondary">
                            Stock
                          </Typography>
                          <Typography variant="h6" fontWeight={700} sx={{ color: stockStatus.color }}>
                            {product.stockQuantity} {product.unit}s
                          </Typography>
                        </Box>
                        <Tooltip title="Update Stock">
                          <IconButton
                            size="small"
                            onClick={() => handleOpenStockDialog(product)}
                            sx={{
                              backgroundColor: alpha(stockStatus.color, 0.15),
                              color: stockStatus.color,
                              '&:hover': { backgroundColor: alpha(stockStatus.color, 0.25) },
                            }}
                          >
                            <Edit fontSize="small" />
                          </IconButton>
                        </Tooltip>
                      </Box>
                    </CardContent>

                    <CardActions sx={{ p: 2, pt: 0 }}>
                      <Button
                        fullWidth
                        variant="outlined"
                        startIcon={<Visibility />}
                        sx={{
                          borderRadius: '10px',
                          textTransform: 'none',
                          fontWeight: 600,
                          borderColor: alpha('#1a1a2e', 0.15),
                          '&:hover': {
                            borderColor: '#9C27B0',
                            backgroundColor: alpha('#9C27B0', 0.05),
                          },
                        }}
                      >
                        View Details
                      </Button>
                    </CardActions>
                  </Card>
                </Grid>
              );
            })}
          </Grid>
        )}

        {pagination.totalPages > 1 && (
          <Box sx={{ display: 'flex', justifyContent: 'center', mt: 4 }}>
            <Pagination
              count={pagination.totalPages}
              page={pagination.page}
              onChange={handlePageChange}
              color="primary"
              shape="rounded"
              sx={{
                '& .MuiPaginationItem-root': {
                  fontWeight: 600,
                  borderRadius: '10px',
                  '&.Mui-selected': {
                    backgroundColor: '#9C27B0',
                    color: '#fff',
                    '&:hover': {
                      backgroundColor: '#7B1FA2',
                    },
                  },
                },
              }}
            />
          </Box>
        )}
      </Box>

      <Dialog
        open={stockDialog.open}
        onClose={handleCloseStockDialog}
        PaperProps={{
          sx: {
            borderRadius: '20px',
            minWidth: { xs: '90%', sm: 400 },
          },
        }}
      >
        <DialogTitle sx={{ pb: 1 }}>
          <Typography variant="h6" fontWeight={700}>
            Update Stock
          </Typography>
          {stockDialog.product && (
            <Typography variant="body2" color="text.secondary">
              {stockDialog.product.name}
            </Typography>
          )}
        </DialogTitle>
        <DialogContent>
          <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 2, py: 3 }}>
            <IconButton
              onClick={() => setNewStockQuantity(prev => Math.max(0, prev - 1))}
              sx={{
                width: 48,
                height: 48,
                backgroundColor: alpha('#F44336', 0.1),
                color: '#F44336',
                '&:hover': { backgroundColor: alpha('#F44336', 0.2) },
              }}
            >
              <Remove />
            </IconButton>
            <TextField
              type="number"
              value={newStockQuantity}
              onChange={(e) => setNewStockQuantity(Math.max(0, parseInt(e.target.value) || 0))}
              inputProps={{
                min: 0,
                style: { textAlign: 'center', fontSize: '1.5rem', fontWeight: 700 },
              }}
              sx={{
                width: 120,
                '& .MuiOutlinedInput-root': {
                  borderRadius: '12px',
                },
              }}
            />
            <IconButton
              onClick={() => setNewStockQuantity(prev => prev + 1)}
              sx={{
                width: 48,
                height: 48,
                backgroundColor: alpha('#4CAF50', 0.1),
                color: '#4CAF50',
                '&:hover': { backgroundColor: alpha('#4CAF50', 0.2) },
              }}
            >
              <Add />
            </IconButton>
          </Box>
          {stockDialog.product && (
            <Typography variant="caption" color="text.secondary" textAlign="center" display="block">
              Current: {stockDialog.product.stockQuantity} {stockDialog.product.unit}s | 
              Low stock threshold: {stockDialog.product.lowStockThreshold}
            </Typography>
          )}
        </DialogContent>
        <DialogActions sx={{ p: 2.5, pt: 1 }}>
          <Button
            onClick={handleCloseStockDialog}
            sx={{ borderRadius: '10px', textTransform: 'none' }}
          >
            Cancel
          </Button>
          <Button
            variant="contained"
            onClick={handleUpdateStock}
            sx={{
              borderRadius: '10px',
              textTransform: 'none',
              fontWeight: 600,
              backgroundColor: '#9C27B0',
              '&:hover': { backgroundColor: '#7B1FA2' },
            }}
          >
            Update Stock
          </Button>
        </DialogActions>
      </Dialog>

      <Snackbar
        open={snackbar.open}
        autoHideDuration={4000}
        onClose={() => setSnackbar(prev => ({ ...prev, open: false }))}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        <Alert
          onClose={() => setSnackbar(prev => ({ ...prev, open: false }))}
          severity={snackbar.severity}
          sx={{ borderRadius: '12px', fontWeight: 600 }}
        >
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default SellerInventory;
