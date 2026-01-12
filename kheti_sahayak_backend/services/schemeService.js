const db = require('../db');
const pushNotificationService = require('./pushNotificationService');

const SCHEME_CATEGORIES = {
    SUBSIDY: 'subsidy',
    LOAN: 'loan',
    INSURANCE: 'insurance',
    TRAINING: 'training',
    INFRASTRUCTURE: 'infrastructure',
    MARKET_SUPPORT: 'market_support'
};

const SCHEME_TYPES = {
    CENTRAL: 'Central',
    STATE: 'State',
    JOINT: 'Central-State'
};

const FARMER_CATEGORIES = {
    MARGINAL: { name: 'marginal', maxHectares: 1 },
    SMALL: { name: 'small', maxHectares: 2 },
    SEMI_MEDIUM: { name: 'semi_medium', maxHectares: 4 },
    MEDIUM: { name: 'medium', maxHectares: 10 },
    LARGE: { name: 'large', maxHectares: Infinity }
};

const getFarmerCategory = (farmSizeHectares) => {
    if (farmSizeHectares <= 1) return 'marginal';
    if (farmSizeHectares <= 2) return 'small';
    if (farmSizeHectares <= 4) return 'semi_medium';
    if (farmSizeHectares <= 10) return 'medium';
    return 'large';
};

