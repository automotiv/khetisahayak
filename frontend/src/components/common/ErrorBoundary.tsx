import React, { Component, ReactNode } from 'react';
import { Box, Typography, Button, Alert, Container } from '@mui/material';
import { Refresh, BugReport } from '@mui/icons-material';

interface ErrorBoundaryProps {
  children: ReactNode;
  fallback?: ReactNode;
}

interface ErrorBoundaryState {
  hasError: boolean;
  error?: Error;
  errorInfo?: string;
}

class ErrorBoundary extends Component<ErrorBoundaryProps, ErrorBoundaryState> {
  constructor(props: ErrorBoundaryProps) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    // Update state so the next render will show the fallback UI
    return { 
      hasError: true, 
      error 
    };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    // Log error details for debugging
    console.error('ErrorBoundary caught an error:', error, errorInfo);
    
    this.setState({
      error,
      errorInfo: errorInfo.componentStack
    });
  }

  handleRetry = () => {
    this.setState({ hasError: false, error: undefined, errorInfo: undefined });
  };

  render() {
    if (this.state.hasError) {
      if (this.props.fallback) {
        return this.props.fallback;
      }

      return (
        <Container maxWidth="sm" sx={{ mt: 4 }}>
          <Box
            display="flex"
            flexDirection="column"
            alignItems="center"
            textAlign="center"
            gap={3}
          >
            <BugReport sx={{ fontSize: 64, color: 'error.main' }} />
            
            <Typography variant="h4" color="error.main" gutterBottom>
              Something went wrong
            </Typography>
            
            <Typography variant="body1" color="text.secondary" sx={{ mb: 2 }}>
              We're sorry, but something unexpected happened. Please try refreshing the page.
            </Typography>

            <Alert severity="error" sx={{ width: '100%', textAlign: 'left' }}>
              <Typography variant="body2">
                <strong>Error:</strong> {this.state.error?.message}
              </Typography>
            </Alert>

            <Box display="flex" gap={2}>
              <Button
                variant="contained"
                startIcon={<Refresh />}
                onClick={this.handleRetry}
                color="primary"
              >
                Try Again
              </Button>
              
              <Button
                variant="outlined"
                onClick={() => window.location.reload()}
              >
                Refresh Page
              </Button>
            </Box>

            {process.env.NODE_ENV === 'development' && this.state.errorInfo && (
              <Alert severity="info" sx={{ width: '100%', textAlign: 'left', mt: 2 }}>
                <Typography variant="caption" component="pre" sx={{ whiteSpace: 'pre-wrap' }}>
                  {this.state.errorInfo}
                </Typography>
              </Alert>
            )}
          </Box>
        </Container>
      );
    }

    return this.props.children;
  }
}

export default ErrorBoundary;
