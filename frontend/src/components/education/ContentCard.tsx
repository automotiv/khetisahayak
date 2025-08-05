import React from 'react';
import { 
  Card, 
  CardMedia, 
  CardContent, 
  Typography, 
  Chip,
  Box,
  Stack,
  IconButton
} from '@mui/material';
import { PlayCircle, Article, Bookmark, BookmarkBorder } from '@mui/icons-material';
import { ContentType } from '../../types/enums';

interface ContentCardProps {
  id: string;
  title: string;
  type: ContentType;
  category: string;
  author: string;
  readTime: number;
  rating: number;
  thumbnail: string;
  isBookmarked?: boolean;
  onBookmark?: (contentId: string) => void;
  onContentClick?: (contentId: string) => void;
}

const ContentCard: React.FC<ContentCardProps> = ({
  id,
  title,
  type,
  category,
  author,
  readTime,
  rating,
  thumbnail,
  isBookmarked = false,
  onBookmark,
  onContentClick
}) => {
  const getTypeIcon = () => {
    switch (type) {
      case ContentType.VIDEO:
        return <PlayCircle sx={{ fontSize: 40, color: 'primary.main' }} />;
      case ContentType.ARTICLE:
        return <Article sx={{ fontSize: 40, color: 'info.main' }} />;
      default:
        return <Article sx={{ fontSize: 40, color: 'grey.600' }} />;
    }
  };

  const getTypeLabel = () => {
    switch (type) {
      case ContentType.VIDEO:
        return 'Video';
      case ContentType.ARTICLE:
        return 'Article';
      case ContentType.INFOGRAPHIC:
        return 'Infographic';
      case ContentType.AUDIO:
        return 'Audio';
      default:
        return 'Content';
    }
  };

  return (
    <Card 
      sx={{ 
        height: '100%', 
        display: 'flex', 
        flexDirection: 'column',
        cursor: 'pointer',
        '&:hover': {
          transform: 'translateY(-2px)',
          transition: 'transform 0.2s ease'
        }
      }}
      onClick={() => onContentClick?.(id)}
    >
      <Box sx={{ position: 'relative' }}>
        <CardMedia
          component="img"
          height="140"
          image={thumbnail}
          alt={title}
        />
        <Box sx={{ 
          position: 'absolute', 
          top: 8, 
          left: 8,
          display: 'flex',
          alignItems: 'center',
          gap: 1
        }}>
          {getTypeIcon()}
        </Box>
        <IconButton
          sx={{ 
            position: 'absolute', 
            top: 8, 
            right: 8,
            backgroundColor: 'rgba(255, 255, 255, 0.8)',
            '&:hover': {
              backgroundColor: 'rgba(255, 255, 255, 0.9)'
            }
          }}
          onClick={(e) => {
            e.stopPropagation();
            onBookmark?.(id);
          }}
        >
          {isBookmarked ? <Bookmark color="primary" /> : <BookmarkBorder />}
        </IconButton>
      </Box>
      
      <CardContent sx={{ flexGrow: 1 }}>
        <Stack spacing={1}>
          <Typography variant="h6" component="div" sx={{ 
            fontSize: '1rem',
            display: '-webkit-box',
            WebkitLineClamp: 2,
            WebkitBoxOrient: 'vertical',
            overflow: 'hidden'
          }}>
            {title}
          </Typography>
          
          <Stack direction="row" spacing={1} sx={{ alignItems: 'center' }}>
            <Chip 
              label={getTypeLabel()}
              size="small"
              color="primary"
              variant="outlined"
            />
            <Chip 
              label={category}
              size="small"
              variant="outlined"
            />
          </Stack>
          
          <Typography variant="body2" color="text.secondary">
            By {author}
          </Typography>
          
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <Typography variant="body2" color="text.secondary">
              {type === ContentType.VIDEO ? `${readTime} min` : `${readTime} min read`}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              ⭐ {rating}
            </Typography>
          </Box>
        </Stack>
      </CardContent>
    </Card>
  );
};

export default ContentCard;