const getAllSchemes = async (filters = {}) => {
    const {
        category,
        scheme_type,
        state,
        district,
        crop,
        is_featured,
        active = true,
        search,
        sort_by = 'priority',
        sort_order = 'DESC',
        page = 1,
        limit = 20
    } = filters;

    let query = 'SELECT * FROM schemes WHERE 1=1';
    const params = [];
    let paramIndex = 1;

    if (active !== undefined) {
        query += ` AND active = $${paramIndex}`;
        params.push(active);
        paramIndex++;
    }

    if (category) {
        query += ` AND category = $${paramIndex}`;
        params.push(category);
        paramIndex++;
    }

    if (scheme_type) {
        query += ` AND scheme_type = $${paramIndex}`;
        params.push(scheme_type);
        paramIndex++;
    }

    if (state) {
        query += ` AND (states IS NULL OR states::jsonb ? $${paramIndex})`;
        params.push(state);
        paramIndex++;
    }

    if (district) {
        query += ` AND (districts IS NULL OR districts::jsonb ? $${paramIndex})`;
        params.push(district);
        paramIndex++;
    }

    if (crop) {
        query += ` AND (crops IS NULL OR crops::jsonb ? $${paramIndex})`;
        params.push(crop);
        paramIndex++;
    }

    if (is_featured !== undefined) {
        query += ` AND is_featured = $${paramIndex}`;
        params.push(is_featured);
        paramIndex++;
    }

    if (search) {
        query += ` AND (name ILIKE $${paramIndex} OR description ILIKE $${paramIndex} OR name_hi ILIKE $${paramIndex})`;
        params.push(`%${search}%`);
        paramIndex++;
    }

    const countQuery = query.replace('SELECT *', 'SELECT COUNT(*)');
    const countResult = await db.query(countQuery, params);
    const totalCount = parseInt(countResult.rows[0].count);

    const validSortColumns = ['priority', 'created_at', 'deadline', 'name', 'application_end_date'];
    const sortColumn = validSortColumns.includes(sort_by) ? sort_by : 'priority';
    const sortDirection = sort_order.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

    query += ` ORDER BY ${sortColumn} ${sortDirection}`;

    const offset = (page - 1) * limit;
    query += ` LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
    params.push(limit, offset);

    const result = await db.query(query, params);

    return {
        schemes: result.rows,
        pagination: {
            current_page: parseInt(page),
            total_pages: Math.ceil(totalCount / limit),
            total_items: totalCount,
            items_per_page: parseInt(limit)
        }
    };
};

const getSchemeById = async (schemeId) => {
    const result = await db.query(
        'SELECT * FROM schemes WHERE id = $1',
        [schemeId]
    );

    if (result.rows.length === 0) {
        return null;
    }

    await db.query(
        'UPDATE schemes SET view_count = view_count + 1 WHERE id = $1',
        [schemeId]
    );

    return result.rows[0];
};

const checkEligibility = async (userId, schemeId) => {
    const schemeResult = await db.query('SELECT * FROM schemes WHERE id = $1', [schemeId]);
    if (schemeResult.rows.length === 0) {
        return { eligible: false, reason: 'Scheme not found' };
    }

    const scheme = schemeResult.rows[0];
    
    const profileResult = await db.query(
        'SELECT * FROM user_eligibility_profiles WHERE user_id = $1',
        [userId]
    );

    if (profileResult.rows.length === 0) {
        return {
            eligible: null,
            reason: 'Please complete your eligibility profile first',
            profile_required: true
        };
    }

    const profile = profileResult.rows[0];
    const eligibilityResults = [];
    let isEligible = true;

    if (scheme.min_farm_size !== null && profile.farm_size_hectares !== null) {
        const farmSizeCheck = profile.farm_size_hectares >= scheme.min_farm_size;
        eligibilityResults.push({
            criterion: 'Minimum Farm Size',
            required: `${scheme.min_farm_size} hectares`,
            user_value: `${profile.farm_size_hectares} hectares`,
            passed: farmSizeCheck
        });
        if (!farmSizeCheck) isEligible = false;
    }

    if (scheme.max_farm_size !== null && profile.farm_size_hectares !== null) {
        const farmSizeCheck = profile.farm_size_hectares <= scheme.max_farm_size;
        eligibilityResults.push({
            criterion: 'Maximum Farm Size',
            required: `${scheme.max_farm_size} hectares`,
            user_value: `${profile.farm_size_hectares} hectares`,
            passed: farmSizeCheck
        });
        if (!farmSizeCheck) isEligible = false;
    }

    if (scheme.min_income !== null && profile.annual_income !== null) {
        const incomeCheck = profile.annual_income >= scheme.min_income;
        eligibilityResults.push({
            criterion: 'Minimum Income',
            required: `Rs. ${scheme.min_income}`,
            user_value: `Rs. ${profile.annual_income}`,
            passed: incomeCheck
        });
        if (!incomeCheck) isEligible = false;
    }

    if (scheme.max_income !== null && profile.annual_income !== null) {
        const incomeCheck = profile.annual_income <= scheme.max_income;
        eligibilityResults.push({
            criterion: 'Maximum Income',
            required: `Rs. ${scheme.max_income}`,
            user_value: `Rs. ${profile.annual_income}`,
            passed: incomeCheck
        });
        if (!incomeCheck) isEligible = false;
    }

    if (scheme.land_ownership_type && scheme.land_ownership_type !== 'Any') {
        const ownershipCheck = profile.land_ownership_type === scheme.land_ownership_type.toLowerCase();
        eligibilityResults.push({
            criterion: 'Land Ownership Type',
            required: scheme.land_ownership_type,
            user_value: profile.land_ownership_type,
            passed: ownershipCheck
        });
        if (!ownershipCheck) isEligible = false;
    }

    if (scheme.states && profile.state) {
        const statesArray = typeof scheme.states === 'string' 
            ? JSON.parse(scheme.states) 
            : scheme.states;
        
        const stateCheck = statesArray.includes('All') || statesArray.includes(profile.state);
        eligibilityResults.push({
            criterion: 'State',
            required: statesArray.join(', '),
            user_value: profile.state,
            passed: stateCheck
        });
        if (!stateCheck) isEligible = false;
    }

    if (scheme.crops && profile.primary_crops && profile.primary_crops.length > 0) {
        const cropsArray = typeof scheme.crops === 'string' 
            ? JSON.parse(scheme.crops) 
            : scheme.crops;
        
        const hasMatchingCrop = cropsArray.includes('All') || 
            profile.primary_crops.some(crop => cropsArray.includes(crop));
        
        eligibilityResults.push({
            criterion: 'Crops',
            required: cropsArray.join(', '),
            user_value: profile.primary_crops.join(', '),
            passed: hasMatchingCrop
        });
        if (!hasMatchingCrop) isEligible = false;
    }

    if (scheme.eligibility_criteria) {
        const criteria = typeof scheme.eligibility_criteria === 'string'
            ? JSON.parse(scheme.eligibility_criteria)
            : scheme.eligibility_criteria;

        if (criteria.requires_bank_account && !profile.has_bank_account) {
            eligibilityResults.push({
                criterion: 'Bank Account',
                required: 'Required',
                user_value: 'Not Available',
                passed: false
            });
            isEligible = false;
        }

        if (criteria.requires_aadhar && !profile.has_aadhar) {
            eligibilityResults.push({
                criterion: 'Aadhar Card',
                required: 'Required',
                user_value: 'Not Available',
                passed: false
            });
            isEligible = false;
        }

        if (criteria.farmer_categories && profile.farmer_category) {
            const categoryCheck = criteria.farmer_categories.includes(profile.farmer_category);
            eligibilityResults.push({
                criterion: 'Farmer Category',
                required: criteria.farmer_categories.join(', '),
                user_value: profile.farmer_category,
                passed: categoryCheck
            });
            if (!categoryCheck) isEligible = false;
        }
    }

    return {
        eligible: isEligible,
        scheme: {
            id: scheme.id,
            name: scheme.name,
            category: scheme.category
        },
        criteria_results: eligibilityResults,
        passed_count: eligibilityResults.filter(r => r.passed).length,
        total_count: eligibilityResults.length
    };
};

const getEligibleSchemes = async (userId) => {
    const profileResult = await db.query(
        'SELECT * FROM user_eligibility_profiles WHERE user_id = $1',
        [userId]
    );

    if (profileResult.rows.length === 0) {
        return {
            eligible_schemes: [],
            profile_required: true,
            message: 'Please complete your eligibility profile to see matching schemes'
        };
    }

    const profile = profileResult.rows[0];
    
    let query = 'SELECT * FROM schemes WHERE active = true';
    const params = [];
    let paramIndex = 1;

    if (profile.farm_size_hectares !== null) {
        query += ` AND (min_farm_size IS NULL OR min_farm_size <= $${paramIndex})`;
        params.push(profile.farm_size_hectares);
        paramIndex++;
        
        query += ` AND (max_farm_size IS NULL OR max_farm_size >= $${paramIndex})`;
        params.push(profile.farm_size_hectares);
        paramIndex++;
    }

    if (profile.annual_income !== null) {
        query += ` AND (min_income IS NULL OR min_income <= $${paramIndex})`;
        params.push(profile.annual_income);
        paramIndex++;
        
        query += ` AND (max_income IS NULL OR max_income >= $${paramIndex})`;
        params.push(profile.annual_income);
        paramIndex++;
    }

    if (profile.state) {
        query += ` AND (states IS NULL OR states::jsonb ? $${paramIndex} OR states::jsonb ? 'All')`;
        params.push(profile.state);
        paramIndex++;
    }

    query += ' ORDER BY priority DESC, created_at DESC';

    const result = await db.query(query, params);

    const eligibleSchemes = [];
    for (const scheme of result.rows) {
        const eligibilityCheck = await checkEligibility(userId, scheme.id);
        if (eligibilityCheck.eligible) {
            eligibleSchemes.push({
                ...scheme,
                eligibility_score: eligibilityCheck.passed_count / eligibilityCheck.total_count
            });
        }
    }

    eligibleSchemes.sort((a, b) => b.eligibility_score - a.eligibility_score);

    return {
        eligible_schemes: eligibleSchemes,
        total_count: eligibleSchemes.length,
        profile: {
            farm_size: profile.farm_size_hectares,
            state: profile.state,
            farmer_category: profile.farmer_category
        }
    };
};

const subscribeToScheme = async (userId, schemeId, preferences = {}) => {
    const existingSubscription = await db.query(
        'SELECT * FROM scheme_subscriptions WHERE user_id = $1 AND scheme_id = $2',
        [userId, schemeId]
    );

    if (existingSubscription.rows.length > 0) {
        const result = await db.query(
            `UPDATE scheme_subscriptions 
             SET notification_enabled = true, 
                 notification_preferences = $3
             WHERE user_id = $1 AND scheme_id = $2
             RETURNING *`,
            [userId, schemeId, JSON.stringify(preferences)]
        );
        return result.rows[0];
    }

    const result = await db.query(
        `INSERT INTO scheme_subscriptions (user_id, scheme_id, notification_preferences)
         VALUES ($1, $2, $3)
         RETURNING *`,
        [userId, schemeId, JSON.stringify(preferences)]
    );

    return result.rows[0];
};

const unsubscribeFromScheme = async (userId, schemeId) => {
    const result = await db.query(
        `UPDATE scheme_subscriptions 
         SET notification_enabled = false
         WHERE user_id = $1 AND scheme_id = $2
         RETURNING *`,
        [userId, schemeId]
    );

    return result.rows.length > 0;
};

const getUserSubscriptions = async (userId) => {
    const result = await db.query(
        `SELECT ss.*, s.name, s.category, s.deadline, s.application_end_date, s.benefits
         FROM scheme_subscriptions ss
         JOIN schemes s ON ss.scheme_id = s.id
         WHERE ss.user_id = $1 AND ss.notification_enabled = true
         ORDER BY s.deadline ASC NULLS LAST`,
        [userId]
    );

    return result.rows;
};

const getUpcomingDeadlines = async (daysAhead = 30) => {
    const result = await db.query(
        `SELECT * FROM schemes 
         WHERE active = true 
         AND (deadline IS NOT NULL AND deadline > NOW() AND deadline <= NOW() + INTERVAL '${daysAhead} days')
         OR (application_end_date IS NOT NULL AND application_end_date > NOW() AND application_end_date <= NOW() + INTERVAL '${daysAhead} days')
         ORDER BY COALESCE(deadline, application_end_date) ASC`
    );

    return result.rows;
};

const sendDeadlineNotifications = async () => {
    const notificationDays = [30, 15, 7, 3, 1];
    const notifications = [];

    for (const days of notificationDays) {
        const schemesResult = await db.query(
            `SELECT s.*, ss.user_id
             FROM schemes s
             JOIN scheme_subscriptions ss ON s.id = ss.scheme_id
             WHERE s.active = true
             AND ss.notification_enabled = true
             AND s.notification_enabled = true
             AND (
                 (s.deadline IS NOT NULL AND DATE(s.deadline) = DATE(NOW() + INTERVAL '${days} days'))
                 OR (s.application_end_date IS NOT NULL AND DATE(s.application_end_date) = DATE(NOW() + INTERVAL '${days} days'))
             )`
        );

        for (const row of schemesResult.rows) {
            const deadlineDate = row.deadline || row.application_end_date;
            const title = `${row.name} - ${days} Day${days > 1 ? 's' : ''} Left`;
            const message = `Application deadline for ${row.name} is ${deadlineDate.toLocaleDateString()}. Apply now to not miss out!`;

            const existingNotification = await db.query(
                `SELECT * FROM scheme_notifications 
                 WHERE user_id = $1 AND scheme_id = $2 
                 AND notification_type = 'deadline_reminder'
                 AND DATE(sent_at) = DATE(NOW())`,
                [row.user_id, row.id]
            );

            if (existingNotification.rows.length === 0) {
                await db.query(
                    `INSERT INTO scheme_notifications (user_id, scheme_id, notification_type, title, message)
                     VALUES ($1, $2, 'deadline_reminder', $3, $4)`,
                    [row.user_id, row.id, title, message]
                );

                await pushNotificationService.sendToUser(
                    row.user_id,
                    title,
                    message,
                    { type: 'scheme_deadline', scheme_id: row.id.toString() }
                );

                notifications.push({ user_id: row.user_id, scheme_id: row.id, days });
            }
        }
    }

    return { sent_count: notifications.length, notifications };
};

const notifyEligibleUsers = async (schemeId) => {
    const schemeResult = await db.query('SELECT * FROM schemes WHERE id = $1', [schemeId]);
    if (schemeResult.rows.length === 0) return { notified_count: 0 };

    const scheme = schemeResult.rows[0];

    let query = `SELECT u.id, u.email, uep.*
         FROM users u
         JOIN user_eligibility_profiles uep ON u.id = uep.user_id
         WHERE 1=1`;
    const params = [];
    let paramIndex = 1;

    if (scheme.min_farm_size !== null) {
        query += ` AND (uep.farm_size_hectares IS NULL OR uep.farm_size_hectares >= $${paramIndex})`;
        params.push(scheme.min_farm_size);
        paramIndex++;
    }

    if (scheme.max_farm_size !== null) {
        query += ` AND (uep.farm_size_hectares IS NULL OR uep.farm_size_hectares <= $${paramIndex})`;
        params.push(scheme.max_farm_size);
        paramIndex++;
    }

    if (scheme.states) {
        const states = typeof scheme.states === 'string' ? JSON.parse(scheme.states) : scheme.states;
        if (!states.includes('All')) {
            query += ` AND uep.state = ANY($${paramIndex}::text[])`;
            params.push(states);
            paramIndex++;
        }
    }

    const usersResult = await db.query(query, params);
    let notifiedCount = 0;

    for (const user of usersResult.rows) {
        const title = `New Scheme: ${scheme.name}`;
        const message = `A new agricultural scheme "${scheme.name}" is available. You may be eligible! Check now.`;

        await db.query(
            `INSERT INTO scheme_notifications (user_id, scheme_id, notification_type, title, message)
             VALUES ($1, $2, 'new_scheme', $3, $4)`,
            [user.id, schemeId, title, message]
        );

        await pushNotificationService.sendToUser(
            user.id,
            title,
            message,
            { type: 'new_scheme', scheme_id: schemeId.toString() }
        );

        notifiedCount++;
    }

    return { notified_count: notifiedCount, scheme_name: scheme.name };
};

const saveEligibilityProfile = async (userId, profileData) => {
    const {
        farm_size_hectares,
        annual_income,
        land_ownership_type,
        primary_crops,
        state,
        district,
        block,
        village,
        social_category,
        gender,
        age,
        has_bank_account,
        has_aadhar,
        has_kcc,
        irrigation_type,
        soil_type,
        additional_criteria
    } = profileData;

    const farmer_category = farm_size_hectares ? getFarmerCategory(farm_size_hectares) : null;

    const existingProfile = await db.query(
        'SELECT * FROM user_eligibility_profiles WHERE user_id = $1',
        [userId]
    );

    if (existingProfile.rows.length > 0) {
        const result = await db.query(
            `UPDATE user_eligibility_profiles SET
                farm_size_hectares = $2,
                annual_income = $3,
                land_ownership_type = $4,
                primary_crops = $5,
                state = $6,
                district = $7,
                block = $8,
                village = $9,
                farmer_category = $10,
                social_category = $11,
                gender = $12,
                age = $13,
                has_bank_account = $14,
                has_aadhar = $15,
                has_kcc = $16,
                irrigation_type = $17,
                soil_type = $18,
                additional_criteria = $19,
                updated_at = NOW()
             WHERE user_id = $1
             RETURNING *`,
            [
                userId, farm_size_hectares, annual_income, land_ownership_type,
                primary_crops, state, district, block, village, farmer_category,
                social_category, gender, age, has_bank_account, has_aadhar,
                has_kcc, irrigation_type, soil_type, JSON.stringify(additional_criteria)
            ]
        );
        return result.rows[0];
    }

    const result = await db.query(
        `INSERT INTO user_eligibility_profiles (
            user_id, farm_size_hectares, annual_income, land_ownership_type,
            primary_crops, state, district, block, village, farmer_category,
            social_category, gender, age, has_bank_account, has_aadhar,
            has_kcc, irrigation_type, soil_type, additional_criteria
         ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19)
         RETURNING *`,
        [
            userId, farm_size_hectares, annual_income, land_ownership_type,
            primary_crops, state, district, block, village, farmer_category,
            social_category, gender, age, has_bank_account, has_aadhar,
            has_kcc, irrigation_type, soil_type, JSON.stringify(additional_criteria)
        ]
    );

    return result.rows[0];
};

const getEligibilityProfile = async (userId) => {
    const result = await db.query(
        'SELECT * FROM user_eligibility_profiles WHERE user_id = $1',
        [userId]
    );

    return result.rows[0] || null;
};

const getSchemesByRegion = async (state, district = null) => {
    let query = `SELECT * FROM schemes WHERE active = true
                 AND (states IS NULL OR states::jsonb ? $1 OR states::jsonb ? 'All')`;
    const params = [state];

    if (district) {
        query += ` AND (districts IS NULL OR districts::jsonb ? $2)`;
        params.push(district);
    }

    query += ' ORDER BY priority DESC, created_at DESC';

    const result = await db.query(query, params);
    return result.rows;
};

const getSchemeNotifications = async (userId, unreadOnly = false) => {
    let query = `SELECT sn.*, s.name as scheme_name, s.category
                 FROM scheme_notifications sn
                 JOIN schemes s ON sn.scheme_id = s.id
                 WHERE sn.user_id = $1`;
    const params = [userId];

    if (unreadOnly) {
        query += ' AND sn.is_read = false';
    }

    query += ' ORDER BY sn.sent_at DESC LIMIT 50';

    const result = await db.query(query, params);
    return result.rows;
};

const markNotificationRead = async (userId, notificationId) => {
    const result = await db.query(
        `UPDATE scheme_notifications 
         SET is_read = true, read_at = NOW()
         WHERE id = $1 AND user_id = $2
         RETURNING *`,
        [notificationId, userId]
    );

    return result.rows[0];
};

module.exports = {
    SCHEME_CATEGORIES,
    SCHEME_TYPES,
    FARMER_CATEGORIES,
    getFarmerCategory,
    getAllSchemes,
    getSchemeById,
    checkEligibility,
    getEligibleSchemes,
    subscribeToScheme,
    unsubscribeFromScheme,
    getUserSubscriptions,
    getUpcomingDeadlines,
    sendDeadlineNotifications,
    notifyEligibleUsers,
    saveEligibilityProfile,
    getEligibilityProfile,
    getSchemesByRegion,
    getSchemeNotifications,
    markNotificationRead
};
