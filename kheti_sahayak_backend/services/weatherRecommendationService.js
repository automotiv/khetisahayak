/**
 * Weather-Based Activity Recommendations Service
 *
 * Provides farming activity recommendations based on weather conditions (Story #372)
 */

/**
 * Activity types and their weather requirements
 */
const activityRequirements = {
  planting: {
    name: 'Planting',
    name_hi: 'बुवाई',
    icon: 'seedling',
    ideal: {
      temp_min: 15,
      temp_max: 30,
      humidity_min: 40,
      humidity_max: 70,
      wind_max: 15,
      rain_max: 5,
    },
    warnings: {
      too_hot: 'High temperatures may stress young seedlings',
      too_cold: 'Cold temperatures slow germination',
      too_humid: 'High humidity increases disease risk',
      too_windy: 'Wind may damage tender seedlings',
      rain_expected: 'Wait for soil to dry slightly after rain',
    },
  },
  irrigation: {
    name: 'Irrigation',
    name_hi: 'सिंचाई',
    icon: 'water',
    ideal: {
      temp_min: 10,
      temp_max: 35,
      humidity_max: 80,
      wind_max: 20,
      rain_max: 2,
    },
    warnings: {
      rain_expected: 'Skip irrigation if rain is expected',
      too_humid: 'Reduce irrigation frequency in humid conditions',
      too_hot: 'Irrigate early morning or late evening to reduce evaporation',
    },
  },
  spraying: {
    name: 'Pesticide/Fertilizer Spraying',
    name_hi: 'कीटनाशक/उर्वरक छिड़काव',
    icon: 'spray',
    ideal: {
      temp_min: 15,
      temp_max: 30,
      humidity_min: 40,
      humidity_max: 70,
      wind_max: 10,
      rain_max: 0,
    },
    warnings: {
      too_windy: 'Wind will cause spray drift - postpone application',
      rain_expected: 'Rain will wash off chemicals - wait for dry spell',
      too_hot: 'High heat causes rapid evaporation - spray early morning',
      too_humid: 'Poor spray coverage in high humidity',
    },
  },
  harvesting: {
    name: 'Harvesting',
    name_hi: 'कटाई',
    icon: 'harvest',
    ideal: {
      temp_min: 15,
      temp_max: 35,
      humidity_max: 70,
      rain_max: 0,
    },
    warnings: {
      rain_expected: 'Harvest before rain to prevent crop damage',
      too_humid: 'High humidity may affect grain quality',
    },
  },
  tillage: {
    name: 'Tillage/Land Preparation',
    name_hi: 'जुताई/भूमि तैयारी',
    icon: 'tractor',
    ideal: {
      temp_min: 10,
      temp_max: 35,
      humidity_min: 30,
      humidity_max: 60,
      rain_max: 0,
    },
    warnings: {
      too_wet: 'Soil too wet - tillage will cause compaction',
      rain_expected: 'Wait for dry conditions after rain',
    },
  },
  weeding: {
    name: 'Weeding',
    name_hi: 'निराई',
    icon: 'weeding',
    ideal: {
      temp_min: 15,
      temp_max: 32,
      humidity_min: 30,
      humidity_max: 70,
      rain_max: 5,
    },
    warnings: {
      too_hot: 'Weed in early morning or evening to avoid heat stress',
    },
  },
  pruning: {
    name: 'Pruning',
    name_hi: 'छंटाई',
    icon: 'pruning',
    ideal: {
      temp_min: 10,
      temp_max: 28,
      humidity_max: 70,
      rain_max: 0,
    },
    warnings: {
      too_humid: 'High humidity increases disease infection risk at cut sites',
      rain_expected: 'Rain may spread pathogens to fresh cuts',
    },
  },
  mulching: {
    name: 'Mulching',
    name_hi: 'मल्चिंग',
    icon: 'mulch',
    ideal: {
      temp_min: 10,
      temp_max: 35,
      wind_max: 15,
      rain_max: 5,
    },
    warnings: {
      too_windy: 'Wind will blow light mulch away',
    },
  },
};

/**
 * Weather severity levels
 */
const SeverityLevel = {
  IDEAL: 'ideal',
  CAUTION: 'caution',
  AVOID: 'avoid',
};

/**
 * Get activity recommendations based on current weather
 */
