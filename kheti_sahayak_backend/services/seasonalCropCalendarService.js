const { getAgroClimaticZone, INDIAN_STATES } = require('./geocodingService');

const MONTHS = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];

const SEASONS = {
  KHARIF: {
    name: 'Kharif',
    name_hi: 'खरीफ',
    startMonth: 6,
    endMonth: 10,
    description: 'Monsoon cropping season (June-October)',
    description_hi: 'मानसून फसल मौसम (जून-अक्टूबर)'
  },
  RABI: {
    name: 'Rabi',
    name_hi: 'रबी',
    startMonth: 11,
    endMonth: 3,
    description: 'Winter cropping season (November-March)',
    description_hi: 'सर्दियों की फसल का मौसम (नवंबर-मार्च)'
  },
  ZAID: {
    name: 'Zaid',
    name_hi: 'जायद',
    startMonth: 4,
    endMonth: 6,
    description: 'Summer cropping season (April-June)',
    description_hi: 'गर्मी की फसल का मौसम (अप्रैल-जून)'
  }
};

const STATE_CROP_CALENDARS = {
  'MH': {
    stateName: 'Maharashtra',
    kharif: [
      { crop: 'Rice', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'October', harvestEnd: 'November', waterReq: 'High' },
      { crop: 'Cotton', sowingStart: 'May', sowingEnd: 'June', harvestStart: 'October', harvestEnd: 'December', waterReq: 'Medium' },
      { crop: 'Soybean', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'October', harvestEnd: 'November', waterReq: 'Medium' },
      { crop: 'Groundnut', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'October', harvestEnd: 'November', waterReq: 'Medium' },
      { crop: 'Jowar', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'September', harvestEnd: 'October', waterReq: 'Low' },
      { crop: 'Bajra', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'September', harvestEnd: 'October', waterReq: 'Low' },
      { crop: 'Tur/Arhar', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'November', harvestEnd: 'January', waterReq: 'Medium' },
      { crop: 'Sugarcane', sowingStart: 'January', sowingEnd: 'March', harvestStart: 'December', harvestEnd: 'March', waterReq: 'Very High' }
    ],
    rabi: [
      { crop: 'Wheat', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'March', harvestEnd: 'April', waterReq: 'Medium' },
      { crop: 'Gram/Chickpea', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'February', harvestEnd: 'March', waterReq: 'Low' },
      { crop: 'Jowar (Rabi)', sowingStart: 'September', sowingEnd: 'October', harvestStart: 'January', harvestEnd: 'February', waterReq: 'Low' },
      { crop: 'Onion', sowingStart: 'October', sowingEnd: 'December', harvestStart: 'March', harvestEnd: 'May', waterReq: 'Medium' },
      { crop: 'Safflower', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'February', harvestEnd: 'March', waterReq: 'Low' }
    ],
    zaid: [
      { crop: 'Watermelon', sowingStart: 'February', sowingEnd: 'March', harvestStart: 'April', harvestEnd: 'May', waterReq: 'High' },
      { crop: 'Muskmelon', sowingStart: 'February', sowingEnd: 'March', harvestStart: 'April', harvestEnd: 'May', waterReq: 'High' },
      { crop: 'Cucumber', sowingStart: 'February', sowingEnd: 'March', harvestStart: 'April', harvestEnd: 'May', waterReq: 'Medium' },
      { crop: 'Vegetables', sowingStart: 'February', sowingEnd: 'April', harvestStart: 'April', harvestEnd: 'June', waterReq: 'Medium' }
    ]
  },
  'UP': {
    stateName: 'Uttar Pradesh',
    kharif: [
      { crop: 'Rice', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'October', harvestEnd: 'November', waterReq: 'High' },
      { crop: 'Sugarcane', sowingStart: 'February', sowingEnd: 'March', harvestStart: 'November', harvestEnd: 'February', waterReq: 'Very High' },
      { crop: 'Maize', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'September', harvestEnd: 'October', waterReq: 'Medium' },
      { crop: 'Bajra', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'September', harvestEnd: 'October', waterReq: 'Low' },
      { crop: 'Groundnut', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'October', harvestEnd: 'November', waterReq: 'Medium' },
      { crop: 'Urad', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'September', harvestEnd: 'October', waterReq: 'Low' }
    ],
    rabi: [
      { crop: 'Wheat', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'March', harvestEnd: 'April', waterReq: 'Medium' },
      { crop: 'Mustard', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'February', harvestEnd: 'March', waterReq: 'Low' },
      { crop: 'Gram', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'February', harvestEnd: 'March', waterReq: 'Low' },
      { crop: 'Peas', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'February', harvestEnd: 'March', waterReq: 'Medium' },
      { crop: 'Potato', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'January', harvestEnd: 'March', waterReq: 'High' },
      { crop: 'Barley', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'March', harvestEnd: 'April', waterReq: 'Low' }
    ],
    zaid: [
      { crop: 'Watermelon', sowingStart: 'February', sowingEnd: 'March', harvestStart: 'May', harvestEnd: 'June', waterReq: 'High' },
      { crop: 'Cucumber', sowingStart: 'February', sowingEnd: 'March', harvestStart: 'April', harvestEnd: 'June', waterReq: 'Medium' },
      { crop: 'Moong', sowingStart: 'March', sowingEnd: 'April', harvestStart: 'May', harvestEnd: 'June', waterReq: 'Low' },
      { crop: 'Fodder Crops', sowingStart: 'March', sowingEnd: 'April', harvestStart: 'May', harvestEnd: 'June', waterReq: 'Medium' }
    ]
  },
  'PB': {
    stateName: 'Punjab',
    kharif: [
      { crop: 'Rice', sowingStart: 'May', sowingEnd: 'June', harvestStart: 'October', harvestEnd: 'November', waterReq: 'Very High' },
      { crop: 'Cotton', sowingStart: 'April', sowingEnd: 'May', harvestStart: 'October', harvestEnd: 'December', waterReq: 'High' },
      { crop: 'Maize', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'September', harvestEnd: 'October', waterReq: 'Medium' },
      { crop: 'Sugarcane', sowingStart: 'February', sowingEnd: 'March', harvestStart: 'December', harvestEnd: 'March', waterReq: 'Very High' }
    ],
    rabi: [
      { crop: 'Wheat', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'April', harvestEnd: 'May', waterReq: 'Medium' },
      { crop: 'Potato', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'January', harvestEnd: 'February', waterReq: 'High' },
      { crop: 'Mustard', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'March', harvestEnd: 'April', waterReq: 'Low' },
      { crop: 'Peas', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'February', harvestEnd: 'March', waterReq: 'Medium' }
    ],
    zaid: [
      { crop: 'Moong', sowingStart: 'March', sowingEnd: 'April', harvestStart: 'May', harvestEnd: 'June', waterReq: 'Low' },
      { crop: 'Vegetables', sowingStart: 'February', sowingEnd: 'April', harvestStart: 'April', harvestEnd: 'June', waterReq: 'Medium' }
    ]
  },
  'MP': {
    stateName: 'Madhya Pradesh',
    kharif: [
      { crop: 'Soybean', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'October', harvestEnd: 'November', waterReq: 'Medium' },
      { crop: 'Rice', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'November', harvestEnd: 'December', waterReq: 'High' },
      { crop: 'Maize', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'September', harvestEnd: 'October', waterReq: 'Medium' },
      { crop: 'Cotton', sowingStart: 'May', sowingEnd: 'June', harvestStart: 'October', harvestEnd: 'December', waterReq: 'Medium' },
      { crop: 'Jowar', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'September', harvestEnd: 'October', waterReq: 'Low' },
      { crop: 'Tur/Arhar', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'January', harvestEnd: 'February', waterReq: 'Low' }
    ],
    rabi: [
      { crop: 'Wheat', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'March', harvestEnd: 'April', waterReq: 'Medium' },
      { crop: 'Gram/Chickpea', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'February', harvestEnd: 'March', waterReq: 'Low' },
      { crop: 'Lentil/Masoor', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'February', harvestEnd: 'March', waterReq: 'Low' },
      { crop: 'Mustard', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'February', harvestEnd: 'March', waterReq: 'Low' },
      { crop: 'Potato', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'January', harvestEnd: 'February', waterReq: 'High' }
    ],
    zaid: [
      { crop: 'Watermelon', sowingStart: 'February', sowingEnd: 'March', harvestStart: 'April', harvestEnd: 'May', waterReq: 'High' },
      { crop: 'Moong', sowingStart: 'March', sowingEnd: 'April', harvestStart: 'May', harvestEnd: 'June', waterReq: 'Low' }
    ]
  },
  'RJ': {
    stateName: 'Rajasthan',
    kharif: [
      { crop: 'Bajra', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'September', harvestEnd: 'October', waterReq: 'Very Low' },
      { crop: 'Maize', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'September', harvestEnd: 'October', waterReq: 'Medium' },
      { crop: 'Groundnut', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'October', harvestEnd: 'November', waterReq: 'Medium' },
      { crop: 'Moth', sowingStart: 'July', sowingEnd: 'August', harvestStart: 'September', harvestEnd: 'October', waterReq: 'Very Low' },
      { crop: 'Guar', sowingStart: 'July', sowingEnd: 'August', harvestStart: 'October', harvestEnd: 'November', waterReq: 'Very Low' },
      { crop: 'Cotton', sowingStart: 'April', sowingEnd: 'May', harvestStart: 'October', harvestEnd: 'December', waterReq: 'Medium' }
    ],
    rabi: [
      { crop: 'Wheat', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'March', harvestEnd: 'April', waterReq: 'Medium' },
      { crop: 'Mustard', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'February', harvestEnd: 'March', waterReq: 'Low' },
      { crop: 'Gram', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'February', harvestEnd: 'March', waterReq: 'Low' },
      { crop: 'Barley', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'March', harvestEnd: 'April', waterReq: 'Low' },
      { crop: 'Cumin', sowingStart: 'November', sowingEnd: 'December', harvestStart: 'March', harvestEnd: 'April', waterReq: 'Low' }
    ],
    zaid: [
      { crop: 'Watermelon', sowingStart: 'February', sowingEnd: 'March', harvestStart: 'April', harvestEnd: 'May', waterReq: 'High' },
      { crop: 'Muskmelon', sowingStart: 'February', sowingEnd: 'March', harvestStart: 'April', harvestEnd: 'May', waterReq: 'High' }
    ]
  },
  'GJ': {
    stateName: 'Gujarat',
    kharif: [
      { crop: 'Cotton', sowingStart: 'May', sowingEnd: 'June', harvestStart: 'October', harvestEnd: 'December', waterReq: 'Medium' },
      { crop: 'Groundnut', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'October', harvestEnd: 'November', waterReq: 'Medium' },
      { crop: 'Rice', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'November', harvestEnd: 'December', waterReq: 'High' },
      { crop: 'Castor', sowingStart: 'July', sowingEnd: 'August', harvestStart: 'January', harvestEnd: 'March', waterReq: 'Low' },
      { crop: 'Bajra', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'September', harvestEnd: 'October', waterReq: 'Low' }
    ],
    rabi: [
      { crop: 'Wheat', sowingStart: 'November', sowingEnd: 'December', harvestStart: 'March', harvestEnd: 'April', waterReq: 'Medium' },
      { crop: 'Tobacco', sowingStart: 'September', sowingEnd: 'October', harvestStart: 'February', harvestEnd: 'March', waterReq: 'Medium' },
      { crop: 'Gram', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'February', harvestEnd: 'March', waterReq: 'Low' },
      { crop: 'Cumin', sowingStart: 'November', sowingEnd: 'December', harvestStart: 'March', harvestEnd: 'April', waterReq: 'Low' }
    ],
    zaid: [
      { crop: 'Vegetables', sowingStart: 'February', sowingEnd: 'April', harvestStart: 'April', harvestEnd: 'June', waterReq: 'Medium' },
      { crop: 'Fodder', sowingStart: 'March', sowingEnd: 'April', harvestStart: 'May', harvestEnd: 'June', waterReq: 'Medium' }
    ]
  },
  'KA': {
    stateName: 'Karnataka',
    kharif: [
      { crop: 'Rice', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'October', harvestEnd: 'December', waterReq: 'High' },
      { crop: 'Ragi', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'October', harvestEnd: 'November', waterReq: 'Medium' },
      { crop: 'Jowar', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'October', harvestEnd: 'November', waterReq: 'Low' },
      { crop: 'Maize', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'September', harvestEnd: 'October', waterReq: 'Medium' },
      { crop: 'Groundnut', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'October', harvestEnd: 'November', waterReq: 'Medium' },
      { crop: 'Cotton', sowingStart: 'May', sowingEnd: 'June', harvestStart: 'October', harvestEnd: 'December', waterReq: 'Medium' },
      { crop: 'Sugarcane', sowingStart: 'January', sowingEnd: 'March', harvestStart: 'November', harvestEnd: 'February', waterReq: 'Very High' }
    ],
    rabi: [
      { crop: 'Jowar (Rabi)', sowingStart: 'September', sowingEnd: 'October', harvestStart: 'January', harvestEnd: 'February', waterReq: 'Low' },
      { crop: 'Wheat', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'March', harvestEnd: 'April', waterReq: 'Medium' },
      { crop: 'Gram', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'January', harvestEnd: 'February', waterReq: 'Low' },
      { crop: 'Sunflower', sowingStart: 'September', sowingEnd: 'October', harvestStart: 'January', harvestEnd: 'February', waterReq: 'Medium' }
    ],
    zaid: [
      { crop: 'Vegetables', sowingStart: 'February', sowingEnd: 'April', harvestStart: 'April', harvestEnd: 'June', waterReq: 'Medium' },
      { crop: 'Watermelon', sowingStart: 'February', sowingEnd: 'March', harvestStart: 'April', harvestEnd: 'May', waterReq: 'High' }
    ]
  },
  'AP': {
    stateName: 'Andhra Pradesh',
    kharif: [
      { crop: 'Rice', sowingStart: 'June', sowingEnd: 'August', harvestStart: 'November', harvestEnd: 'January', waterReq: 'High' },
      { crop: 'Groundnut', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'October', harvestEnd: 'November', waterReq: 'Medium' },
      { crop: 'Cotton', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'October', harvestEnd: 'December', waterReq: 'Medium' },
      { crop: 'Maize', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'September', harvestEnd: 'October', waterReq: 'Medium' },
      { crop: 'Chillies', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'November', harvestEnd: 'February', waterReq: 'Medium' }
    ],
    rabi: [
      { crop: 'Rice (Rabi)', sowingStart: 'November', sowingEnd: 'December', harvestStart: 'March', harvestEnd: 'April', waterReq: 'High' },
      { crop: 'Groundnut', sowingStart: 'December', sowingEnd: 'January', harvestStart: 'April', harvestEnd: 'May', waterReq: 'Medium' },
      { crop: 'Sunflower', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'February', harvestEnd: 'March', waterReq: 'Medium' },
      { crop: 'Black Gram', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'January', harvestEnd: 'February', waterReq: 'Low' }
    ],
    zaid: [
      { crop: 'Vegetables', sowingStart: 'February', sowingEnd: 'April', harvestStart: 'April', harvestEnd: 'June', waterReq: 'Medium' },
      { crop: 'Green Gram', sowingStart: 'March', sowingEnd: 'April', harvestStart: 'May', harvestEnd: 'June', waterReq: 'Low' }
    ]
  },
  'TN': {
    stateName: 'Tamil Nadu',
    kharif: [
      { crop: 'Rice (Samba)', sowingStart: 'August', sowingEnd: 'September', harvestStart: 'January', harvestEnd: 'February', waterReq: 'High' },
      { crop: 'Groundnut', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'October', harvestEnd: 'November', waterReq: 'Medium' },
      { crop: 'Cotton', sowingStart: 'July', sowingEnd: 'August', harvestStart: 'December', harvestEnd: 'February', waterReq: 'Medium' },
      { crop: 'Maize', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'September', harvestEnd: 'October', waterReq: 'Medium' },
      { crop: 'Sugarcane', sowingStart: 'January', sowingEnd: 'March', harvestStart: 'December', harvestEnd: 'March', waterReq: 'Very High' },
      { crop: 'Millets (Cumbu)', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'September', harvestEnd: 'October', waterReq: 'Low' }
    ],
    rabi: [
      { crop: 'Rice (Kuruvai)', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'September', harvestEnd: 'October', waterReq: 'High' },
      { crop: 'Groundnut', sowingStart: 'December', sowingEnd: 'January', harvestStart: 'March', harvestEnd: 'April', waterReq: 'Medium' },
      { crop: 'Black Gram', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'January', harvestEnd: 'February', waterReq: 'Low' },
      { crop: 'Green Gram', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'January', harvestEnd: 'February', waterReq: 'Low' },
      { crop: 'Sesame', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'January', harvestEnd: 'February', waterReq: 'Low' }
    ],
    zaid: [
      { crop: 'Vegetables', sowingStart: 'February', sowingEnd: 'April', harvestStart: 'April', harvestEnd: 'June', waterReq: 'Medium' },
      { crop: 'Watermelon', sowingStart: 'February', sowingEnd: 'March', harvestStart: 'April', harvestEnd: 'May', waterReq: 'High' },
      { crop: 'Banana', sowingStart: 'February', sowingEnd: 'April', harvestStart: 'November', harvestEnd: 'February', waterReq: 'High' }
    ]
  },
  'WB': {
    stateName: 'West Bengal',
    kharif: [
      { crop: 'Rice (Aman)', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'November', harvestEnd: 'December', waterReq: 'High' },
      { crop: 'Jute', sowingStart: 'March', sowingEnd: 'May', harvestStart: 'August', harvestEnd: 'September', waterReq: 'High' },
      { crop: 'Maize', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'September', harvestEnd: 'October', waterReq: 'Medium' },
      { crop: 'Sesame', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'September', harvestEnd: 'October', waterReq: 'Low' },
      { crop: 'Groundnut', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'October', harvestEnd: 'November', waterReq: 'Medium' }
    ],
    rabi: [
      { crop: 'Rice (Boro)', sowingStart: 'November', sowingEnd: 'December', harvestStart: 'April', harvestEnd: 'May', waterReq: 'High' },
      { crop: 'Wheat', sowingStart: 'November', sowingEnd: 'December', harvestStart: 'March', harvestEnd: 'April', waterReq: 'Medium' },
      { crop: 'Potato', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'February', harvestEnd: 'March', waterReq: 'High' },
      { crop: 'Mustard', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'February', harvestEnd: 'March', waterReq: 'Low' },
      { crop: 'Lentil', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'February', harvestEnd: 'March', waterReq: 'Low' }
    ],
    zaid: [
      { crop: 'Rice (Aus)', sowingStart: 'March', sowingEnd: 'April', harvestStart: 'July', harvestEnd: 'August', waterReq: 'High' },
      { crop: 'Vegetables', sowingStart: 'February', sowingEnd: 'April', harvestStart: 'April', harvestEnd: 'June', waterReq: 'Medium' },
      { crop: 'Moong', sowingStart: 'March', sowingEnd: 'April', harvestStart: 'May', harvestEnd: 'June', waterReq: 'Low' }
    ]
  },
  'BR': {
    stateName: 'Bihar',
    kharif: [
      { crop: 'Rice', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'October', harvestEnd: 'November', waterReq: 'High' },
      { crop: 'Maize', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'September', harvestEnd: 'October', waterReq: 'Medium' },
      { crop: 'Sugarcane', sowingStart: 'February', sowingEnd: 'March', harvestStart: 'December', harvestEnd: 'March', waterReq: 'Very High' },
      { crop: 'Jute', sowingStart: 'April', sowingEnd: 'May', harvestStart: 'August', harvestEnd: 'September', waterReq: 'High' },
      { crop: 'Bajra', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'September', harvestEnd: 'October', waterReq: 'Low' }
    ],
    rabi: [
      { crop: 'Wheat', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'March', harvestEnd: 'April', waterReq: 'Medium' },
      { crop: 'Maize (Rabi)', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'March', harvestEnd: 'April', waterReq: 'Medium' },
      { crop: 'Gram', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'February', harvestEnd: 'March', waterReq: 'Low' },
      { crop: 'Lentil', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'February', harvestEnd: 'March', waterReq: 'Low' },
      { crop: 'Potato', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'January', harvestEnd: 'February', waterReq: 'High' },
      { crop: 'Mustard', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'February', harvestEnd: 'March', waterReq: 'Low' }
    ],
    zaid: [
      { crop: 'Moong', sowingStart: 'March', sowingEnd: 'April', harvestStart: 'May', harvestEnd: 'June', waterReq: 'Low' },
      { crop: 'Vegetables', sowingStart: 'February', sowingEnd: 'April', harvestStart: 'April', harvestEnd: 'June', waterReq: 'Medium' },
      { crop: 'Watermelon', sowingStart: 'February', sowingEnd: 'March', harvestStart: 'April', harvestEnd: 'May', waterReq: 'High' }
    ]
  },
  'OR': {
    stateName: 'Odisha',
    kharif: [
      { crop: 'Rice', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'November', harvestEnd: 'December', waterReq: 'High' },
      { crop: 'Groundnut', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'October', harvestEnd: 'November', waterReq: 'Medium' },
      { crop: 'Maize', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'September', harvestEnd: 'October', waterReq: 'Medium' },
      { crop: 'Sugarcane', sowingStart: 'January', sowingEnd: 'March', harvestStart: 'December', harvestEnd: 'March', waterReq: 'Very High' },
      { crop: 'Sesame', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'September', harvestEnd: 'October', waterReq: 'Low' },
      { crop: 'Green Gram', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'September', harvestEnd: 'October', waterReq: 'Low' }
    ],
    rabi: [
      { crop: 'Rice (Rabi)', sowingStart: 'November', sowingEnd: 'December', harvestStart: 'April', harvestEnd: 'May', waterReq: 'High' },
      { crop: 'Groundnut', sowingStart: 'December', sowingEnd: 'January', harvestStart: 'April', harvestEnd: 'May', waterReq: 'Medium' },
      { crop: 'Mustard', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'February', harvestEnd: 'March', waterReq: 'Low' },
      { crop: 'Sunflower', sowingStart: 'November', sowingEnd: 'December', harvestStart: 'February', harvestEnd: 'March', waterReq: 'Medium' },
      { crop: 'Gram', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'January', harvestEnd: 'February', waterReq: 'Low' }
    ],
    zaid: [
      { crop: 'Vegetables', sowingStart: 'February', sowingEnd: 'April', harvestStart: 'April', harvestEnd: 'June', waterReq: 'Medium' },
      { crop: 'Green Gram', sowingStart: 'March', sowingEnd: 'April', harvestStart: 'May', harvestEnd: 'June', waterReq: 'Low' },
      { crop: 'Black Gram', sowingStart: 'March', sowingEnd: 'April', harvestStart: 'May', harvestEnd: 'June', waterReq: 'Low' }
    ]
  },
  'HR': {
    stateName: 'Haryana',
    kharif: [
      { crop: 'Rice', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'October', harvestEnd: 'November', waterReq: 'Very High' },
      { crop: 'Cotton', sowingStart: 'April', sowingEnd: 'May', harvestStart: 'October', harvestEnd: 'December', waterReq: 'High' },
      { crop: 'Bajra', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'September', harvestEnd: 'October', waterReq: 'Low' },
      { crop: 'Sugarcane', sowingStart: 'February', sowingEnd: 'March', harvestStart: 'December', harvestEnd: 'March', waterReq: 'Very High' },
      { crop: 'Maize', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'September', harvestEnd: 'October', waterReq: 'Medium' },
      { crop: 'Guar', sowingStart: 'July', sowingEnd: 'August', harvestStart: 'October', harvestEnd: 'November', waterReq: 'Very Low' }
    ],
    rabi: [
      { crop: 'Wheat', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'April', harvestEnd: 'May', waterReq: 'Medium' },
      { crop: 'Mustard', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'March', harvestEnd: 'April', waterReq: 'Low' },
      { crop: 'Gram', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'March', harvestEnd: 'April', waterReq: 'Low' },
      { crop: 'Barley', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'March', harvestEnd: 'April', waterReq: 'Low' },
      { crop: 'Potato', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'January', harvestEnd: 'February', waterReq: 'High' }
    ],
    zaid: [
      { crop: 'Moong', sowingStart: 'March', sowingEnd: 'April', harvestStart: 'May', harvestEnd: 'June', waterReq: 'Low' },
      { crop: 'Vegetables', sowingStart: 'February', sowingEnd: 'April', harvestStart: 'April', harvestEnd: 'June', waterReq: 'Medium' },
      { crop: 'Fodder', sowingStart: 'March', sowingEnd: 'April', harvestStart: 'May', harvestEnd: 'June', waterReq: 'Medium' }
    ]
  },
  'TL': {
    stateName: 'Telangana',
    kharif: [
      { crop: 'Rice', sowingStart: 'June', sowingEnd: 'August', harvestStart: 'November', harvestEnd: 'January', waterReq: 'High' },
      { crop: 'Cotton', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'October', harvestEnd: 'December', waterReq: 'Medium' },
      { crop: 'Maize', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'September', harvestEnd: 'October', waterReq: 'Medium' },
      { crop: 'Soybean', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'October', harvestEnd: 'November', waterReq: 'Medium' },
      { crop: 'Groundnut', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'October', harvestEnd: 'November', waterReq: 'Medium' },
      { crop: 'Red Gram (Tur)', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'December', harvestEnd: 'January', waterReq: 'Low' },
      { crop: 'Chillies', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'November', harvestEnd: 'February', waterReq: 'Medium' }
    ],
    rabi: [
      { crop: 'Rice (Rabi)', sowingStart: 'November', sowingEnd: 'December', harvestStart: 'March', harvestEnd: 'April', waterReq: 'High' },
      { crop: 'Groundnut', sowingStart: 'December', sowingEnd: 'January', harvestStart: 'April', harvestEnd: 'May', waterReq: 'Medium' },
      { crop: 'Sunflower', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'February', harvestEnd: 'March', waterReq: 'Medium' },
      { crop: 'Bengal Gram', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'January', harvestEnd: 'February', waterReq: 'Low' },
      { crop: 'Maize (Rabi)', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'February', harvestEnd: 'March', waterReq: 'Medium' }
    ],
    zaid: [
      { crop: 'Vegetables', sowingStart: 'February', sowingEnd: 'April', harvestStart: 'April', harvestEnd: 'June', waterReq: 'Medium' },
      { crop: 'Green Gram', sowingStart: 'March', sowingEnd: 'April', harvestStart: 'May', harvestEnd: 'June', waterReq: 'Low' },
      { crop: 'Watermelon', sowingStart: 'February', sowingEnd: 'March', harvestStart: 'April', harvestEnd: 'May', waterReq: 'High' }
    ]
  },
  'AS': {
    stateName: 'Assam',
    kharif: [
      { crop: 'Rice (Sali)', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'November', harvestEnd: 'December', waterReq: 'High' },
      { crop: 'Jute', sowingStart: 'March', sowingEnd: 'May', harvestStart: 'August', harvestEnd: 'September', waterReq: 'High' },
      { crop: 'Sugarcane', sowingStart: 'February', sowingEnd: 'March', harvestStart: 'January', harvestEnd: 'March', waterReq: 'Very High' },
      { crop: 'Maize', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'September', harvestEnd: 'October', waterReq: 'Medium' },
      { crop: 'Sesame', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'September', harvestEnd: 'October', waterReq: 'Low' }
    ],
    rabi: [
      { crop: 'Rice (Boro)', sowingStart: 'November', sowingEnd: 'December', harvestStart: 'April', harvestEnd: 'May', waterReq: 'High' },
      { crop: 'Wheat', sowingStart: 'November', sowingEnd: 'December', harvestStart: 'March', harvestEnd: 'April', waterReq: 'Medium' },
      { crop: 'Potato', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'January', harvestEnd: 'February', waterReq: 'High' },
      { crop: 'Mustard', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'February', harvestEnd: 'March', waterReq: 'Low' },
      { crop: 'Peas', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'February', harvestEnd: 'March', waterReq: 'Medium' },
      { crop: 'Lentil', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'February', harvestEnd: 'March', waterReq: 'Low' }
    ],
    zaid: [
      { crop: 'Rice (Ahu)', sowingStart: 'February', sowingEnd: 'March', harvestStart: 'June', harvestEnd: 'July', waterReq: 'High' },
      { crop: 'Vegetables', sowingStart: 'February', sowingEnd: 'April', harvestStart: 'April', harvestEnd: 'June', waterReq: 'Medium' },
      { crop: 'Black Gram', sowingStart: 'March', sowingEnd: 'April', harvestStart: 'May', harvestEnd: 'June', waterReq: 'Low' }
    ]
  },
  'JH': {
    stateName: 'Jharkhand',
    kharif: [
      { crop: 'Rice', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'November', harvestEnd: 'December', waterReq: 'High' },
      { crop: 'Maize', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'September', harvestEnd: 'October', waterReq: 'Medium' },
      { crop: 'Arhar/Tur', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'December', harvestEnd: 'January', waterReq: 'Low' },
      { crop: 'Groundnut', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'October', harvestEnd: 'November', waterReq: 'Medium' },
      { crop: 'Niger', sowingStart: 'August', sowingEnd: 'September', harvestStart: 'December', harvestEnd: 'January', waterReq: 'Low' }
    ],
    rabi: [
      { crop: 'Wheat', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'March', harvestEnd: 'April', waterReq: 'Medium' },
      { crop: 'Gram', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'February', harvestEnd: 'March', waterReq: 'Low' },
      { crop: 'Lentil', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'February', harvestEnd: 'March', waterReq: 'Low' },
      { crop: 'Mustard', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'February', harvestEnd: 'March', waterReq: 'Low' },
      { crop: 'Potato', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'January', harvestEnd: 'February', waterReq: 'High' }
    ],
    zaid: [
      { crop: 'Vegetables', sowingStart: 'February', sowingEnd: 'April', harvestStart: 'April', harvestEnd: 'June', waterReq: 'Medium' },
      { crop: 'Moong', sowingStart: 'March', sowingEnd: 'April', harvestStart: 'May', harvestEnd: 'June', waterReq: 'Low' }
    ]
  },
  'CG': {
    stateName: 'Chhattisgarh',
    kharif: [
      { crop: 'Rice', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'November', harvestEnd: 'December', waterReq: 'High' },
      { crop: 'Maize', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'September', harvestEnd: 'October', waterReq: 'Medium' },
      { crop: 'Soybean', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'October', harvestEnd: 'November', waterReq: 'Medium' },
      { crop: 'Arhar/Tur', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'January', harvestEnd: 'February', waterReq: 'Low' },
      { crop: 'Groundnut', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'October', harvestEnd: 'November', waterReq: 'Medium' },
      { crop: 'Kodo-Kutki', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'October', harvestEnd: 'November', waterReq: 'Very Low' }
    ],
    rabi: [
      { crop: 'Wheat', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'March', harvestEnd: 'April', waterReq: 'Medium' },
      { crop: 'Gram', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'February', harvestEnd: 'March', waterReq: 'Low' },
      { crop: 'Lentil', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'February', harvestEnd: 'March', waterReq: 'Low' },
      { crop: 'Mustard', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'February', harvestEnd: 'March', waterReq: 'Low' },
      { crop: 'Linseed', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'February', harvestEnd: 'March', waterReq: 'Low' }
    ],
    zaid: [
      { crop: 'Vegetables', sowingStart: 'February', sowingEnd: 'April', harvestStart: 'April', harvestEnd: 'June', waterReq: 'Medium' },
      { crop: 'Watermelon', sowingStart: 'February', sowingEnd: 'March', harvestStart: 'April', harvestEnd: 'May', waterReq: 'High' }
    ]
  },
  'UK': {
    stateName: 'Uttarakhand',
    kharif: [
      { crop: 'Rice', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'October', harvestEnd: 'November', waterReq: 'High' },
      { crop: 'Maize', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'September', harvestEnd: 'October', waterReq: 'Medium' },
      { crop: 'Mandua (Finger Millet)', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'October', harvestEnd: 'November', waterReq: 'Low' },
      { crop: 'Soybean', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'October', harvestEnd: 'November', waterReq: 'Medium' },
      { crop: 'Jhangora (Barnyard Millet)', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'September', harvestEnd: 'October', waterReq: 'Very Low' }
    ],
    rabi: [
      { crop: 'Wheat', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'April', harvestEnd: 'May', waterReq: 'Medium' },
      { crop: 'Barley', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'April', harvestEnd: 'May', waterReq: 'Low' },
      { crop: 'Mustard', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'March', harvestEnd: 'April', waterReq: 'Low' },
      { crop: 'Lentil', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'March', harvestEnd: 'April', waterReq: 'Low' },
      { crop: 'Peas', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'February', harvestEnd: 'March', waterReq: 'Medium' }
    ],
    zaid: [
      { crop: 'Vegetables', sowingStart: 'February', sowingEnd: 'April', harvestStart: 'April', harvestEnd: 'June', waterReq: 'Medium' },
      { crop: 'Rajma (Kidney Beans)', sowingStart: 'March', sowingEnd: 'April', harvestStart: 'June', harvestEnd: 'July', waterReq: 'Medium' }
    ]
  },
  'HP': {
    stateName: 'Himachal Pradesh',
    kharif: [
      { crop: 'Rice', sowingStart: 'May', sowingEnd: 'June', harvestStart: 'October', harvestEnd: 'November', waterReq: 'High' },
      { crop: 'Maize', sowingStart: 'May', sowingEnd: 'June', harvestStart: 'September', harvestEnd: 'October', waterReq: 'Medium' },
      { crop: 'Apple (Harvest)', sowingStart: 'August', sowingEnd: 'October', harvestStart: 'August', harvestEnd: 'October', waterReq: 'Medium' },
      { crop: 'Potato (Kharif)', sowingStart: 'February', sowingEnd: 'March', harvestStart: 'June', harvestEnd: 'July', waterReq: 'High' },
      { crop: 'Ginger', sowingStart: 'April', sowingEnd: 'May', harvestStart: 'December', harvestEnd: 'January', waterReq: 'High' }
    ],
    rabi: [
      { crop: 'Wheat', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'April', harvestEnd: 'May', waterReq: 'Medium' },
      { crop: 'Barley', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'April', harvestEnd: 'May', waterReq: 'Low' },
      { crop: 'Potato (Rabi)', sowingStart: 'September', sowingEnd: 'October', harvestStart: 'December', harvestEnd: 'January', waterReq: 'High' },
      { crop: 'Peas', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'March', harvestEnd: 'April', waterReq: 'Medium' },
      { crop: 'Garlic', sowingStart: 'September', sowingEnd: 'October', harvestStart: 'April', harvestEnd: 'May', waterReq: 'Medium' }
    ],
    zaid: [
      { crop: 'Vegetables', sowingStart: 'February', sowingEnd: 'April', harvestStart: 'April', harvestEnd: 'June', waterReq: 'Medium' },
      { crop: 'Off-season vegetables', sowingStart: 'January', sowingEnd: 'March', harvestStart: 'April', harvestEnd: 'June', waterReq: 'Medium' }
    ]
  },
  'KL': {
    stateName: 'Kerala',
    kharif: [
      { crop: 'Rice (Virippu)', sowingStart: 'May', sowingEnd: 'June', harvestStart: 'September', harvestEnd: 'October', waterReq: 'High' },
      { crop: 'Banana', sowingStart: 'May', sowingEnd: 'June', harvestStart: 'March', harvestEnd: 'May', waterReq: 'High' },
      { crop: 'Tapioca', sowingStart: 'May', sowingEnd: 'June', harvestStart: 'January', harvestEnd: 'March', waterReq: 'Medium' },
      { crop: 'Ginger', sowingStart: 'May', sowingEnd: 'June', harvestStart: 'January', harvestEnd: 'February', waterReq: 'High' },
      { crop: 'Turmeric', sowingStart: 'May', sowingEnd: 'June', harvestStart: 'January', harvestEnd: 'February', waterReq: 'High' }
    ],
    rabi: [
      { crop: 'Rice (Mundakan)', sowingStart: 'September', sowingEnd: 'October', harvestStart: 'January', harvestEnd: 'February', waterReq: 'High' },
      { crop: 'Vegetables', sowingStart: 'September', sowingEnd: 'November', harvestStart: 'December', harvestEnd: 'February', waterReq: 'Medium' },
      { crop: 'Coconut (Harvest)', sowingStart: 'November', sowingEnd: 'February', harvestStart: 'November', harvestEnd: 'February', waterReq: 'Medium' },
      { crop: 'Pepper (Harvest)', sowingStart: 'December', sowingEnd: 'January', harvestStart: 'December', harvestEnd: 'January', waterReq: 'Medium' }
    ],
    zaid: [
      { crop: 'Rice (Puncha)', sowingStart: 'December', sowingEnd: 'January', harvestStart: 'April', harvestEnd: 'May', waterReq: 'High' },
      { crop: 'Summer Vegetables', sowingStart: 'February', sowingEnd: 'April', harvestStart: 'April', harvestEnd: 'June', waterReq: 'High' },
      { crop: 'Watermelon', sowingStart: 'February', sowingEnd: 'March', harvestStart: 'April', harvestEnd: 'May', waterReq: 'High' }
    ]
  }
};

