import React, { useState } from 'react';
import {
  Box,
  Typography,
  Tabs,
  Tab,
  TextField,
  InputAdornment,
  FormControl,
  Select,
  MenuItem,
  InputLabel,
  Stack,
  Fab
} from '@mui/material';
import { Search, Add, Build, People } from '@mui/icons-material';
import EquipmentCard from './EquipmentCard';
import LaborCard from './LaborCard';
import { EquipmentType, LaborSkill } from '../../types/enums';

interface EquipmentData {
  id: string;
  name: string;
  type: EquipmentType;
  owner: string;
  location: string;
  hourlyRate: number;
  dailyRate: number;
  securityDeposit: number;
  status: any;
  rating: number;
  images: string[];
  description: string;
}

interface LaborData {
  id: string;
  name: string;
  skills: LaborSkill[];
  experience: number;
  location: string;
  dailyWage: number;
  hourlyWage: number;
  rating: number;
  isAvailable: boolean;
  profileImage: string;
  description: string;
}

interface SharingPlatformProps {
  equipment: EquipmentData[];
  labor: LaborData[];
}

const SharingPlatform: React.FC<SharingPlatformProps> = ({ equipment, labor }) => {
  const [tabValue, setTabValue] = useState(0);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedEquipmentType, setSelectedEquipmentType] = useState<EquipmentType | 'all'>('all');
  const [selectedSkill, setSelectedSkill] = useState<LaborSkill | 'all'>('all');

  const filteredEquipment = equipment.filter(item => {
    const matchesSearch = item.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.owner.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesType = selectedEquipmentType === 'all' || item.type === selectedEquipmentType;

    return matchesSearch && matchesType;
  });

  const filteredLabor = labor.filter(worker => {
    const matchesSearch = worker.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      worker.description.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesSkill = selectedSkill === 'all' || worker.skills.includes(selectedSkill);

    return matchesSearch && matchesSkill;
  });

  const handleBookEquipment = (equipmentId: string) => {
    console.log('Booking equipment:', equipmentId);
  };

  const handleHireLabor = (laborId: string) => {
    console.log('Hiring labor:', laborId);
  };

  const handleViewDetails = (id: string) => {
    console.log('Viewing details for:', id);
  };

  const handleAddListing = () => {
    console.log('Adding new listing');
  };

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h4">
          Equipment & Labor
        </Typography>
      </Box>

      {/* Tabs */}
      <Tabs value={tabValue} onChange={(_, newValue) => setTabValue(newValue)} sx={{ mb: 2 }}>
        <Tab
          label={
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <Build />
              <span>Equipment</span>
            </Box>
          }
        />
        <Tab
          label={
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <People />
              <span>Labor</span>
            </Box>
          }
        />
      </Tabs>

      {/* Search and Filters */}
      <Stack spacing={2} sx={{ mb: 3 }}>
        <TextField
          fullWidth
          placeholder={tabValue === 0 ? "Search equipment..." : "Search workers..."}
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

        {tabValue === 0 ? (
          <FormControl size="small" sx={{ minWidth: 150 }}>
            <InputLabel>Equipment Type</InputLabel>
            <Select
              value={selectedEquipmentType}
              label="Equipment Type"
              onChange={(e) => setSelectedEquipmentType(e.target.value as EquipmentType | 'all')}
            >
              <MenuItem value="all">All Equipment</MenuItem>
              <MenuItem value={EquipmentType.TRACTOR}>Tractor</MenuItem>
              <MenuItem value={EquipmentType.HARVESTER}>Harvester</MenuItem>
              <MenuItem value={EquipmentType.PLOUGH}>Plough</MenuItem>
              <MenuItem value={EquipmentType.SEEDER}>Seeder</MenuItem>
              <MenuItem value={EquipmentType.SPRAYER}>Sprayer</MenuItem>
              <MenuItem value={EquipmentType.CULTIVATOR}>Cultivator</MenuItem>
              <MenuItem value={EquipmentType.THRESHER}>Thresher</MenuItem>
              <MenuItem value={EquipmentType.PUMP}>Pump</MenuItem>
            </Select>
          </FormControl>
        ) : (
          <FormControl size="small" sx={{ minWidth: 150 }}>
            <InputLabel>Skill</InputLabel>
            <Select
              value={selectedSkill}
              label="Skill"
              onChange={(e) => setSelectedSkill(e.target.value as LaborSkill | 'all')}
            >
              <MenuItem value="all">All Skills</MenuItem>
              <MenuItem value={LaborSkill.PLANTING}>Planting</MenuItem>
              <MenuItem value={LaborSkill.HARVESTING}>Harvesting</MenuItem>
              <MenuItem value={LaborSkill.TRACTOR_OPERATION}>Tractor Operation</MenuItem>
              <MenuItem value={LaborSkill.IRRIGATION}>Irrigation</MenuItem>
              <MenuItem value={LaborSkill.GENERAL_LABOR}>General Labor</MenuItem>
              <MenuItem value={LaborSkill.LIVESTOCK_CARE}>Livestock Care</MenuItem>
              <MenuItem value={LaborSkill.MACHINERY_REPAIR}>Machinery Repair</MenuItem>
            </Select>
          </FormControl>
        )}
      </Stack>

      {/* Content Grid */}
      <Box sx={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))',
        gap: 2
      }}>
        {tabValue === 0 ? (
          filteredEquipment.map((item) => (
            <EquipmentCard
              key={item.id}
              id={item.id}
              name={item.name}
              type={item.type}
              owner={item.owner}
              location={item.location}
              hourlyRate={item.hourlyRate}
              dailyRate={item.dailyRate}
              securityDeposit={item.securityDeposit}
              status={item.status}
              rating={item.rating}
              images={item.images}
              description={item.description}
              onBook={handleBookEquipment}
              onViewDetails={handleViewDetails}
            />
          ))
        ) : (
          filteredLabor.map((worker) => (
            <LaborCard
              key={worker.id}
              id={worker.id}
              name={worker.name}
              skills={worker.skills}
              experience={worker.experience}
              location={worker.location}
              dailyWage={worker.dailyWage}
              hourlyWage={worker.hourlyWage}
              rating={worker.rating}
              isAvailable={worker.isAvailable}
              profileImage={worker.profileImage}
              description={worker.description}
              onHire={handleHireLabor}
              onViewProfile={handleViewDetails}
            />
          ))
        )}
      </Box>

      {/* Empty State */}
      {((tabValue === 0 && filteredEquipment.length === 0) ||
        (tabValue === 1 && filteredLabor.length === 0)) && (
          <Box sx={{ textAlign: 'center', py: 4 }}>
            <Typography variant="h6" color="text.secondary">
              {tabValue === 0 ? 'No equipment found' : 'No workers found'}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Try adjusting your search or filters
            </Typography>
          </Box>
        )}

      {/* Add Listing FAB */}
      <Fab
        color="primary"
        aria-label="add listing"
        sx={{ position: 'fixed', bottom: 80, right: 16 }}
        onClick={handleAddListing}
      >
        <Add />
      </Fab>
    </Box>
  );
};

export default SharingPlatform;