function getActivityRecommendations(weatherData) {
  const { temperature, humidity, wind_speed, rain_chance = 0, rain_amount = 0 } = weatherData;

  const recommendations = [];

  for (const [activityKey, activity] of Object.entries(activityRequirements)) {
    const recommendation = evaluateActivity(activityKey, activity, {
      temperature,
      humidity,
      wind_speed,
      rain_chance,
      rain_amount,
    });

    recommendations.push(recommendation);
  }

  // Sort by suitability (ideal first, then caution, then avoid)
  const severityOrder = { [SeverityLevel.IDEAL]: 0, [SeverityLevel.CAUTION]: 1, [SeverityLevel.AVOID]: 2 };
  recommendations.sort((a, b) => severityOrder[a.severity] - severityOrder[b.severity]);

  return recommendations;
}

/**
 * Evaluate a specific activity against weather conditions
 */
function evaluateActivity(key, activity, weather) {
  const { ideal, warnings } = activity;
  const { temperature, humidity, wind_speed, rain_chance, rain_amount } = weather;

  const issues = [];
  let severity = SeverityLevel.IDEAL;

  // Check temperature
  if (ideal.temp_min !== undefined && temperature < ideal.temp_min) {
    issues.push(warnings.too_cold || `Temperature too low (${temperature}°C)`);
    severity = temperature < ideal.temp_min - 5 ? SeverityLevel.AVOID : SeverityLevel.CAUTION;
  }
  if (ideal.temp_max !== undefined && temperature > ideal.temp_max) {
    issues.push(warnings.too_hot || `Temperature too high (${temperature}°C)`);
    severity = temperature > ideal.temp_max + 5 ? SeverityLevel.AVOID : SeverityLevel.CAUTION;
  }

  // Check humidity
  if (ideal.humidity_min !== undefined && humidity < ideal.humidity_min) {
    issues.push(warnings.too_dry || `Humidity too low (${humidity}%)`);
    severity = Math.max(severity === SeverityLevel.AVOID ? 2 : 1, 1) === 2 ? SeverityLevel.AVOID : SeverityLevel.CAUTION;
  }
  if (ideal.humidity_max !== undefined && humidity > ideal.humidity_max) {
    issues.push(warnings.too_humid || `Humidity too high (${humidity}%)`);
    if (severity !== SeverityLevel.AVOID) severity = SeverityLevel.CAUTION;
  }

  // Check wind
  if (ideal.wind_max !== undefined && wind_speed > ideal.wind_max) {
    issues.push(warnings.too_windy || `Wind too strong (${wind_speed} km/h)`);
    severity = wind_speed > ideal.wind_max * 1.5 ? SeverityLevel.AVOID : SeverityLevel.CAUTION;
  }

  // Check rain
  if ((ideal.rain_max !== undefined && rain_amount > ideal.rain_max) || rain_chance > 60) {
    issues.push(warnings.rain_expected || 'Rain expected - consider postponing');
    if (rain_chance > 80 || rain_amount > 10) {
      severity = SeverityLevel.AVOID;
    } else if (severity !== SeverityLevel.AVOID) {
      severity = SeverityLevel.CAUTION;
    }
  }

  // Generate recommendation message
  let message;
  if (severity === SeverityLevel.IDEAL) {
    message = `Good conditions for ${activity.name.toLowerCase()}`;
  } else if (severity === SeverityLevel.CAUTION) {
    message = `${activity.name} possible with caution`;
  } else {
    message = `Not recommended for ${activity.name.toLowerCase()}`;
  }

  return {
    activity: key,
    name: activity.name,
    name_hi: activity.name_hi,
    icon: activity.icon,
    severity,
    suitability_score: severity === SeverityLevel.IDEAL ? 100 : severity === SeverityLevel.CAUTION ? 60 : 20,
    message,
    issues,
    ideal_conditions: {
      temperature: ideal.temp_min && ideal.temp_max ? `${ideal.temp_min}-${ideal.temp_max}°C` : 'Any',
      humidity: ideal.humidity_min && ideal.humidity_max ? `${ideal.humidity_min}-${ideal.humidity_max}%` : ideal.humidity_max ? `<${ideal.humidity_max}%` : 'Any',
      wind: ideal.wind_max ? `<${ideal.wind_max} km/h` : 'Any',
      rain: ideal.rain_max !== undefined ? (ideal.rain_max === 0 ? 'No rain' : `<${ideal.rain_max}mm`) : 'Any',
    },
  };
}

