/**
 * Migration: Create Weather Alerts Tables
 * 
 * Creates tables for:
 * - weather_alert_preferences: User alert preferences
 * - weather_alert_subscriptions: User location subscriptions with persistent storage
 * - weather_alert_history: History of triggered alerts
 * - weather_alert_rules: Configurable alert rules (admin managed)
 */

exports.up = (pgm) => {
  // Create ENUM for alert types
  pgm.sql(`
    DO $$ BEGIN
      CREATE TYPE weather_alert_type AS ENUM (
        'heat_wave', 
        'heavy_rain', 
        'frost', 
        'storm', 
        'drought',
        'hail',
        'fog',
        'cold_wave',
        'flood_warning'
      );
    EXCEPTION
      WHEN duplicate_object THEN null;
    END $$;
  `);

  // Create ENUM for alert severity
  pgm.sql(`
    DO $$ BEGIN
      CREATE TYPE alert_severity AS ENUM ('low', 'moderate', 'high', 'severe', 'extreme');
    EXCEPTION
      WHEN duplicate_object THEN null;
    END $$;
  `);

  // Create ENUM for notification channels
  pgm.sql(`
    DO $$ BEGIN
      CREATE TYPE notification_channel AS ENUM ('push', 'sms', 'email', 'in_app');
    EXCEPTION
      WHEN duplicate_object THEN null;
    END $$;
  `);

  // Create weather_alert_rules table (admin configurable rules)
  pgm.createTable('weather_alert_rules', {
    id: {
      type: 'uuid',
      primaryKey: true,
      default: pgm.func('uuid_generate_v4()')
    },
    alert_type: {
      type: 'weather_alert_type',
      notNull: true
    },
    name: {
      type: 'varchar(100)',
      notNull: true
    },
    name_hi: {
      type: 'varchar(100)'
    },
    description: {
      type: 'text'
    },
    description_hi: {
      type: 'text'
    },
    // Condition thresholds stored as JSONB for flexibility
    // e.g., {"temp_min": 40, "temp_max": null, "humidity_min": null, "wind_speed_min": null}
    conditions: {
      type: 'jsonb',
      notNull: true
    },
    // Severity mapping based on condition values
    // e.g., {"moderate": {"temp_min": 40}, "high": {"temp_min": 42}, "severe": {"temp_min": 45}}
    severity_thresholds: {
      type: 'jsonb',
      notNull: true
    },
    // Default recommendations for this alert type
    recommendations: {
      type: 'jsonb',
      default: "'[]'::jsonb"
    },
    recommendations_hi: {
      type: 'jsonb',
      default: "'[]'::jsonb"
    },
    is_active: {
      type: 'boolean',
      notNull: true,
      default: true
    },
    // Priority for sorting alerts
    priority: {
      type: 'integer',
      notNull: true,
      default: 5
    },
    // Whether this alert should trigger SMS for severe cases
    sms_enabled: {
      type: 'boolean',
      notNull: true,
      default: true
    },
    created_at: {
      type: 'timestamp with time zone',
      notNull: true,
      default: pgm.func('CURRENT_TIMESTAMP')
    },
    updated_at: {
      type: 'timestamp with time zone',
      notNull: true,
      default: pgm.func('CURRENT_TIMESTAMP')
    }
  });

  // Create weather_alert_preferences table
  pgm.createTable('weather_alert_preferences', {
    id: {
      type: 'uuid',
      primaryKey: true,
      default: pgm.func('uuid_generate_v4()')
    },
    user_id: {
      type: 'uuid',
      notNull: true,
      references: '"users"',
      onDelete: 'CASCADE'
    },
    // Which alert types user wants to receive
    enabled_alerts: {
      type: 'jsonb',
      notNull: true,
      default: "'[\"heat_wave\", \"heavy_rain\", \"frost\", \"storm\", \"drought\"]'::jsonb"
    },
    // Notification channels user prefers
    notification_channels: {
      type: 'jsonb',
      notNull: true,
      default: "'[\"push\", \"in_app\"]'::jsonb"
    },
    // Minimum severity level to receive notifications
    min_severity: {
      type: 'alert_severity',
      notNull: true,
      default: "'moderate'"
    },
    // Quiet hours (don't send non-critical notifications)
    quiet_hours_start: {
      type: 'time'
    },
    quiet_hours_end: {
      type: 'time'
    },
    // SMS preferences
    sms_enabled: {
      type: 'boolean',
      notNull: true,
      default: false
    },
    // Only send SMS for high/severe alerts
    sms_critical_only: {
      type: 'boolean',
      notNull: true,
      default: true
    },
    // User's phone for SMS (can be different from account phone)
    sms_phone: {
      type: 'varchar(20)'
    },
    // Language preference for alerts
    language: {
      type: 'varchar(10)',
      notNull: true,
      default: "'en'"
    },
    // Max alerts per day (0 = unlimited)
    daily_limit: {
      type: 'integer',
      notNull: true,
      default: 10
    },
    is_active: {
      type: 'boolean',
      notNull: true,
      default: true
    },
    created_at: {
      type: 'timestamp with time zone',
      notNull: true,
      default: pgm.func('CURRENT_TIMESTAMP')
    },
    updated_at: {
      type: 'timestamp with time zone',
      notNull: true,
      default: pgm.func('CURRENT_TIMESTAMP')
    }
  });

  // Create unique constraint - one preference record per user
  pgm.createIndex('weather_alert_preferences', ['user_id'], { unique: true });

  // Create weather_alert_subscriptions table (location subscriptions)
  pgm.createTable('weather_alert_subscriptions', {
    id: {
      type: 'uuid',
      primaryKey: true,
      default: pgm.func('uuid_generate_v4()')
    },
    user_id: {
      type: 'uuid',
      notNull: true,
      references: '"users"',
      onDelete: 'CASCADE'
    },
    // Location details
    latitude: {
      type: 'decimal(10, 7)',
      notNull: true
    },
    longitude: {
      type: 'decimal(10, 7)',
      notNull: true
    },
    location_name: {
      type: 'varchar(200)'
    },
    // Override alert types for this location (null = use user preferences)
    alert_types: {
      type: 'jsonb'
    },
    // Is this the primary/home location?
    is_primary: {
      type: 'boolean',
      notNull: true,
      default: false
    },
    is_active: {
      type: 'boolean',
      notNull: true,
      default: true
    },
    // Last time alerts were checked for this location
    last_checked_at: {
      type: 'timestamp with time zone'
    },
    created_at: {
      type: 'timestamp with time zone',
      notNull: true,
      default: pgm.func('CURRENT_TIMESTAMP')
    },
    updated_at: {
      type: 'timestamp with time zone',
      notNull: true,
      default: pgm.func('CURRENT_TIMESTAMP')
    }
  });

  // Create indexes for subscriptions
  pgm.createIndex('weather_alert_subscriptions', ['user_id', 'is_active']);
  pgm.createIndex('weather_alert_subscriptions', ['latitude', 'longitude']);
  pgm.createIndex('weather_alert_subscriptions', ['user_id', 'latitude', 'longitude'], { 
    unique: true,
    name: 'unique_user_location_subscription'
  });

  // Create weather_alert_history table
  pgm.createTable('weather_alert_history', {
    id: {
      type: 'uuid',
      primaryKey: true,
      default: pgm.func('uuid_generate_v4()')
    },
    user_id: {
      type: 'uuid',
      notNull: true,
      references: '"users"',
      onDelete: 'CASCADE'
    },
    subscription_id: {
      type: 'uuid',
      references: '"weather_alert_subscriptions"',
      onDelete: 'SET NULL'
    },
    alert_type: {
      type: 'weather_alert_type',
      notNull: true
    },
    severity: {
      type: 'alert_severity',
      notNull: true
    },
    title: {
      type: 'varchar(200)',
      notNull: true
    },
    message: {
      type: 'text',
      notNull: true
    },
    // Weather conditions that triggered the alert
    weather_data: {
      type: 'jsonb'
    },
    // Location where alert was triggered
    latitude: {
      type: 'decimal(10, 7)',
      notNull: true
    },
    longitude: {
      type: 'decimal(10, 7)',
      notNull: true
    },
    location_name: {
      type: 'varchar(200)'
    },
    // Notification delivery status
    push_sent: {
      type: 'boolean',
      notNull: true,
      default: false
    },
    push_sent_at: {
      type: 'timestamp with time zone'
    },
    sms_sent: {
      type: 'boolean',
      notNull: true,
      default: false
    },
    sms_sent_at: {
      type: 'timestamp with time zone'
    },
    email_sent: {
      type: 'boolean',
      notNull: true,
      default: false
    },
    email_sent_at: {
      type: 'timestamp with time zone'
    },
    // User interaction
    is_read: {
      type: 'boolean',
      notNull: true,
      default: false
    },
    read_at: {
      type: 'timestamp with time zone'
    },
    is_dismissed: {
      type: 'boolean',
      notNull: true,
      default: false
    },
    // Alert validity period
    valid_from: {
      type: 'timestamp with time zone',
      notNull: true,
      default: pgm.func('CURRENT_TIMESTAMP')
    },
    valid_until: {
      type: 'timestamp with time zone'
    },
    created_at: {
      type: 'timestamp with time zone',
      notNull: true,
      default: pgm.func('CURRENT_TIMESTAMP')
    }
  });

  // Create indexes for alert history
  pgm.createIndex('weather_alert_history', ['user_id', 'created_at']);
  pgm.createIndex('weather_alert_history', ['user_id', 'is_read']);
  pgm.createIndex('weather_alert_history', ['user_id', 'alert_type']);
  pgm.createIndex('weather_alert_history', ['valid_until'], { 
    where: 'valid_until IS NOT NULL'
  });

  // Add triggers for updated_at
  pgm.sql(`
    CREATE TRIGGER update_weather_alert_rules_updated_at
    BEFORE UPDATE ON weather_alert_rules
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
  `);

  pgm.sql(`
    CREATE TRIGGER update_weather_alert_preferences_updated_at
    BEFORE UPDATE ON weather_alert_preferences
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
  `);

  pgm.sql(`
    CREATE TRIGGER update_weather_alert_subscriptions_updated_at
    BEFORE UPDATE ON weather_alert_subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
  `);

  // Insert default alert rules
  pgm.sql(`
    INSERT INTO weather_alert_rules (alert_type, name, name_hi, description, description_hi, conditions, severity_thresholds, recommendations, recommendations_hi, priority, sms_enabled) VALUES
    ('heat_wave', 'Heat Wave Alert', 'लू की चेतावनी', 'Extreme heat conditions that may affect crops and farm workers', 'अत्यधिक गर्मी की स्थिति जो फसलों और खेत मजदूरों को प्रभावित कर सकती है', 
     '{"temp_min": 40}', 
     '{"moderate": {"temp_min": 40}, "high": {"temp_min": 42}, "severe": {"temp_min": 45}, "extreme": {"temp_min": 47}}',
     '["Irrigate crops early morning or late evening", "Provide shade to livestock", "Avoid pesticide application during peak heat", "Ensure adequate hydration for workers", "Consider mulching to retain soil moisture"]',
     '["सुबह जल्दी या शाम को देर से फसलों की सिंचाई करें", "पशुओं को छाया प्रदान करें", "चरम गर्मी के दौरान कीटनाशक छिड़काव से बचें", "श्रमिकों के लिए पर्याप्त जलयोजन सुनिश्चित करें", "मिट्टी की नमी बनाए रखने के लिए मल्चिंग पर विचार करें"]',
     1, true),
    
    ('frost', 'Frost Warning', 'पाला चेतावनी', 'Low temperature conditions that may damage sensitive crops', 'कम तापमान की स्थिति जो संवेदनशील फसलों को नुकसान पहुंचा सकती है',
     '{"temp_max": 4}',
     '{"moderate": {"temp_max": 4}, "high": {"temp_max": 2}, "severe": {"temp_max": 0}, "extreme": {"temp_max": -3}}',
     '["Cover tender crops with plastic sheets or straw", "Light irrigation can help protect from frost", "Avoid harvesting frozen produce", "Delay morning field work until frost melts", "Use smoke or fog for orchard protection"]',
     '["कोमल फसलों को प्लास्टिक शीट या पुआल से ढकें", "हल्की सिंचाई पाले से बचाने में मदद कर सकती है", "जमे हुए उत्पादों की कटाई से बचें", "पाला पिघलने तक सुबह के खेत के काम में देरी करें", "बाग संरक्षण के लिए धुआं या कोहरे का उपयोग करें"]',
     2, true),
    
    ('heavy_rain', 'Heavy Rain Warning', 'भारी बारिश चेतावनी', 'Heavy rainfall that may cause waterlogging and crop damage', 'भारी बारिश जो जलभराव और फसल क्षति का कारण बन सकती है',
     '{"precipitation_min": 50}',
     '{"moderate": {"precipitation_min": 50}, "high": {"precipitation_min": 75}, "severe": {"precipitation_min": 100}, "extreme": {"precipitation_min": 150}}',
     '["Clear drainage channels immediately", "Harvest ready crops before rain if possible", "Postpone irrigation and fertilizer application", "Protect stored grains from moisture", "Check and repair field bunds"]',
     '["तुरंत जल निकासी चैनल साफ करें", "यदि संभव हो तो बारिश से पहले तैयार फसलों की कटाई करें", "सिंचाई और उर्वरक आवेदन स्थगित करें", "संग्रहीत अनाज को नमी से बचाएं", "खेत की मेड़ों की जांच और मरम्मत करें"]',
     3, true),
    
    ('storm', 'Storm Warning', 'तूफान चेतावनी', 'High wind speeds that may damage crops and structures', 'तेज हवा की गति जो फसलों और संरचनाओं को नुकसान पहुंचा सकती है',
     '{"wind_speed_min": 50}',
     '{"moderate": {"wind_speed_min": 50}, "high": {"wind_speed_min": 65}, "severe": {"wind_speed_min": 80}, "extreme": {"wind_speed_min": 100}}',
     '["Secure greenhouse covers and temporary structures", "Stake tall crops to prevent lodging", "Postpone all spraying operations", "Keep livestock in sheltered areas", "Remove loose materials from fields"]',
     '["ग्रीनहाउस कवर और अस्थायी संरचनाओं को सुरक्षित करें", "लंबी फसलों को गिरने से रोकने के लिए सहारा दें", "सभी छिड़काव कार्यों को स्थगित करें", "पशुओं को आश्रय वाले क्षेत्रों में रखें", "खेतों से ढीली सामग्री हटाएं"]',
     4, true),
    
    ('drought', 'Drought Advisory', 'सूखा सलाह', 'Extended period without rainfall affecting water availability', 'वर्षा के बिना लंबी अवधि जो जल उपलब्धता को प्रभावित करती है',
     '{"days_without_rain": 14}',
     '{"moderate": {"days_without_rain": 14}, "high": {"days_without_rain": 21}, "severe": {"days_without_rain": 30}, "extreme": {"days_without_rain": 45}}',
     '["Implement water-saving irrigation techniques", "Use mulching to reduce evaporation", "Consider drought-resistant crop varieties", "Prioritize water for critical crop stages", "Explore alternative water sources"]',
     '["जल-बचत सिंचाई तकनीकों को लागू करें", "वाष्पीकरण को कम करने के लिए मल्चिंग का उपयोग करें", "सूखा प्रतिरोधी फसल किस्मों पर विचार करें", "महत्वपूर्ण फसल चरणों के लिए पानी को प्राथमिकता दें", "वैकल्पिक जल स्रोतों का पता लगाएं"]',
     5, false),
    
    ('hail', 'Hail Warning', 'ओला चेतावनी', 'Hailstorm conditions that may cause severe crop damage', 'ओलावृष्टि की स्थिति जो गंभीर फसल क्षति का कारण बन सकती है',
     '{"hail_probability_min": 60}',
     '{"moderate": {"hail_probability_min": 60}, "high": {"hail_probability_min": 75}, "severe": {"hail_probability_min": 85}}',
     '["Cover vulnerable crops with protective nets", "Harvest ready produce immediately", "Move livestock to covered areas", "Document damage for insurance claims", "Inspect crops after hail for disease entry points"]',
     '["कमजोर फसलों को सुरक्षात्मक जाल से ढकें", "तैयार उपज की तुरंत कटाई करें", "पशुओं को ढके हुए क्षेत्रों में ले जाएं", "बीमा दावों के लिए क्षति का दस्तावेजीकरण करें", "रोग प्रवेश बिंदुओं के लिए ओलावृष्टि के बाद फसलों का निरीक्षण करें"]',
     6, true),
    
    ('fog', 'Dense Fog Advisory', 'घना कोहरा सलाह', 'Dense fog conditions affecting visibility and crop health', 'घने कोहरे की स्थिति जो दृश्यता और फसल स्वास्थ्य को प्रभावित करती है',
     '{"visibility_max": 200}',
     '{"moderate": {"visibility_max": 200}, "high": {"visibility_max": 100}, "severe": {"visibility_max": 50}}',
     '["Monitor for fungal disease development", "Delay spraying until fog clears", "Be cautious with field machinery", "Check crops for moisture-related issues", "Avoid travel during peak fog hours"]',
     '["फंगल रोग विकास की निगरानी करें", "कोहरा छंटने तक छिड़काव में देरी करें", "खेत मशीनरी के साथ सावधान रहें", "नमी संबंधी समस्याओं के लिए फसलों की जांच करें", "चरम कोहरे के घंटों के दौरान यात्रा से बचें"]',
     7, false),
    
    ('cold_wave', 'Cold Wave Alert', 'शीत लहर चेतावनी', 'Sustained cold temperatures affecting crops and livestock', 'लगातार ठंडा तापमान जो फसलों और पशुओं को प्रभावित करता है',
     '{"temp_max": 10, "temp_deviation": -5}',
     '{"moderate": {"temp_max": 10}, "high": {"temp_max": 5}, "severe": {"temp_max": 2}}',
     '["Provide extra bedding for livestock", "Cover sensitive plants", "Postpone planting of warm-season crops", "Check irrigation systems for freezing", "Ensure livestock have access to unfrozen water"]',
     '["पशुओं के लिए अतिरिक्त बिस्तर प्रदान करें", "संवेदनशील पौधों को ढकें", "गर्म मौसम की फसलों की रोपाई स्थगित करें", "जमने के लिए सिंचाई प्रणालियों की जांच करें", "सुनिश्चित करें कि पशुओं की पहुंच बिना जमे पानी तक हो"]',
     8, true),
    
    ('flood_warning', 'Flood Warning', 'बाढ़ चेतावनी', 'Risk of flooding due to heavy rainfall or river overflow', 'भारी वर्षा या नदी के उफान के कारण बाढ़ का खतरा',
     '{"flood_risk_level": 3}',
     '{"moderate": {"flood_risk_level": 3}, "high": {"flood_risk_level": 4}, "severe": {"flood_risk_level": 5}, "extreme": {"flood_risk_level": 6}}',
     '["Move livestock to higher ground", "Secure farm equipment and chemicals", "Harvest standing crops if possible", "Prepare emergency supplies", "Stay informed via official channels", "Do not attempt to cross flooded areas"]',
     '["पशुओं को ऊंचे स्थान पर ले जाएं", "कृषि उपकरण और रसायनों को सुरक्षित करें", "यदि संभव हो तो खड़ी फसलों की कटाई करें", "आपातकालीन आपूर्ति तैयार करें", "आधिकारिक चैनलों के माध्यम से सूचित रहें", "बाढ़ वाले क्षेत्रों को पार करने का प्रयास न करें"]',
     9, true);
  `);
};

exports.down = (pgm) => {
  pgm.dropTable('weather_alert_history');
  pgm.dropTable('weather_alert_subscriptions');
  pgm.dropTable('weather_alert_preferences');
  pgm.dropTable('weather_alert_rules');
  
  pgm.sql(`
    DROP TYPE IF EXISTS notification_channel;
    DROP TYPE IF EXISTS alert_severity;
    DROP TYPE IF EXISTS weather_alert_type;
  `);
};
