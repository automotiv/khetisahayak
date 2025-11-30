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
  Tabs,
  Tab
} from '@mui/material';
import { Search, Bookmark } from '@mui/icons-material';
import ContentCard from './ContentCard';
import { QueryTypes } from '../../types/schema';
import { ContentType } from '../../types/enums';

interface EducationalContentProps {
  content: QueryTypes['educationalContent'];
}

const EducationalContent: React.FC<EducationalContentProps> = ({ content }) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedType, setSelectedType] = useState<ContentType | 'all'>('all');
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [tabValue, setTabValue] = useState(0);
  const [bookmarkedContent, setBookmarkedContent] = useState<Set<string>>(new Set());

  const filteredContent = content.filter(item => {
    const matchesSearch = item.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.author.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesType = selectedType === 'all' || item.type === selectedType;
    const matchesCategory = selectedCategory === 'all' || item.category === selectedCategory;
    const matchesTab = tabValue === 0 || (tabValue === 1 && bookmarkedContent.has(item.id));

    return matchesSearch && matchesType && matchesCategory && matchesTab;
  });

  const handleBookmark = (contentId: string) => {
    setBookmarkedContent(prev => {
      const newSet = new Set(prev);
      if (newSet.has(contentId)) {
        newSet.delete(contentId);
      } else {
        newSet.add(contentId);
      }
      return newSet;
    });
  };

  const handleContentClick = (contentId: string) => {
    console.log('Opening content:', contentId);
  };

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Educational Content
      </Typography>

      {/* Tabs */}
      <Tabs value={tabValue} onChange={(_, newValue) => setTabValue(newValue)} sx={{ mb: 2 }}>
        <Tab label="All Content" />
        <Tab
          label="Bookmarks"
          icon={<Bookmark />}
          iconPosition="start"
        />
      </Tabs>

      {/* Search and Filters */}
      <Stack spacing={2} sx={{ mb: 3 }}>
        <TextField
          fullWidth
          placeholder="Search articles, videos, tutorials..."
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
            <InputLabel>Type</InputLabel>
            <Select
              value={selectedType}
              label="Type"
              onChange={(e) => setSelectedType(e.target.value as ContentType | 'all')}
            >
              <MenuItem value="all">All Types</MenuItem>
              <MenuItem value={ContentType.ARTICLE}>Articles</MenuItem>
              <MenuItem value={ContentType.VIDEO}>Videos</MenuItem>
              <MenuItem value={ContentType.INFOGRAPHIC}>Infographics</MenuItem>
              <MenuItem value={ContentType.AUDIO}>Audio</MenuItem>
            </Select>
          </FormControl>

          <FormControl size="small" sx={{ minWidth: 150 }}>
            <InputLabel>Category</InputLabel>
            <Select
              value={selectedCategory}
              label="Category"
              onChange={(e) => setSelectedCategory(e.target.value)}
            >
              <MenuItem value="all">All Categories</MenuItem>
              <MenuItem value="Organic Farming">Organic Farming</MenuItem>
              <MenuItem value="Crop Management">Crop Management</MenuItem>
              <MenuItem value="Soil Health">Soil Health</MenuItem>
              <MenuItem value="Pest Control">Pest Control</MenuItem>
              <MenuItem value="Water Management">Water Management</MenuItem>
            </Select>
          </FormControl>
        </Stack>
      </Stack>

      {/* Content Grid */}
      <Box sx={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))',
        gap: 2
      }}>
        {filteredContent.map((item) => (
          <ContentCard
            key={item.id}
            id={item.id}
            title={item.title}
            type={item.type}
            category={item.category}
            author={item.author}
            readTime={item.readTime}
            rating={item.rating}
            thumbnail={item.thumbnail}
            isBookmarked={bookmarkedContent.has(item.id)}
            onBookmark={handleBookmark}
            onContentClick={handleContentClick}
          />
        ))}
      </Box>

      {filteredContent.length === 0 && (
        <Box sx={{ textAlign: 'center', py: 4 }}>
          <Typography variant="h6" color="text.secondary">
            {tabValue === 1 ? 'No bookmarked content' : 'No content found'}
          </Typography>
          <Typography variant="body2" color="text.secondary">
            {tabValue === 1 ? 'Bookmark content to see it here' : 'Try adjusting your search or filters'}
          </Typography>
        </Box>
      )}
    </Box>
  );
};

export default EducationalContent;