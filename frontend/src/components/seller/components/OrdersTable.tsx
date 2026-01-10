import React from 'react';
import {
  Box,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Typography,
  Chip,
  IconButton,
  Tooltip,
  Avatar,
  AvatarGroup,
  Skeleton,
  useTheme,
  alpha,
  useMediaQuery,
  Card,
  Stack,
  Button,
} from '@mui/material';
import {
  CheckCircle,
  LocalShipping,
  Inventory,
  MoreVert,
  Phone,
  LocationOn,
} from '@mui/icons-material';
import { SellerOrder } from '../../../types/seller';
import { OrderStatus } from '../../../types/enums';
import { formatCurrency, formatDateTime } from '../../../utils/formatters';

interface OrdersTableProps {
  orders: SellerOrder[];
  loading?: boolean;
  onConfirmOrder?: (orderId: string) => void;
  onShipOrder?: (orderId: string) => void;
  onDeliverOrder?: (orderId: string) => void;
  onViewDetails?: (orderId: string) => void;
  compact?: boolean;
}

const statusConfig: Record<OrderStatus, { color: 'default' | 'primary' | 'secondary' | 'error' | 'info' | 'success' | 'warning'; label: string; bgColor: string }> = {
  [OrderStatus.PENDING]: { color: 'warning', label: 'Pending', bgColor: '#FFF3E0' },
  [OrderStatus.CONFIRMED]: { color: 'info', label: 'Confirmed', bgColor: '#E3F2FD' },
  [OrderStatus.SHIPPED]: { color: 'primary', label: 'Shipped', bgColor: '#E8F5E9' },
  [OrderStatus.DELIVERED]: { color: 'success', label: 'Delivered', bgColor: '#E8F5E9' },
  [OrderStatus.CANCELLED]: { color: 'error', label: 'Cancelled', bgColor: '#FFEBEE' },
  [OrderStatus.RETURNED]: { color: 'default', label: 'Returned', bgColor: '#F5F5F5' },
};

