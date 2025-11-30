import React, { useState } from 'react';
import {
  Box,
  Typography,
  Fab,
  TextField,
  InputAdornment,
  FormControl,
  Select,
  MenuItem,
  InputLabel,
  Stack,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Card,
  CardContent
} from '@mui/material';
import { Add, Search, GetApp } from '@mui/icons-material';
import LogbookEntry from './LogbookEntry';
import { ActivityType } from '../../types/enums';

interface LogbookData {
  id: string;
  activityType: ActivityType;
  cropType: string;
  date: string;
  notes: string;
  inputsUsed: Array<{
    type: string;
    quantity: number;
    unit: string;
    cost: number;
  }>;
  expenses: number;
  photos: string[];
}

interface DigitalLogbookProps {
  entries: LogbookData[];
}

const DigitalLogbook: React.FC<DigitalLogbookProps> = ({ entries }) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedActivity, setSelectedActivity] = useState<ActivityType | 'all'>('all');
  const [exportDialogOpen, setExportDialogOpen] = useState(false);
  const [selectedFormat, setSelectedFormat] = useState<'csv' | 'pdf' | 'xlsx'>('csv');

  const filteredEntries = entries.filter(entry => {
    const matchesSearch = entry.notes.toLowerCase().includes(searchTerm.toLowerCase()) ||
      entry.cropType.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesActivity = selectedActivity === 'all' || entry.activityType === selectedActivity;

    return matchesSearch && matchesActivity;
  });

  const handleAddEntry = () => {
    console.log('Adding new logbook entry');
  };

  const handleEditEntry = (entryId: string) => {
    console.log('Editing entry:', entryId);
  };

  const handleDeleteEntry = (entryId: string) => {
    console.log('Deleting entry:', entryId);
  };

  const handleExport = () => {
    console.log('Exporting logbook data as:', selectedFormat);
    setExportDialogOpen(false);
  };

  const totalExpenses = filteredEntries.reduce((sum, entry) => sum + entry.expenses, 0);

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h4">
          Digital Logbook
        </Typography>
        <Button
          variant="outlined"
          startIcon={<GetApp />}
          onClick={() => setExportDialogOpen(true)}
        >
          Export
        </Button>
      </Box>

      {/* Summary Card */}
      <Card sx={{ mb: 3, background: 'linear-gradient(135deg, #E8F5E8, #F1F8E9)' }}>
        <CardContent>
          <Stack direction="row" spacing={4}>
            <Box>
              <Typography variant="h6" color="primary.main">
                {filteredEntries.length}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Total Entries
              </Typography>
            </Box>
            <Box>
              <Typography variant="h6" color="primary.main">
                ₹{totalExpenses.toLocaleString()}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Total Expenses
              </Typography>
            </Box>
          </Stack>
        </CardContent>
      </Card>

      {/* Search and Filters */}
      <Stack spacing={2} sx={{ mb: 3 }}>
        <TextField
          fullWidth
          placeholder="Search entries by notes or crop..."
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
          <InputLabel>Activity Type</InputLabel>
          <Select
            value={selectedActivity}
            label="Activity Type"
            onChange={(e) => setSelectedActivity(e.target.value as ActivityType | 'all')}
          >
            <MenuItem value="all">All Activities</MenuItem>
            <MenuItem value={ActivityType.PLANTING}>Planting</MenuItem>
            <MenuItem value={ActivityType.IRRIGATION}>Irrigation</MenuItem>
            <MenuItem value={ActivityType.FERTILIZING}>Fertilizing</MenuItem>
            <MenuItem value={ActivityType.PEST_CONTROL}>Pest Control</MenuItem>
            <MenuItem value={ActivityType.HARVESTING}>Harvesting</MenuItem>
            <MenuItem value={ActivityType.OBSERVATION}>Observation</MenuItem>
            <MenuItem value={ActivityType.MAINTENANCE}>Maintenance</MenuItem>
            <MenuItem value={ActivityType.SALE}>Sale</MenuItem>
          </Select>
        </FormControl>
      </Stack>

      {/* Entries List */}
      <Stack spacing={2}>
        {filteredEntries.map((entry) => (
          <LogbookEntry
            key={entry.id}
            id={entry.id}
            activityType={entry.activityType}
            cropType={entry.cropType}
            date={entry.date}
            notes={entry.notes}
            inputsUsed={entry.inputsUsed}
            expenses={entry.expenses}
            photos={entry.photos}
            onEdit={handleEditEntry}
            onDelete={handleDeleteEntry}
          />
        ))}
      </Stack>

      {filteredEntries.length === 0 && (
        <Box sx={{ textAlign: 'center', py: 4 }}>
          <Typography variant="h6" color="text.secondary">
            No entries found
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Start by adding your first farm activity
          </Typography>
        </Box>
      )}

      {/* Add Entry FAB */}
      <Fab
        color="primary"
        aria-label="add entry"
        sx={{ position: 'fixed', bottom: 80, right: 16 }}
        onClick={handleAddEntry}
      >
        <Add />
      </Fab>

      {/* Export Dialog */}
      <Dialog open={exportDialogOpen} onClose={() => setExportDialogOpen(false)}>
        <DialogTitle>Export Logbook Data</DialogTitle>
        <DialogContent>
          <FormControl fullWidth sx={{ mt: 1 }}>
            <InputLabel>Export Format</InputLabel>
            <Select
              value={selectedFormat}
              label="Export Format"
              onChange={(e) => setSelectedFormat(e.target.value as 'csv' | 'pdf' | 'xlsx')}
            >
              <MenuItem value="csv">CSV (Excel Compatible)</MenuItem>
              <MenuItem value="pdf">PDF Report</MenuItem>
              <MenuItem value="xlsx">Excel Workbook</MenuItem>
            </Select>
          </FormControl>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setExportDialogOpen(false)}>Cancel</Button>
          <Button variant="contained" onClick={handleExport}>Export</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default DigitalLogbook;