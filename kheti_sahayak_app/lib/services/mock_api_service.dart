import 'dart:convert';
import 'dart:math';

class MockApiService {
  static final MockApiService _instance = MockApiService._internal();
  
  // Singleton pattern
  factory MockApiService() => _instance;
  
  MockApiService._internal();
  
  // Mock user data
  final Map<String, dynamic> _mockUser = {
    'id': '12345',
    'username': 'testuser',
    'email': 'test@example.com',
    'token': 'mock_jwt_token_1234567890',
  };
  
  // Mock authentication
  Future<Map<String, dynamic>> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    if (email == 'test@example.com' && password == 'test123') {
      return {
        'user': _mockUser,
        'token': _mockUser['token'],
      };
    } else {
      throw Exception('Invalid credentials');
    }
  }
  
  // Mock data for other API calls
  Future<Map<String, dynamic>> get(String endpoint, {Map<String, String>? queryParams}) async {
    await Future.delayed(const Duration(seconds: 1));
    
    if (endpoint.startsWith('crops')) {
      if (endpoint.endsWith('recommendations')) {
        final recommendations = await getCropRecommendations();
        return {'data': recommendations};
      }
      return {'crops': _mockCrops};
    } else if (endpoint.startsWith('diagnostics')) {
      return {'diagnostics': _mockDiagnostics};
    } else if (endpoint == 'weather') {
      return _weatherReport;
    }
    
    return {};
  }
  
  // Mock data for crops
  final List<Map<String, dynamic>> _mockCrops = [
    {
      'id': '1',
      'name': 'Rice',
      'variety': 'Basmati',
      'season': 'Kharif',
      'duration': '120-150 days',
      'price_per_kg': 25.50,
      'yield_per_hectare': '4-6 tons',
      'description': 'Premium quality basmati rice known for its aroma and long grains. Grown in flooded fields with proper water management.',
      'planting_date': '2023-06-01',
      'harvest_date': '2023-10-15',
      'status': 'Growing',
      'image_url': 'https://images.unsplash.com/photo-1540148426945-6cf22a6b2383?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2070&q=80',
      'gallery': [
        'https://images.unsplash.com/photo-1540148426945-6cf22a6b2383?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2070&q=80',
        'https://images.unsplash.com/photo-1595475207225-4288f6ae566b?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1470&q=80',
        'https://images.unsplash.com/photo-1500382246541-71b77d1a9e4c?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1470&q=80',
      ],
      'requirements': {
        'soil': 'Clayey loam with good water retention',
        'temperature': '20-35°C',
        'rainfall': '150-300 cm annually',
        'ph': '5.0-8.0'
      },
      'pests': ['Stem borer', 'Brown plant hopper', 'Leaf folder'],
      'diseases': ['Blast', 'Bacterial blight', 'Sheath blight'],
    },
    {
      'id': '2',
      'name': 'Wheat',
      'variety': 'Sharbati',
      'season': 'Rabi',
      'duration': '120-150 days',
      'price_per_kg': 18.75,
      'yield_per_hectare': '3-5 tons',
      'description': 'High-quality wheat variety ideal for making chapatis and bread. Requires well-drained soil and cool weather.',
      'planting_date': '2023-11-15',
      'harvest_date': '2024-03-30',
      'status': 'Planned',
      'image_url': 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1332&q=80',
      'gallery': [
        'https://images.unsplash.com/photo-1500382017468-9049fed747ef?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1332&q=80',
        'https://images.unsplash.com/photo 1500382017468-9049fed747ef?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1332&q=80',
      ],
      'requirements': {
        'soil': 'Well-drained loamy soil',
        'temperature': '17-23°C',
        'rainfall': '50-100 cm annually',
        'ph': '6.0-7.5'
      },
      'pests': ['Aphids', 'Termites', 'Armyworm'],
      'diseases': ['Rust', 'Karnal bunt', 'Powdery mildew'],
    },
    {
      'id': '3',
      'name': 'Cotton',
      'variety': 'BT Cotton',
      'season': 'Kharif',
      'duration': '150-180 days',
      'price_per_kg': 65.00,
      'yield_per_hectare': '10-12 quintals',
      'description': 'Genetically modified cotton resistant to bollworms. Requires warm climate and well-drained soil.',
      'planting_date': '2023-05-15',
      'harvest_date': '2023-10-30',
      'status': 'Growing',
      'image_url': 'https://images.unsplash.com/photo-1605000797499-95a51c5269ae?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1471&q=80',
      'gallery': [
        'https://images.unsplash.com/photo-1605000797499-95a51c5269ae?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1471&q=80',
        'https://images.unsplash.com/photo-1605000797499-95a51c5269ae?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1471&q=80',
      ],
      'requirements': {
        'soil': 'Black cotton soil',
        'temperature': '21-30°C',
        'rainfall': '50-100 cm annually',
        'ph': '6.0-8.0'
      },
      'pests': ['Bollworm', 'Aphids', 'Whitefly'],
      'diseases': ['Bacterial blight', 'Verticillium wilt', 'Fusarium wilt'],
    },
    {
      'id': '4',
      'name': 'Sugarcane',
      'variety': 'Co-0238',
      'season': 'Year-round',
      'duration': '12-18 months',
      'price_per_kg': 3.20,
      'yield_per_hectare': '70-80 tons',
      'description': 'High-yielding sugarcane variety with good sugar recovery rate. Requires abundant water and sunshine.',
      'planting_date': '2023-02-10',
      'harvest_date': '2024-02-28',
      'status': 'Growing',
      'image_url': 'https://images.unsplash.com/photo-1587049352846-4a222e784d38?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1528&q=80',
      'gallery': [
        'https://images.unsplash.com/photo-1587049352846-4a222e784d38?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1528&q=80',
        'https://images.unsplash.com/photo-1587049352846-4a222e784d38?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1528&q=80',
      ],
      'requirements': {
        'soil': 'Deep, well-drained loamy soil',
        'temperature': '20-30°C',
        'rainfall': '150-200 cm annually',
        'ph': '6.5-7.5'
      },
      'pests': ['Termites', 'Early shoot borer', 'Scale insects'],
      'diseases': ['Red rot', 'Smut', 'Rust'],
    },
  ];
  
  // Mock data for weather reports
  final Map<String, dynamic> _weatherReport = {
    'current': {
      'temperature': 28.5,
      'condition': 'Partly Cloudy',
      'humidity': 65,
      'wind_speed': 12.5,
      'precipitation': 0.0,
      'icon': 'partly_cloudy',
      'last_updated': DateTime.now().toIso8601String(),
    },
    'forecast': [
      {
        'date': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        'max_temp': 30.0,
        'min_temp': 22.0,
        'condition': 'Sunny',
        'precipitation_chance': 10,
      },
      {
        'date': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
        'max_temp': 29.0,
        'min_temp': 23.0,
        'condition': 'Partly Cloudy',
        'precipitation_chance': 20,
      },
      {
        'date': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
        'max_temp': 27.0,
        'min_temp': 21.0,
        'condition': 'Rain Showers',
        'precipitation_chance': 70,
      },
      {
        'date': DateTime.now().add(const Duration(days: 4)).toIso8601String(),
        'max_temp': 26.0,
        'min_temp': 20.0,
        'condition': 'Rain',
        'precipitation_chance': 90,
      },
      {
        'date': DateTime.now().add(const Duration(days: 5)).toIso8601String(),
        'max_temp': 28.0,
        'min_temp': 21.0,
        'condition': 'Cloudy',
        'precipitation_chance': 40,
      },
    ],
    'alerts': [
      {
        'title': 'Heavy Rain Alert',
        'description': 'Heavy rainfall expected in the next 48 hours. Take necessary precautions for your crops.',
        'severity': 'warning',
        'start_time': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
        'end_time': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
      }
    ]
  };

  // Mock data for diagnostics
  final List<Map<String, dynamic>> _mockDiagnostics = [
    {
      'id': '1',
      'crop': 'Rice',
      'issue': 'Yellowing leaves',
      'description': 'Older leaves are turning yellow from the tip, spreading to the entire leaf.',
      'solution': 'Apply nitrogen-rich fertilizer (Urea) at 50kg per acre. Check soil pH and adjust if necessary.',
      'date': '2023-06-15',
      'status': 'Resolved',
      'severity': 'medium',
      'recommended_products': ['Urea', 'NPK 20:20:20', 'Micronutrient Mix']
    },
    {
      'id': '2',
      'crop': 'Wheat',
      'issue': 'Powdery Mildew',
      'description': 'White powdery spots on leaves and stems, especially in humid conditions.',
      'solution': 'Apply fungicide containing sulfur or potassium bicarbonate. Ensure proper spacing between plants for air circulation.',
      'date': '2023-02-20',
      'status': 'In Progress',
      'severity': 'high',
      'recommended_products': ['Sulfur Dust', 'Neem Oil', 'Baking Soda Spray']
    },
  ];
  
  // Get weather data
  Future<Map<String, dynamic>> getWeather() async {
    await Future.delayed(const Duration(seconds: 1));
    return _weatherReport;
  }

  // Get crop recommendations based on weather
  Future<List<Map<String, dynamic>>> getCropRecommendations() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      {
        'crop': 'Rice',
        'recommendation': 'Good time for transplanting seedlings. Ensure proper water management.',
        'priority': 'high',
        'action_items': ['Prepare nursery beds', 'Apply basal dose of fertilizers']
      },
      {
        'crop': 'Wheat',
        'recommendation': 'Monitor for pest attacks. Consider preventive spraying.',
        'priority': 'medium',
        'action_items': ['Inspect fields', 'Prepare for sowing season']
      },
      {
        'crop': 'Vegetables',
        'recommendation': 'Ideal conditions for growing leafy vegetables. Ensure proper irrigation.',
        'priority': 'low',
        'action_items': ['Sow seeds', 'Apply organic manure']
      }
    ];
  }

  // Add more mock methods as needed
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    await Future.delayed(const Duration(seconds: 1));
    
    if (endpoint.contains('auth/register')) {
      return {
        'user': {
          'id': 'mock_${DateTime.now().millisecondsSinceEpoch}',
          'username': data['username'],
          'email': data['email'],
          'full_name': data['full_name'],
          'phone_number': data['phone_number'],
        },
        'token': 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}',
      };
    }
    
    return {'message': 'Operation successful'};
  }
}
