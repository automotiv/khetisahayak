import React, { useState } from 'react';
import {
  Card,
  CardContent,
  TextField,
  Button,
  Typography,
  Stack,
  Box,
  Alert,
  CircularProgress
} from '@mui/material';
import { Phone, Security } from '@mui/icons-material';

interface LoginFormProps {
  onLogin?: (phone: string, otp: string) => void;
  onRegister?: () => void;
}

const LoginForm: React.FC<LoginFormProps> = ({ onLogin, onRegister }) => {
  const [phone, setPhone] = useState('');
  const [otp, setOtp] = useState('');
  const [step, setStep] = useState<'phone' | 'otp'>('phone');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');

  const validatePhone = (phoneNumber: string): boolean => {
    const phoneRegex = /^[6-9]\d{9}$/;
    return phoneRegex.test(phoneNumber);
  };

  const handleSendOTP = async () => {
    if (!validatePhone(phone)) {
      setError('Please enter a valid 10-digit mobile number');
      return;
    }

    setIsLoading(true);
    setError('');
    
    // Simulate API call
    setTimeout(() => {
      setIsLoading(false);
      setStep('otp');
    }, 2000);
  };

  const handleVerifyOTP = async () => {
    if (otp.length !== 6) {
      setError('Please enter a valid 6-digit OTP');
      return;
    }

    setIsLoading(true);
    setError('');
    
    // Simulate API call
    setTimeout(() => {
      setIsLoading(false);
      onLogin?.(phone, otp);
    }, 1500);
  };

  const handleResendOTP = () => {
    setOtp('');
    handleSendOTP();
  };

  return (
    <Box sx={{ 
      display: 'flex', 
      justifyContent: 'center', 
      alignItems: 'center', 
      minHeight: '100vh',
      background: 'linear-gradient(135deg, #4CAF50, #8BC34A)',
      p: 2
    }}>
      <Card sx={{ maxWidth: 400, width: '100%' }}>
        <CardContent sx={{ p: 4 }}>
          <Box sx={{ textAlign: 'center', mb: 3 }}>
            <Typography variant="h4" gutterBottom sx={{ color: 'primary.main', fontWeight: 'bold' }}>
              🌾 Kheti Sahayak
            </Typography>
            <Typography variant="body1" color="text.secondary">
              Your Digital Agricultural Assistant
            </Typography>
          </Box>

          {error && (
            <Alert severity="error" sx={{ mb: 2 }}>
              {error}
            </Alert>
          )}

          <Stack spacing={3}>
            {step === 'phone' ? (
              <>
                <TextField
                  fullWidth
                  label="Mobile Number"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  placeholder="Enter 10-digit mobile number"
                  InputProps={{
                    startAdornment: <Phone sx={{ mr: 1, color: 'text.secondary' }} />
                  }}
                  inputProps={{ 
                    maxLength: 10,
                    'aria-describedby': 'phone-helper-text',
                    'aria-required': true,
                    type: 'tel',
                    autoComplete: 'tel'
                  }}
                  helperText="Enter your 10-digit mobile number"
                  id="phone-input"
                  error={error && error.includes('mobile')}
                />
                
                <Button
                  variant="contained"
                  onClick={handleSendOTP}
                  disabled={isLoading || !phone}
                  fullWidth
                  size="large"
                >
                  {isLoading ? <CircularProgress size={24} /> : 'Send OTP'}
                </Button>
              </>
            ) : (
              <>
                <Box>
                  <Typography variant="body1" gutterBottom>
                    Enter the 6-digit OTP sent to
                  </Typography>
                  <Typography variant="body2" color="primary.main" sx={{ fontWeight: 'medium' }}>
                    +91 {phone}
                  </Typography>
                </Box>
                
                <TextField
                  fullWidth
                  label="OTP"
                  value={otp}
                  onChange={(e) => setOtp(e.target.value)}
                  placeholder="Enter 6-digit OTP"
                  InputProps={{
                    startAdornment: <Security sx={{ mr: 1, color: 'text.secondary' }} />
                  }}
                  inputProps={{ 
                    maxLength: 6,
                    'aria-describedby': 'otp-helper-text',
                    'aria-required': true,
                    type: 'text',
                    inputMode: 'numeric',
                    pattern: '[0-9]*',
                    autoComplete: 'one-time-code'
                  }}
                  helperText="Enter the 6-digit OTP sent to your mobile"
                  id="otp-input"
                  error={error && error.includes('OTP')}
                />
                
                <Button
                  variant="contained"
                  onClick={handleVerifyOTP}
                  disabled={isLoading || !otp}
                  fullWidth
                  size="large"
                >
                  {isLoading ? <CircularProgress size={24} /> : 'Verify OTP'}
                </Button>
                
                <Button
                  variant="text"
                  onClick={handleResendOTP}
                  disabled={isLoading}
                  fullWidth
                >
                  Resend OTP
                </Button>
              </>
            )}
            
            <Box sx={{ textAlign: 'center' }}>
              <Typography variant="body2" color="text.secondary">
                New to Kheti Sahayak?{' '}
                <Button variant="text" onClick={onRegister} sx={{ p: 0, minWidth: 'auto' }}>
                  Register here
                </Button>
              </Typography>
            </Box>
          </Stack>
        </CardContent>
      </Card>
    </Box>
  );
};

export default LoginForm;