const DEFAULT_CALENDAR = {
  kharif: [
    { crop: 'Rice', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'October', harvestEnd: 'November', waterReq: 'High' },
    { crop: 'Maize', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'September', harvestEnd: 'October', waterReq: 'Medium' },
    { crop: 'Cotton', sowingStart: 'May', sowingEnd: 'June', harvestStart: 'October', harvestEnd: 'December', waterReq: 'Medium' },
    { crop: 'Soybean', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'October', harvestEnd: 'November', waterReq: 'Medium' },
    { crop: 'Groundnut', sowingStart: 'June', sowingEnd: 'July', harvestStart: 'October', harvestEnd: 'November', waterReq: 'Medium' }
  ],
  rabi: [
    { crop: 'Wheat', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'March', harvestEnd: 'April', waterReq: 'Medium' },
    { crop: 'Mustard', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'February', harvestEnd: 'March', waterReq: 'Low' },
    { crop: 'Gram/Chickpea', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'February', harvestEnd: 'March', waterReq: 'Low' },
    { crop: 'Peas', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'February', harvestEnd: 'March', waterReq: 'Medium' },
    { crop: 'Barley', sowingStart: 'October', sowingEnd: 'November', harvestStart: 'March', harvestEnd: 'April', waterReq: 'Low' }
  ],
  zaid: [
    { crop: 'Watermelon', sowingStart: 'February', sowingEnd: 'March', harvestStart: 'April', harvestEnd: 'May', waterReq: 'High' },
    { crop: 'Muskmelon', sowingStart: 'February', sowingEnd: 'March', harvestStart: 'April', harvestEnd: 'May', waterReq: 'High' },
    { crop: 'Cucumber', sowingStart: 'February', sowingEnd: 'March', harvestStart: 'April', harvestEnd: 'May', waterReq: 'Medium' },
    { crop: 'Moong', sowingStart: 'March', sowingEnd: 'April', harvestStart: 'May', harvestEnd: 'June', waterReq: 'Low' }
  ]
};

