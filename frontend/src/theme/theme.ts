// Modern agricultural theme for Kheti Sahayak application

import { createTheme } from '@mui/material/styles';

const theme = createTheme({
  palette: {
    primary: {
      main: '#2E7D32',
      light: '#4CAF50',
      dark: '#1B5E20',
      contrastText: '#FFFFFF'
    },
    secondary: {
      main: '#FF9800', // Warm orange for harvest/sun
      light: '#FFB74D',
      dark: '#F57C00',
      contrastText: '#FFFFFF'
    },
    success: {
      main: '#8BC34A',
      light: '#AED581',
      dark: '#689F38',
      contrastText: '#FFFFFF'
    },
    warning: {
      main: '#FFC107',
      light: '#FFD54F',
      dark: '#FFA000',
      contrastText: '#000000'
    },
    error: {
      main: '#F44336',
      light: '#EF5350',
      dark: '#D32F2F',
      contrastText: '#FFFFFF'
    },
    info: {
      main: '#2196F3',
      light: '#64B5F6',
      dark: '#1976D2',
      contrastText: '#FFFFFF'
    },
    background: {
      default: '#F8FAF9',
      paper: '#FFFFFF'
    },
    text: {
      primary: '#2E2E2E',
      secondary: '#666666',
      disabled: '#9E9E9E'
    },
    grey: {
      50: '#FAFAFA',
      100: '#F5F5F5',
      200: '#EEEEEE',
      300: '#E0E0E0',
      400: '#BDBDBD',
      500: '#9E9E9E',
      600: '#757575',
      700: '#616161',
      800: '#424242',
      900: '#212121'
    },
    divider: '#E0E0E0'
  },
  typography: {
    fontFamily: '"Inter", "Roboto", "Helvetica", "Arial", sans-serif',
    fontSize: 14,
    fontWeightLight: 300,
    fontWeightRegular: 400,
    fontWeightMedium: 500,
    fontWeightBold: 700,
    h1: {
      fontSize: '2.5rem',
      fontWeight: 700,
      lineHeight: 1.2
    },
    h2: {
      fontSize: '2rem',
      fontWeight: 600,
      lineHeight: 1.3
    },
    h3: {
      fontSize: '1.75rem',
      fontWeight: 600,
      lineHeight: 1.4
    },
    h4: {
      fontSize: '1.5rem',
      fontWeight: 500,
      lineHeight: 1.4
    },
    h5: {
      fontSize: '1.25rem',
      fontWeight: 500,
      lineHeight: 1.5
    },
    h6: {
      fontSize: '1rem',
      fontWeight: 500,
      lineHeight: 1.5
    },
    body1: {
      fontSize: '1rem',
      lineHeight: 1.6
    },
    body2: {
      fontSize: '0.875rem',
      lineHeight: 1.5
    },
    button: {
      fontSize: '0.875rem',
      fontWeight: 500,
      textTransform: 'none' as const
    }
  },
  shape: {
    borderRadius: 20
  },
  components: {
    MuiCard: {
      styleOverrides: {
        root: {
          borderRadius: 20,
          boxShadow: '0 4px 20px rgba(0, 0, 0, 0.08)',
        },
      },
    },
    MuiButton: {
      styleOverrides: {
        root: {
          borderRadius: 12,
          textTransform: 'none',
          fontWeight: 600,
        },
      },
    },
    MuiChip: {
      styleOverrides: {
        root: {
          borderRadius: 8,
          fontWeight: 600,
        },
      },
    },
  },
  shadows: [
    'none',
    '0px 2px 4px rgba(0, 0, 0, 0.1)',
    '0px 4px 8px rgba(0, 0, 0, 0.12)',
    '0px 8px 16px rgba(0, 0, 0, 0.14)',
    '0px 12px 24px rgba(0, 0, 0, 0.16)',
    '0px 16px 32px rgba(0, 0, 0, 0.18)',
    '0px 20px 40px rgba(0, 0, 0, 0.20)',
    '0px 24px 48px rgba(0, 0, 0, 0.22)',
    '0px 28px 56px rgba(0, 0, 0, 0.24)',
    '0px 32px 64px rgba(0, 0, 0, 0.26)',
    '0px 36px 72px rgba(0, 0, 0, 0.28)',
    '0px 40px 80px rgba(0, 0, 0, 0.30)',
    '0px 44px 88px rgba(0, 0, 0, 0.32)',
    '0px 48px 96px rgba(0, 0, 0, 0.34)',
    '0px 52px 104px rgba(0, 0, 0, 0.36)',
    '0px 56px 112px rgba(0, 0, 0, 0.38)',
    '0px 60px 120px rgba(0, 0, 0, 0.40)',
    '0px 64px 128px rgba(0, 0, 0, 0.42)',
    '0px 68px 136px rgba(0, 0, 0, 0.44)',
    '0px 72px 144px rgba(0, 0, 0, 0.46)',
    '0px 76px 152px rgba(0, 0, 0, 0.48)',
    '0px 80px 160px rgba(0, 0, 0, 0.50)',
    '0px 84px 168px rgba(0, 0, 0, 0.52)',
    '0px 88px 176px rgba(0, 0, 0, 0.54)',
    '0px 92px 184px rgba(0, 0, 0, 0.56)'
  ]
});

export default theme;