import React, { useState, useEffect, useCallback } from 'react';
import {
  Box,
  Typography,
  Tabs,
  Tab,
  TextField,
  InputAdornment,
  Pagination,
  Skeleton,
  useTheme,
  alpha,
  useMediaQuery,
  Chip,
  Card,
  IconButton,
  Menu,
  MenuItem,
  ListItemIcon,
  ListItemText,
  Snackbar,
  Alert,
} from '@mui/material';
import {
  Search,
  FilterList,
  Refresh,
  Download,
  CheckCircle,
  LocalShipping,
  MoreVert,
  AccessTime,
  Done,
  DoNotDisturb,
} from '@mui/icons-material';
import OrdersTable from './components/OrdersTable';
import { sellerApi } from '../../services/sellerApi';
import { SellerOrder, OrdersFilter, PaginatedResponse } from '../../types/seller';
import { OrderStatus } from '../../types/enums';

const statusTabs = [
  { value: 'all', label: 'All Orders', icon: <FilterList /> },
  { value: OrderStatus.PENDING, label: 'Pending', icon: <AccessTime />, color: '#FF9800' },
  { value: OrderStatus.CONFIRMED, label: 'Confirmed', icon: <CheckCircle />, color: '#2196F3' },
  { value: OrderStatus.SHIPPED, label: 'Shipped', icon: <LocalShipping />, color: '#4CAF50' },
  { value: OrderStatus.DELIVERED, label: 'Delivered', icon: <Done />, color: '#2E7D32' },
  { value: OrderStatus.CANCELLED, label: 'Cancelled', icon: <DoNotDisturb />, color: '#F44336' },
];