const OrdersTable: React.FC<OrdersTableProps> = ({
  orders,
  loading = false,
  onConfirmOrder,
  onShipOrder,
  onDeliverOrder,
  onViewDetails,
  compact = false,
}) => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));

  const getActionButton = (order: SellerOrder) => {
    switch (order.status) {
      case OrderStatus.PENDING:
        return (
          <Tooltip title="Confirm Order">
            <IconButton
              size="small"
              onClick={() => onConfirmOrder?.(order.id)}
              sx={{
                backgroundColor: alpha(theme.palette.info.main, 0.1),
                color: theme.palette.info.main,
                '&:hover': {
                  backgroundColor: alpha(theme.palette.info.main, 0.2),
                },
              }}
            >
              <CheckCircle fontSize="small" />
            </IconButton>
          </Tooltip>
        );
      case OrderStatus.CONFIRMED:
        return (
          <Tooltip title="Mark as Shipped">
            <IconButton
              size="small"
              onClick={() => onShipOrder?.(order.id)}
              sx={{
                backgroundColor: alpha(theme.palette.primary.main, 0.1),
                color: theme.palette.primary.main,
                '&:hover': {
                  backgroundColor: alpha(theme.palette.primary.main, 0.2),
                },
              }}
            >
              <LocalShipping fontSize="small" />
            </IconButton>
          </Tooltip>
        );
      case OrderStatus.SHIPPED:
        return (
          <Tooltip title="Mark as Delivered">
            <IconButton
              size="small"
              onClick={() => onDeliverOrder?.(order.id)}
              sx={{
                backgroundColor: alpha(theme.palette.success.main, 0.1),
                color: theme.palette.success.main,
                '&:hover': {
                  backgroundColor: alpha(theme.palette.success.main, 0.2),
                },
              }}
            >
              <Inventory fontSize="small" />
            </IconButton>
          </Tooltip>
        );
      default:
        return (
          <IconButton size="small" onClick={() => onViewDetails?.(order.id)}>
            <MoreVert fontSize="small" />
          </IconButton>
        );
    }
  };

  if (loading) {
    return (
      <TableContainer component={Paper} sx={{ borderRadius: '16px', boxShadow: '0 4px 20px rgba(0,0,0,0.08)' }}>
        <Table>
          <TableHead>
            <TableRow>
              {['Order', 'Customer', 'Products', 'Total', 'Status', 'Actions'].map((header) => (
                <TableCell key={header}>
                  <Skeleton variant="text" width={80} />
                </TableCell>
              ))}
            </TableRow>
          </TableHead>
          <TableBody>
            {[...Array(5)].map((_, i) => (
              <TableRow key={i}>
                {[...Array(6)].map((_, j) => (
                  <TableCell key={j}>
                    <Skeleton variant="text" />
                  </TableCell>
                ))}
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>
    );
  }

  if (orders.length === 0) {
    return (
      <Box
        sx={{
          textAlign: 'center',
          py: 6,
          px: 3,
          backgroundColor: alpha(theme.palette.grey[100], 0.5),
          borderRadius: '16px',
        }}
      >
        <Inventory sx={{ fontSize: 64, color: alpha('#1a1a2e', 0.2), mb: 2 }} />
        <Typography variant="h6" color="text.secondary">
          No orders found
        </Typography>
        <Typography variant="body2" color="text.secondary">
          Orders will appear here once customers start purchasing
        </Typography>
      </Box>
    );
  }

  if (isMobile) {
    return (
      <Stack spacing={2}>
        {orders.map((order) => (
          <Card
            key={order.id}
            sx={{
              borderRadius: '16px',
              boxShadow: '0 2px 12px rgba(0,0,0,0.06)',
              overflow: 'hidden',
              border: `1px solid ${alpha('#1a1a2e', 0.06)}`,
            }}
          >
            <Box sx={{ p: 2 }}>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 2 }}>
                <Box>
                  <Typography variant="subtitle2" fontWeight={700}>
                    {order.orderNumber}
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    {formatDateTime(new Date(order.createdAt))}
                  </Typography>
                </Box>
                <Chip
                  label={statusConfig[order.status].label}
                  size="small"
                  color={statusConfig[order.status].color}
                  sx={{ fontWeight: 600 }}
                />
              </Box>

              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
                <Avatar sx={{ width: 32, height: 32, bgcolor: alpha('#2E7D32', 0.1), color: '#2E7D32' }}>
                  {order.customerName.charAt(0)}
                </Avatar>
                <Box>
                  <Typography variant="body2" fontWeight={600}>
                    {order.customerName}
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    {order.products.length} item{order.products.length > 1 ? 's' : ''}
                  </Typography>
                </Box>
              </Box>

              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Typography variant="h6" fontWeight={700} color="#2E7D32">
                  {formatCurrency(order.totalAmount)}
                </Typography>
                <Box sx={{ display: 'flex', gap: 1 }}>
                  {getActionButton(order)}
                  <IconButton size="small" onClick={() => onViewDetails?.(order.id)}>
                    <MoreVert fontSize="small" />
                  </IconButton>
                </Box>
              </Box>
            </Box>
          </Card>
        ))}
      </Stack>
    );
  }

  return (
    <TableContainer
      component={Paper}
      sx={{
        borderRadius: '16px',
        boxShadow: '0 4px 20px rgba(0,0,0,0.08)',
        overflow: 'hidden',
        border: `1px solid ${alpha('#1a1a2e', 0.06)}`,
      }}
    >
      <Table>
        <TableHead>
          <TableRow
            sx={{
              backgroundColor: alpha('#2E7D32', 0.04),
              '& th': {
                fontWeight: 700,
                color: alpha('#1a1a2e', 0.7),
                fontSize: '0.75rem',
                textTransform: 'uppercase',
                letterSpacing: '0.5px',
                borderBottom: `1px solid ${alpha('#1a1a2e', 0.08)}`,
                py: 2,
              },
            }}
          >
            <TableCell>Order</TableCell>
            <TableCell>Customer</TableCell>
            {!compact && <TableCell>Products</TableCell>}
            <TableCell align="right">Total</TableCell>
            <TableCell>Status</TableCell>
            <TableCell align="center">Actions</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {orders.map((order, index) => (
            <TableRow
              key={order.id}
              sx={{
                '&:last-child td': { borderBottom: 0 },
                transition: 'background-color 0.2s ease',
                '&:hover': {
                  backgroundColor: alpha('#2E7D32', 0.02),
                },
                ...(index % 2 === 0 && {
                  backgroundColor: alpha('#f8faf9', 0.5),
                }),
              }}
            >
              <TableCell>
                <Box>
                  <Typography variant="body2" fontWeight={700} sx={{ color: '#1a1a2e' }}>
                    {order.orderNumber}
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    {formatDateTime(new Date(order.createdAt))}
                  </Typography>
                </Box>
              </TableCell>

              <TableCell>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                  <Avatar
                    sx={{
                      width: 36,
                      height: 36,
                      bgcolor: alpha('#2E7D32', 0.1),
                      color: '#2E7D32',
                      fontWeight: 700,
                      fontSize: '0.875rem',
                    }}
                  >
                    {order.customerName.charAt(0)}
                  </Avatar>
                  <Box>
                    <Typography variant="body2" fontWeight={600}>
                      {order.customerName}
                    </Typography>
                    {!compact && (
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                        <Phone sx={{ fontSize: 12, color: 'text.secondary' }} />
                        <Typography variant="caption" color="text.secondary">
                          {order.customerPhone}
                        </Typography>
                      </Box>
                    )}
                  </Box>
                </Box>
              </TableCell>

              {!compact && (
                <TableCell>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <AvatarGroup
                      max={3}
                      sx={{
                        '& .MuiAvatar-root': {
                          width: 28,
                          height: 28,
                          fontSize: '0.7rem',
                          border: '2px solid #fff',
                        },
                      }}
                    >
                      {order.products.map((product) => (
                        <Avatar
                          key={product.id}
                          src={product.image}
                          alt={product.name}
                          sx={{ bgcolor: alpha('#FF9800', 0.2) }}
                        >
                          {product.name.charAt(0)}
                        </Avatar>
                      ))}
                    </AvatarGroup>
                    <Typography variant="caption" color="text.secondary">
                      {order.products.length} item{order.products.length > 1 ? 's' : ''}
                    </Typography>
                  </Box>
                </TableCell>
              )}

              <TableCell align="right">
                <Typography
                  variant="body2"
                  fontWeight={700}
                  sx={{
                    color: '#2E7D32',
                    fontFamily: '"DM Sans", sans-serif',
                  }}
                >
                  {formatCurrency(order.totalAmount)}
                </Typography>
                {order.paymentStatus === 'paid' && (
                  <Typography variant="caption" color="success.main">
                    Paid
                  </Typography>
                )}
              </TableCell>

              <TableCell>
                <Chip
                  label={statusConfig[order.status].label}
                  size="small"
                  color={statusConfig[order.status].color}
                  sx={{
                    fontWeight: 600,
                    borderRadius: '8px',
                    px: 0.5,
                  }}
                />
              </TableCell>

              <TableCell align="center">
                <Box sx={{ display: 'flex', justifyContent: 'center', gap: 0.5 }}>
                  {getActionButton(order)}
                </Box>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </TableContainer>
  );
};

export default OrdersTable;
