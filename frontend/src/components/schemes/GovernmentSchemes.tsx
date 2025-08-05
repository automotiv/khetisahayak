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
  Tab,
  Badge
} from '@mui/material';
import { Search, Bookmark } from '@mui/icons-material';
import SchemeCard from './SchemeCard';
import { SchemeType, SchemeLevel } from '../../types/enums';

interface SchemeData {
  id: string;
  name: string;
  type: SchemeType;
  level: SchemeLevel;
  description: string;
  eligibility: string;
  benefits: string;
  deadline: string;
  applicationUrl: string;
  isBookmarked: boolean;
}

interface GovernmentSchemesProps {
  schemes: SchemeData[];
}

const GovernmentSchemes: React.FC<GovernmentSchemesProps> = ({ schemes }) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedType, setSelectedType] = useState<SchemeType | 'all'>('all');
  const [selectedLevel, setSelectedLevel] = useState<SchemeLevel | 'all'>('all');
  const [tabValue, setTabValue] = useState(0);
  const [bookmarkedSchemes, setBookmarkedSchemes] = useState<Set<string>>(
    new Set(schemes.filter(s => s.isBookmarked).map(s => s.id))
  );

  const filteredSchemes = schemes.filter(scheme => {
    const matchesSearch = scheme.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         scheme.description.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesType = selectedType === 'all' || scheme.type === selectedType;
    const matchesLevel = selectedLevel === 'all' || scheme.level === selectedLevel;
    const matchesTab = tabValue === 0 || (tabValue === 1 && bookmarkedSchemes.has(scheme.id));
    
    return matchesSearch && matchesType && matchesLevel && matchesTab;
  });

  const handleBookmark = (schemeId: string) => {
    setBookmarkedSchemes(prev => {
      const newSet = new Set(prev);
      if (newSet.has(schemeId)) {
        newSet.delete(schemeId);
      } else {
        newSet.add(schemeId);
      }
      return newSet;
    });
  };

  const handleApply = (applicationUrl: string) => {
    window.open(applicationUrl, '_blank');
  };

  const bookmarkedCount = bookmarkedSchemes.size;

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Government Schemes
      </Typography>

      {/* Tabs */}
      <Tabs value={tabValue} onChange={(e, newValue) => setTabValue(newValue)} sx={{ mb: 2 }}>
        <Tab label="All Schemes" />
        <Tab 
          label={
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <Bookmark />
              <span>Bookmarks</span>
              {bookmarkedCount > 0 && (
                <Badge badgeContent={bookmarkedCount} color="primary" />
              )}
            </Box>
          }
        />
      </Tabs>

      {/* Search and Filters */}
      <Stack spacing={2} sx={{ mb: 3 }}>
        <TextField
          fullWidth
          placeholder="Search schemes by name or description..."
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
              onChange={(e) => setSelectedType(e.target.value as SchemeType | 'all')}
            >
              <MenuItem value="all">All Types</MenuItem>
              <MenuItem value={SchemeType.SUBSIDY}>Subsidy</MenuItem>
              <MenuItem value={SchemeType.LOAN}>Loan</MenuItem>
              <MenuItem value={SchemeType.INSURANCE}>Insurance</MenuItem>
              <MenuItem value={SchemeType.TRAINING}>Training</MenuItem>
              <MenuItem value={SchemeType.EQUIPMENT}>Equipment</MenuItem>
              <MenuItem value={SchemeType.CROP_SUPPORT}>Crop Support</MenuItem>
              <MenuItem value={SchemeType.WATER_MANAGEMENT}>Water Management</MenuItem>
            </Select>
          </FormControl>
          
          <FormControl size="small" sx={{ minWidth: 120 }}>
            <InputLabel>Level</InputLabel>
            <Select
              value={selectedLevel}
              label="Level"
              onChange={(e) => setSelectedLevel(e.target.value as SchemeLevel | 'all')}
            >
              <MenuItem value="all">All Levels</MenuItem>
              <MenuItem value={SchemeLevel.CENTRAL}>Central</MenuItem>
              <MenuItem value={SchemeLevel.STATE}>State</MenuItem>
              <MenuItem value={SchemeLevel.DISTRICT}>District</MenuItem>
            </Select>
          </FormControl>
        </Stack>
      </Stack>

      {/* Schemes List */}
      <Stack spacing={2}>
        {filteredSchemes.map((scheme) => (
          <SchemeCard
            key={scheme.id}
            id={scheme.id}
            name={scheme.name}
            type={scheme.type}
            level={scheme.level}
            description={scheme.description}
            eligibility={scheme.eligibility}
            benefits={scheme.benefits}
            deadline={scheme.deadline}
            applicationUrl={scheme.applicationUrl}
            isBookmarked={bookmarkedSchemes.has(scheme.id)}
            onBookmark={handleBookmark}
            onApply={handleApply}
          />
        ))}
      </Stack>

      {filteredSchemes.length === 0 && (
        <Box sx={{ textAlign: 'center', py: 4 }}>
          <Typography variant="h6" color="text.secondary">
            {tabValue === 1 ? 'No bookmarked schemes' : 'No schemes found'}
          </Typography>
          <Typography variant="body2" color="text.secondary">
            {tabValue === 1 ? 'Bookmark schemes to see them here' : 'Try adjusting your search or filters'}
          </Typography>
        </Box>
      )}
    </Box>
  );
};

export default GovernmentSchemes;