/**
 * Get daily farming tips based on weather forecast
 */
function getDailyTips(forecastData) {
  const tips = [];
  const today = forecastData[0];

  if (!today) return tips;

  const { temperature, humidity, rain_chance = 0, weather_condition } = today;

  // Temperature tips
  if (temperature > 35) {
    tips.push({
      priority: 'high',
      category: 'heat',
      tip: 'Extreme heat expected. Irrigate crops early morning and provide shade to sensitive plants.',
      tip_hi: 'अत्यधिक गर्मी की संभावना। सुबह जल्दी सिंचाई करें और संवेदनशील पौधों को छाया प्रदान करें।',
    });
  } else if (temperature < 10) {
    tips.push({
      priority: 'high',
      category: 'cold',
      tip: 'Cold conditions expected. Protect tender crops with mulch or row covers.',
      tip_hi: 'ठंड की स्थिति अपेक्षित है। मल्च या रो कवर से कोमल फसलों की रक्षा करें।',
    });
  }

  // Rain tips
  if (rain_chance > 70) {
    tips.push({
      priority: 'high',
      category: 'rain',
      tip: 'Rain likely today. Harvest mature crops, ensure drainage, and postpone spraying.',
      tip_hi: 'आज बारिश की संभावना है। पकी फसलें काटें, जल निकासी सुनिश्चित करें, और छिड़काव स्थगित करें।',
    });
  } else if (rain_chance > 40) {
    tips.push({
      priority: 'medium',
      category: 'rain',
      tip: 'Some chance of rain. Complete outdoor work in the morning.',
      tip_hi: 'बारिश की कुछ संभावना है। सुबह में बाहरी काम पूरा करें।',
    });
  }

  // Humidity tips
  if (humidity > 80) {
    tips.push({
      priority: 'medium',
      category: 'disease',
      tip: 'High humidity increases disease risk. Monitor crops for fungal infections.',
      tip_hi: 'उच्च आर्द्रता से रोग का खतरा बढ़ता है। फंगल संक्रमण के लिए फसलों की निगरानी करें।',
    });
  }

  // General seasonal tips
  tips.push({
    priority: 'low',
    category: 'general',
    tip: 'Check soil moisture before irrigation. Avoid overwatering.',
    tip_hi: 'सिंचाई से पहले मिट्टी की नमी जांचें। अत्यधिक पानी देने से बचें।',
  });

  return tips.slice(0, 5); // Return max 5 tips
}

/**
 * Get optimal time windows for activities
 */
function getOptimalTimeWindows(hourlyForecast) {
  const windows = {
    spraying: [],
    irrigation: [],
    harvesting: [],
  };

  if (!hourlyForecast || hourlyForecast.length === 0) {
    return windows;
  }

  for (let i = 0; i < hourlyForecast.length; i++) {
    const hour = hourlyForecast[i];
    const { time, temperature, humidity, wind_speed, rain_chance } = hour;

    // Spraying windows (low wind, no rain, moderate temp)
    if (wind_speed < 10 && rain_chance < 20 && temperature >= 15 && temperature <= 30) {
      windows.spraying.push({ time, score: 100 - wind_speed * 2 - rain_chance });
    }

    // Irrigation windows (early morning or evening, no rain expected)
    const hourOfDay = parseInt(time.split(':')[0]);
    if ((hourOfDay < 9 || hourOfDay > 17) && rain_chance < 30) {
      windows.irrigation.push({ time, score: 100 - rain_chance });
    }

    // Harvesting windows (dry, moderate conditions)
    if (humidity < 70 && rain_chance < 20) {
      windows.harvesting.push({ time, score: 100 - humidity - rain_chance });
    }
  }

  // Sort by score and take top 3 windows
  for (const activity in windows) {
    windows[activity] = windows[activity]
      .sort((a, b) => b.score - a.score)
      .slice(0, 3)
      .map(w => w.time);
  }

  return windows;
}

module.exports = {
  getActivityRecommendations,
  getDailyTips,
  getOptimalTimeWindows,
  activityRequirements,
  SeverityLevel,
};
