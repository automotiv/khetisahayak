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
  Stack
} from '@mui/material';
import { Search } from '@mui/icons-material';
import ExpertCard from './ExpertCard';
import { QueryTypes } from '../../types/schema';

interface ExpertConnectProps {
  experts: QueryTypes['experts'];
}

const ExpertConnect: React.FC<ExpertConnectProps> = ({ experts }) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedSpecialization, setSelectedSpecialization] = useState<string>('all');
  const [selectedLanguage, setSelectedLanguage] = useState<string>('all');

  const filteredExperts = experts.filter(expert => {
    const matchesSearch = expert.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         expert.specialization.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesSpecialization = selectedSpecialization === 'all' || 
                                 expert.specialization.toLowerCase().includes(selectedSpecialization.toLowerCase());
    const matchesLanguage = selectedLanguage === 'all' || 
                           expert.languages.some(lang => lang.toLowerCase() === selectedLanguage.toLowerCase());
    
    return matchesSearch && matchesSpecialization && matchesLanguage;
  });

  const handleStartChat = (expertId: string) => {
    console.log('Starting chat with expert:', expertId);
  };

  const handleScheduleCall = (expertId: string) => {
    console.log('Scheduling call with expert:', expertId);
  };

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Connect with Experts
      </Typography>

      {/* Search and Filters */}
      <Stack spacing={2} sx={{ mb: 3 }}>
        <TextField
          fullWidth
          placeholder="Search experts by name or specialization..."
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
          <FormControl size="small" sx={{ minWidth: 150 }}>
            <InputLabel>Specialization</InputLabel>
            <Select
              value={selectedSpecialization}
              label="Specialization"
              onChange={(e) => setSelectedSpecialization(e.target.value)}
            >
              <MenuItem value="all">All Specializations</MenuItem>
              <MenuItem value="plant pathology">Plant Pathology</MenuItem>
              <MenuItem value="soil science">Soil Science</MenuItem>
              <MenuItem value="entomology">Entomology</MenuItem>
              <MenuItem value="agronomy">Agronomy</MenuItem>
            </Select>
          </FormControl>
          
          <FormControl size="small" sx={{ minWidth: 120 }}>
            <InputLabel>Language</InputLabel>
            <Select
              value={selectedLanguage}
              label="Language"
              onChange={(e) => setSelectedLanguage(e.target.value)}
            >
              <MenuItem value="all">All Languages</MenuItem>
              <MenuItem value="hindi">Hindi</MenuItem>
              <MenuItem value="english">English</MenuItem>
              <MenuItem value="marathi">Marathi</MenuItem>
              <MenuItem value="gujarati">Gujarati</MenuItem>
            </Select>
          </FormControl>
        </Stack>
      </Stack>

      {/* Experts Grid */}
      <Box sx={{ 
        display: 'grid', 
        gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', 
        gap: 2 
      }}>
        {filteredExperts.map((expert) => (
          <ExpertCard
            key={expert.id}
            id={expert.id}
            name={expert.name}
            specialization={expert.specialization}
            rating={expert.rating}
            languages={expert.languages}
            isAvailable={expert.isAvailable}
            consultationFee={expert.consultationFee}
            profileImage={expert.profileImage}
            onStartChat={handleStartChat}
            onScheduleCall={handleScheduleCall}
          />
        ))}
      </Box>

      {filteredExperts.length === 0 && (
        <Box sx={{ textAlign: 'center', py: 4 }}>
          <Typography variant="h6" color="text.secondary">
            No experts found
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Try adjusting your search or filters
          </Typography>
        </Box>
      )}
    </Box>
  );
};

export default ExpertConnect;