function getCurrentSeason() {
  const currentMonth = new Date().getMonth() + 1;
  
  if (currentMonth >= 6 && currentMonth <= 10) {
    return { ...SEASONS.KHARIF, key: 'KHARIF' };
  } else if (currentMonth >= 11 || currentMonth <= 3) {
    return { ...SEASONS.RABI, key: 'RABI' };
  } else {
    return { ...SEASONS.ZAID, key: 'ZAID' };
  }
}

function getSeasonPhase(season) {
  const currentMonth = new Date().getMonth() + 1;
  const seasonStart = season.startMonth;
  const seasonEnd = season.endMonth;
  
  let monthsIntoSeason;
  if (seasonStart <= seasonEnd) {
    monthsIntoSeason = currentMonth - seasonStart;
  } else {
    monthsIntoSeason = currentMonth >= seasonStart 
      ? currentMonth - seasonStart 
      : (12 - seasonStart) + currentMonth;
  }
  
  if (monthsIntoSeason <= 1) return 'early';
  if (monthsIntoSeason <= 3) return 'mid';
  return 'late';
}

function getCropCalendarByState(stateCode) {
  return STATE_CROP_CALENDARS[stateCode] || DEFAULT_CALENDAR;
}

function getCropStatus(crop, currentMonth) {
  const sowingStartIdx = MONTHS.indexOf(crop.sowingStart);
  const sowingEndIdx = MONTHS.indexOf(crop.sowingEnd);
  const harvestStartIdx = MONTHS.indexOf(crop.harvestStart);
  const harvestEndIdx = MONTHS.indexOf(crop.harvestEnd);
  const monthIdx = currentMonth - 1;
  
  if (monthIdx >= sowingStartIdx && monthIdx <= sowingEndIdx) {
    return { status: 'sowing', message: 'Optimal sowing time', message_hi: 'बुवाई का सर्वोत्तम समय' };
  }
  
  if (monthIdx >= harvestStartIdx && monthIdx <= harvestEndIdx) {
    return { status: 'harvest', message: 'Harvest time', message_hi: 'कटाई का समय' };
  }
  
  const isGrowing = (sowingEndIdx < harvestStartIdx)
    ? (monthIdx > sowingEndIdx && monthIdx < harvestStartIdx)
    : (monthIdx > sowingEndIdx || monthIdx < harvestStartIdx);
  
  if (isGrowing) {
    return { status: 'growing', message: 'Crop growing period', message_hi: 'फसल वृद्धि काल' };
  }
  
  return { status: 'off_season', message: 'Off season', message_hi: 'बंद मौसम' };
}