const SellerOrders: React.FC = () => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'));

  const [loading, setLoading] = useState(true);
  const [orders, setOrders] = useState<SellerOrder[]>([]);
  const [pagination, setPagination] = useState({ page: 1, totalPages: 1, total: 0 });
  const [filters, setFilters] = useState<OrdersFilter>({
    status: 'all',
    search: '',
    page: 1,
    limit: 10,
  });
  const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({
    open: false,
    message: '',
    severity: 'success',
  });
  const [menuAnchor, setMenuAnchor] = useState<null | HTMLElement>(null);

  const fetchOrders = useCallback(async () => {
    try {
      setLoading(true);
      const response: PaginatedResponse<SellerOrder> = await sellerApi.getOrders(filters);
      setOrders(response.data);
      setPagination({
        page: response.page,
        totalPages: response.totalPages,
        total: response.total,
      });
    } catch (error) {
      console.error('Failed to fetch orders:', error);
      setSnackbar({ open: true, message: 'Failed to load orders', severity: 'error' });
    } finally {
      setLoading(false);
    }
  }, [filters]);

  useEffect(() => {
    fetchOrders();
  }, [fetchOrders]);

  const handleTabChange = (_: React.SyntheticEvent, newValue: OrderStatus | 'all') => {
    setFilters(prev => ({ ...prev, status: newValue, page: 1 }));
  };

  const handleSearchChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setFilters(prev => ({ ...prev, search: event.target.value, page: 1 }));
  };

  const handlePageChange = (_: React.ChangeEvent<unknown>, page: number) => {
    setFilters(prev => ({ ...prev, page }));
  };

  const updateOrderStatus = async (orderId: string, newStatus: OrderStatus) => {
    try {
      await sellerApi.updateOrderStatus(orderId, newStatus);
      await fetchOrders();
      setSnackbar({ open: true, message: `Order status updated to ${newStatus}`, severity: 'success' });
    } catch (error) {
      console.error('Failed to update order:', error);
      setSnackbar({ open: true, message: 'Failed to update order status', severity: 'error' });
    }
  };

  const handleConfirmOrder = (orderId: string) => updateOrderStatus(orderId, OrderStatus.CONFIRMED);
  const handleShipOrder = (orderId: string) => updateOrderStatus(orderId, OrderStatus.SHIPPED);
  const handleDeliverOrder = (orderId: string) => updateOrderStatus(orderId, OrderStatus.DELIVERED);

  const getStatusCount = (status: OrderStatus | 'all') => {
    if (status === 'all') return pagination.total;
    return orders.filter(o => o.status === status).length;
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
          background: 'linear-gradient(135deg, #FF9800 0%, #F57C00 50%, #FF9800 100%)',
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
                Order Management
              </Typography>
              <Typography variant="body2" sx={{ color: 'rgba(255,255,255,0.8)' }}>
                Track and manage your customer orders
              </Typography>
            </Box>

            <Box sx={{ display: 'flex', gap: 1 }}>
              <IconButton
                onClick={fetchOrders}
                sx={{
                  backgroundColor: 'rgba(255,255,255,0.15)',
                  color: '#fff',
                  '&:hover': { backgroundColor: 'rgba(255,255,255,0.25)' },
                }}
              >
                <Refresh />
              </IconButton>
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
        PaperProps={{
          sx: { borderRadius: '12px', minWidth: 180 },
        }}
      >
        <MenuItem onClick={() => setMenuAnchor(null)}>
          <ListItemIcon><Download fontSize="small" /></ListItemIcon>
          <ListItemText>Export Orders</ListItemText>
        </MenuItem>
        <MenuItem onClick={() => setMenuAnchor(null)}>
          <ListItemIcon><FilterList fontSize="small" /></ListItemIcon>
          <ListItemText>Advanced Filter</ListItemText>
        </MenuItem>
      </Menu>

      <Box sx={{ px: { xs: 2, md: 4 }, mt: 3 }}>
        <Card
          sx={{
            borderRadius: '20px',
            boxShadow: '0 4px 20px rgba(0,0,0,0.08)',
            overflow: 'hidden',
            mb: 3,
          }}
        >
          <Box sx={{ borderBottom: `1px solid ${alpha('#1a1a2e', 0.08)}` }}>
            <Tabs
              value={filters.status}
              onChange={handleTabChange}
              variant={isMobile ? 'scrollable' : 'fullWidth'}
              scrollButtons="auto"
              sx={{
                '& .MuiTabs-indicator': {
                  height: 3,
                  borderRadius: '3px 3px 0 0',
                  backgroundColor: '#FF9800',
                },
                '& .MuiTab-root': {
                  textTransform: 'none',
                  fontWeight: 600,
                  fontSize: '0.875rem',
                  minHeight: 56,
                  '&.Mui-selected': {
                    color: '#FF9800',
                  },
                },
              }}
            >
              {statusTabs.map((tab) => (
                <Tab
                  key={tab.value}
                  value={tab.value}
                  label={
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      {!isMobile && React.cloneElement(tab.icon, {
                        sx: { fontSize: 18, color: tab.color || 'inherit' },
                      })}
                      <span>{tab.label}</span>
                      {!isMobile && (
                        <Chip
                          label={getStatusCount(tab.value as OrderStatus | 'all')}
                          size="small"
                          sx={{
                            height: 20,
                            fontSize: '0.7rem',
                            fontWeight: 700,
                            backgroundColor: tab.color ? alpha(tab.color, 0.1) : alpha('#1a1a2e', 0.08),
                            color: tab.color || 'text.secondary',
                          }}
                        />
                      )}
                    </Box>
                  }
                />
              ))}
            </Tabs>
          </Box>

          <Box sx={{ p: 2 }}>
            <TextField
              fullWidth
              placeholder="Search by order number, customer name..."
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
                  '&:hover': {
                    backgroundColor: '#f8faf9',
                  },
                  '& fieldset': {
                    borderColor: alpha('#1a1a2e', 0.1),
                  },
                },
              }}
            />
          </Box>
        </Card>

        {loading ? (
          <Box>
            {[...Array(5)].map((_, i) => (
              <Skeleton
                key={i}
                variant="rectangular"
                height={72}
                sx={{ borderRadius: '12px', mb: 1.5 }}
              />
            ))}
          </Box>
        ) : (
          <OrdersTable
            orders={orders}
            onConfirmOrder={handleConfirmOrder}
            onShipOrder={handleShipOrder}
            onDeliverOrder={handleDeliverOrder}
          />
        )}

        {pagination.totalPages > 1 && (
          <Box sx={{ display: 'flex', justifyContent: 'center', mt: 3 }}>
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
                    backgroundColor: '#FF9800',
                    color: '#fff',
                    '&:hover': {
                      backgroundColor: '#F57C00',
                    },
                  },
                },
              }}
            />
          </Box>
        )}
      </Box>

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

export default SellerOrders;
