const asyncHandler = require('express-async-handler');
const { validationResult } = require('express-validator');
const schemeService = require('../services/schemeService');

const getSchemes = asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ success: false, errors: errors.array() });
    }

    const filters = {
        category: req.query.category,
        scheme_type: req.query.scheme_type,
        state: req.query.state,
        district: req.query.district,
        crop: req.query.crop,
        is_featured: req.query.is_featured === 'true' ? true : undefined,
        active: req.query.active !== 'false',
        search: req.query.search,
        sort_by: req.query.sort_by,
        sort_order: req.query.sort_order,
        page: req.query.page,
        limit: req.query.limit
    };

    const result = await schemeService.getAllSchemes(filters);

    res.json({
        success: true,
        data: result.schemes,
        pagination: result.pagination
    });
});

const getSchemeById = asyncHandler(async (req, res) => {
    const { id } = req.params;
    const scheme = await schemeService.getSchemeById(id);

    if (!scheme) {
        res.status(404);
        throw new Error('Scheme not found');
    }

    res.json({
        success: true,
        data: scheme
    });
});

const checkEligibility = asyncHandler(async (req, res) => {
    const { id } = req.params;
    const result = await schemeService.checkEligibility(req.user.id, id);

    res.json({
        success: true,
        data: result
    });
});

const getEligibleSchemes = asyncHandler(async (req, res) => {
    const result = await schemeService.getEligibleSchemes(req.user.id);

    res.json({
        success: true,
        data: result.eligible_schemes,
        total_count: result.total_count,
        profile_required: result.profile_required || false,
        message: result.message,
        user_profile: result.profile
    });
});

const subscribeToScheme = asyncHandler(async (req, res) => {
    const { scheme_id, notification_preferences } = req.body;

    if (!scheme_id) {
        res.status(400);
        throw new Error('scheme_id is required');
    }

    const subscription = await schemeService.subscribeToScheme(
        req.user.id,
        scheme_id,
        notification_preferences || { email: true, push: true, sms: false }
    );

    res.json({
        success: true,
        message: 'Subscribed to scheme notifications',
        data: subscription
    });
});

const unsubscribeFromScheme = asyncHandler(async (req, res) => {
    const { scheme_id } = req.params;

    const success = await schemeService.unsubscribeFromScheme(req.user.id, scheme_id);

    res.json({
        success: true,
        message: success ? 'Unsubscribed from scheme notifications' : 'No subscription found'
    });
});

const getUserSubscriptions = asyncHandler(async (req, res) => {
    const subscriptions = await schemeService.getUserSubscriptions(req.user.id);

    res.json({
        success: true,
        data: subscriptions,
        count: subscriptions.length
    });
});

const getUpcomingDeadlines = asyncHandler(async (req, res) => {
    const daysAhead = parseInt(req.query.days) || 30;
    const schemes = await schemeService.getUpcomingDeadlines(daysAhead);

    res.json({
        success: true,
        data: schemes,
        count: schemes.length,
        days_ahead: daysAhead
    });
});

const saveEligibilityProfile = asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ success: false, errors: errors.array() });
    }

    const profile = await schemeService.saveEligibilityProfile(req.user.id, req.body);

    res.json({
        success: true,
        message: 'Eligibility profile saved successfully',
        data: profile
    });
});

const getEligibilityProfile = asyncHandler(async (req, res) => {
    const profile = await schemeService.getEligibilityProfile(req.user.id);

    if (!profile) {
        return res.json({
            success: true,
            data: null,
            message: 'No eligibility profile found. Please complete your profile.'
        });
    }

    res.json({
        success: true,
        data: profile
    });
});

const getSchemesByRegion = asyncHandler(async (req, res) => {
    const { state, district } = req.query;

    if (!state) {
        res.status(400);
        throw new Error('State is required');
    }

    const schemes = await schemeService.getSchemesByRegion(state, district);

    res.json({
        success: true,
        data: schemes,
        count: schemes.length,
        region: { state, district }
    });
});

const getSchemeNotifications = asyncHandler(async (req, res) => {
    const unreadOnly = req.query.unread === 'true';
    const notifications = await schemeService.getSchemeNotifications(req.user.id, unreadOnly);

    res.json({
        success: true,
        data: notifications,
        count: notifications.length,
        unread_only: unreadOnly
    });
});

const markNotificationRead = asyncHandler(async (req, res) => {
    const { id } = req.params;
    const notification = await schemeService.markNotificationRead(req.user.id, id);

    if (!notification) {
        res.status(404);
        throw new Error('Notification not found');
    }

    res.json({
        success: true,
        message: 'Notification marked as read',
        data: notification
    });
});

const getSchemeCategories = asyncHandler(async (req, res) => {
    res.json({
        success: true,
        data: {
            categories: Object.values(schemeService.SCHEME_CATEGORIES),
            types: Object.values(schemeService.SCHEME_TYPES),
            farmer_categories: Object.keys(schemeService.FARMER_CATEGORIES).map(key => ({
                name: schemeService.FARMER_CATEGORIES[key].name,
                max_hectares: schemeService.FARMER_CATEGORIES[key].maxHectares
            }))
        }
    });
});

const triggerDeadlineNotifications = asyncHandler(async (req, res) => {
    const result = await schemeService.sendDeadlineNotifications();

    res.json({
        success: true,
        message: `Sent ${result.sent_count} deadline notifications`,
        data: result
    });
});

module.exports = {
    getSchemes,
    getSchemeById,
    checkEligibility,
    getEligibleSchemes,
    subscribeToScheme,
    unsubscribeFromScheme,
    getUserSubscriptions,
    getUpcomingDeadlines,
    saveEligibilityProfile,
    getEligibilityProfile,
    getSchemesByRegion,
    getSchemeNotifications,
    markNotificationRead,
    getSchemeCategories,
    triggerDeadlineNotifications
};