function getSeasonalCropCalendar(lat, lon, stateCode) {
  const currentSeason = getCurrentSeason();
  const phase = getSeasonPhase(currentSeason);
  const currentMonth = new Date().getMonth() + 1;
  const currentMonthName = MONTHS[currentMonth - 1];
  
  const calendar = getCropCalendarByState(stateCode);
  const seasonKey = currentSeason.key.toLowerCase();
  const crops = calendar[seasonKey] || [];
  
  const cropsWithStatus = crops.map(crop => ({
    ...crop,
    ...getCropStatus(crop, currentMonth)
  }));
  
  const agroZone = getAgroClimaticZone(lat, lon, stateCode);
  
  const sowingCrops = cropsWithStatus.filter(c => c.status === 'sowing');
  const harvestingCrops = cropsWithStatus.filter(c => c.status === 'harvest');
  const growingCrops = cropsWithStatus.filter(c => c.status === 'growing');
  
  const upcomingTasks = [];
  
  if (sowingCrops.length > 0) {
    upcomingTasks.push({
      type: 'sowing',
      priority: 'high',
      message: `Optimal sowing time for: ${sowingCrops.map(c => c.crop).join(', ')}`,
      message_hi: `बुवाई का सर्वोत्तम समय: ${sowingCrops.map(c => c.crop).join(', ')}`,
      crops: sowingCrops.map(c => c.crop)
    });
  }
  
  if (harvestingCrops.length > 0) {
    upcomingTasks.push({
      type: 'harvest',
      priority: 'high',
      message: `Harvest time for: ${harvestingCrops.map(c => c.crop).join(', ')}`,
      message_hi: `कटाई का समय: ${harvestingCrops.map(c => c.crop).join(', ')}`,
      crops: harvestingCrops.map(c => c.crop)
    });
  }
  
  if (growingCrops.length > 0) {
    upcomingTasks.push({
      type: 'maintenance',
      priority: 'medium',
      message: `Monitor and maintain: ${growingCrops.map(c => c.crop).join(', ')}`,
      message_hi: `निगरानी और रखरखाव: ${growingCrops.map(c => c.crop).join(', ')}`,
      crops: growingCrops.map(c => c.crop)
    });
  }
  
  return {
    location: {
      latitude: lat,
      longitude: lon,
      state_code: stateCode,
      state_name: calendar.stateName || 'India',
      agro_climatic_zone: agroZone
    },
    current_date: new Date().toISOString().split('T')[0],
    current_month: currentMonthName,
    season: {
      ...currentSeason,
      phase,
      phase_message: getPhaseMessage(currentSeason.name, phase)
    },
    crops: cropsWithStatus,
    summary: {
      sowing_now: sowingCrops.length,
      harvesting_now: harvestingCrops.length,
      growing_now: growingCrops.length
    },
    upcoming_tasks: upcomingTasks,
    next_season: getNextSeason(currentSeason.key),
    all_seasons: {
      kharif: { ...SEASONS.KHARIF, crops: calendar.kharif?.length || 0 },
      rabi: { ...SEASONS.RABI, crops: calendar.rabi?.length || 0 },
      zaid: { ...SEASONS.ZAID, crops: calendar.zaid?.length || 0 }
    }
  };
}

