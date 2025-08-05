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
  Fab,
  Tabs,
  Tab
} from '@mui/material';
import { Search, Add, TrendingUp, Schedule, Star } from '@mui/icons-material';
import ForumPostCard from './ForumPostCard';
import { QueryTypes } from '../../types/schema';
import { ForumCategory } from '../../types/enums';

interface CommunityForumProps {
  posts: QueryTypes['forumPosts'];
}

const CommunityForum: React.FC<CommunityForumProps> = ({ posts }) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<ForumCategory | 'all'>('all');
  const [tabValue, setTabValue] = useState(0);
  const [upvotedPosts, setUpvotedPosts] = useState<Set<string>>(new Set());

  const filteredPosts = posts.filter(post => {
    const matchesSearch = post.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         post.author.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesCategory = selectedCategory === 'all' || post.category === selectedCategory;
    
    return matchesSearch && matchesCategory;
  });

  const sortedPosts = [...filteredPosts].sort((a, b) => {
    switch (tabValue) {
      case 0: // Latest
        return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
      case 1: // Trending
        return b.upvotes - a.upvotes;
      case 2: // Expert Replies
        return Number(b.hasExpertReply) - Number(a.hasExpertReply);
      default:
        return 0;
    }
  });

  const handleUpvote = (postId: string) => {
    setUpvotedPosts(prev => {
      const newSet = new Set(prev);
      if (newSet.has(postId)) {
        newSet.delete(postId);
      } else {
        newSet.add(postId);
      }
      return newSet;
    });
  };

  const handleReply = (postId: string) => {
    console.log('Replying to post:', postId);
  };

  const handlePostClick = (postId: string) => {
    console.log('Opening post:', postId);
  };

  const handleCreatePost = () => {
    console.log('Creating new post');
  };

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Community Forum
      </Typography>

      {/* Tabs */}
      <Tabs value={tabValue} onChange={(e, newValue) => setTabValue(newValue)} sx={{ mb: 2 }}>
        <Tab 
          label="Latest" 
          icon={<Schedule />}
          iconPosition="start"
        />
        <Tab 
          label="Trending" 
          icon={<TrendingUp />}
          iconPosition="start"
        />
        <Tab 
          label="Expert Replies" 
          icon={<Star />}
          iconPosition="start"
        />
      </Tabs>

      {/* Search and Filters */}
      <Stack spacing={2} sx={{ mb: 3 }}>
        <TextField
          fullWidth
          placeholder="Search discussions..."
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
        
        <FormControl size="small" sx={{ minWidth: 150 }}>
          <InputLabel>Category</InputLabel>
          <Select
            value={selectedCategory}
            label="Category"
            onChange={(e) => setSelectedCategory(e.target.value as ForumCategory | 'all')}
          >
            <MenuItem value="all">All Categories</MenuItem>
            <MenuItem value={ForumCategory.CROP_MANAGEMENT}>Crop Management</MenuItem>
            <MenuItem value={ForumCategory.SOIL_HEALTH}>Soil Health</MenuItem>
            <MenuItem value={ForumCategory.PEST_CONTROL}>Pest Control</MenuItem>
            <MenuItem value={ForumCategory.WATER_MANAGEMENT}>Water Management</MenuItem>
            <MenuItem value={ForumCategory.ORGANIC_FARMING}>Organic Farming</MenuItem>
            <MenuItem value={ForumCategory.MACHINERY}>Machinery</MenuItem>
            <MenuItem value={ForumCategory.MARKET_INFO}>Market Info</MenuItem>
            <MenuItem value={ForumCategory.GENERAL}>General</MenuItem>
          </Select>
        </FormControl>
      </Stack>

      {/* Posts List */}
      <Stack spacing={2}>
        {sortedPosts.map((post) => (
          <ForumPostCard
            key={post.id}
            id={post.id}
            title={post.title}
            category={post.category}
            author={post.author}
            replies={post.replies}
            upvotes={post.upvotes}
            createdAt={post.createdAt}
            hasExpertReply={post.hasExpertReply}
            isUpvoted={upvotedPosts.has(post.id)}
            onUpvote={handleUpvote}
            onReply={handleReply}
            onPostClick={handlePostClick}
          />
        ))}
      </Stack>

      {sortedPosts.length === 0 && (
        <Box sx={{ textAlign: 'center', py: 4 }}>
          <Typography variant="h6" color="text.secondary">
            No discussions found
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Try adjusting your search or filters
          </Typography>
        </Box>
      )}

      {/* Floating Action Button */}
      <Fab
        color="primary"
        aria-label="create post"
        sx={{ position: 'fixed', bottom: 80, right: 16 }}
        onClick={handleCreatePost}
      >
        <Add />
      </Fab>
    </Box>
  );
};

export default CommunityForum;