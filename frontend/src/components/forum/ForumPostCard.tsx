import React, { useState } from 'react';
import {
  Card,
  CardContent,
  Typography,
  IconButton,
  Chip,
  Box,
  Stack,
  Avatar,
  Menu,
  MenuItem
} from '@mui/material';
import {
  ThumbUp,
  ThumbUpOutlined,
  Reply,
  MoreVert,
  Verified
} from '@mui/icons-material';
import { ForumCategory } from '../../types/enums';
import { formatDateTime } from '../../utils/formatters';

interface ForumPostCardProps {
  id: string;
  title: string;
  category: ForumCategory;
  author: string;
  replies: number;
  upvotes: number;
  createdAt: string;
  hasExpertReply: boolean;
  isUpvoted?: boolean;
  onUpvote?: (postId: string) => void;
  onReply?: (postId: string) => void;
  onPostClick?: (postId: string) => void;
}

const ForumPostCard: React.FC<ForumPostCardProps> = ({
  id,
  title,
  category,
  author,
  replies,
  upvotes,
  createdAt,
  hasExpertReply,
  isUpvoted = false,
  onUpvote,
  onReply,
  onPostClick
}) => {
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const [currentUpvotes, setCurrentUpvotes] = useState(upvotes);
  const [userUpvoted, setUserUpvoted] = useState(isUpvoted);

  const handleMenuClick = (event: React.MouseEvent<HTMLElement>) => {
    event.stopPropagation();
    setAnchorEl(event.currentTarget);
  };

  const handleMenuClose = () => {
    setAnchorEl(null);
  };

  const handleUpvote = (event: React.MouseEvent) => {
    event.stopPropagation();
    if (userUpvoted) {
      setCurrentUpvotes(prev => prev - 1);
    } else {
      setCurrentUpvotes(prev => prev + 1);
    }
    setUserUpvoted(!userUpvoted);
    onUpvote?.(id);
  };

  const handleReply = (event: React.MouseEvent) => {
    event.stopPropagation();
    onReply?.(id);
  };

  const getCategoryColor = (cat: ForumCategory) => {
    switch (cat) {
      case ForumCategory.CROP_MANAGEMENT:
        return 'success';
      case ForumCategory.SOIL_HEALTH:
        return 'warning';
      case ForumCategory.PEST_CONTROL:
        return 'error';
      default:
        return 'default';
    }
  };

  return (
    <Card
      sx={{
        cursor: 'pointer',
        '&:hover': {
          transform: 'translateY(-1px)',
          transition: 'transform 0.2s ease'
        }
      }}
      onClick={() => onPostClick?.(id)}
    >
      <CardContent>
        <Stack spacing={2}>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <Box sx={{ flexGrow: 1 }}>
              <Typography variant="h6" component="div" sx={{
                fontSize: '1.1rem',
                display: '-webkit-box',
                WebkitLineClamp: 2,
                WebkitBoxOrient: 'vertical',
                overflow: 'hidden'
              }}>
                {title}
              </Typography>
            </Box>
            <IconButton size="small" onClick={handleMenuClick}>
              <MoreVert />
            </IconButton>
          </Box>

          <Stack direction="row" spacing={1} sx={{ alignItems: 'center' }}>
            <Chip
              label={category.replace('_', ' ')}
              size="small"
              color={getCategoryColor(category) as any}
              variant="outlined"
            />
            {hasExpertReply && (
              <Chip
                label="Expert Reply"
                size="small"
                color="info"
                icon={<Verified />}
              />
            )}
          </Stack>

          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <Avatar sx={{ width: 24, height: 24 }}>
              {author.charAt(0)}
            </Avatar>
            <Typography variant="body2" color="text.secondary">
              {author}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              • {formatDateTime(new Date(createdAt))}
            </Typography>
          </Box>

          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <Stack direction="row" spacing={2}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                <IconButton size="small" onClick={handleUpvote}>
                  {userUpvoted ? <ThumbUp color="primary" /> : <ThumbUpOutlined />}
                </IconButton>
                <Typography variant="body2" color="text.secondary">
                  {currentUpvotes}
                </Typography>
              </Box>

              <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                <IconButton size="small" onClick={handleReply}>
                  <Reply />
                </IconButton>
                <Typography variant="body2" color="text.secondary">
                  {replies}
                </Typography>
              </Box>
            </Stack>
          </Box>
        </Stack>
      </CardContent>

      <Menu
        anchorEl={anchorEl}
        open={Boolean(anchorEl)}
        onClose={handleMenuClose}
      >
        <MenuItem onClick={handleMenuClose}>Share</MenuItem>
        <MenuItem onClick={handleMenuClose}>Report</MenuItem>
        <MenuItem onClick={handleMenuClose}>Save</MenuItem>
      </Menu>
    </Card>
  );
};

export default ForumPostCard;