function getPhaseMessage(seasonName, phase) {
  const messages = {
    early: {
      en: `Early ${seasonName} - Focus on land preparation and sowing`,
      hi: `प्रारंभिक ${seasonName} - भूमि की तैयारी और बुवाई पर ध्यान दें`
    },
    mid: {
      en: `Mid ${seasonName} - Focus on crop management and pest control`,
      hi: `मध्य ${seasonName} - फसल प्रबंधन और कीट नियंत्रण पर ध्यान दें`
    },
    late: {
      en: `Late ${seasonName} - Prepare for harvest and post-harvest management`,
      hi: `अंतिम ${seasonName} - कटाई और कटाई के बाद प्रबंधन की तैयारी करें`
    }
  };
  return messages[phase] || messages.mid;
}

function getNextSeason(currentSeasonKey) {
  const order = ['KHARIF', 'RABI', 'ZAID'];
  const currentIdx = order.indexOf(currentSeasonKey);
  const nextIdx = (currentIdx + 1) % order.length;
  const nextKey = order[nextIdx];
  return { key: nextKey, ...SEASONS[nextKey] };
}

function getCropRecommendationsForLocation(lat, lon, stateCode, weatherData = null) {
  const calendar = getSeasonalCropCalendar(lat, lon, stateCode);
  const recommendations = [];
  
  const sowingCrops = calendar.crops.filter(c => c.status === 'sowing');
  
  for (const crop of sowingCrops) {
    const rec = {
      crop: crop.crop,
      action: 'sow',
      priority: 'high',
      water_requirement: crop.waterReq,
      timing: `${crop.sowingStart} - ${crop.sowingEnd}`,
      tips: []
    };
    
    if (weatherData) {
      if (weatherData.rain_chance > 60) {
        rec.tips.push('Upcoming rain - ideal for sowing');
        rec.tips.push('आने वाली बारिश - बुवाई के लिए आदर्श');
      }
      if (weatherData.temp > 35) {
        rec.tips.push('High temperature - sow in early morning or evening');
        rec.tips.push('उच्च तापमान - सुबह जल्दी या शाम को बुवाई करें');
      }
    }
    
    recommendations.push(rec);
  }
  
  return recommendations;
}

module.exports = {
  SEASONS,
  MONTHS,
  getCurrentSeason,
  getSeasonPhase,
  getCropCalendarByState,
  getSeasonalCropCalendar,
  getCropStatus,
  getCropRecommendationsForLocation,
  getNextSeason,
  STATE_CROP_CALENDARS,
  DEFAULT_CALENDAR
};
