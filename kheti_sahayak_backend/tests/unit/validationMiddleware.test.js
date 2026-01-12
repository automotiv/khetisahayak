const { validationResult } = require('express-validator');

const mockWarn = jest.fn();

jest.mock('../../utils/logger', () => ({
  warn: mockWarn
}));

const validationMiddleware = require('../../middleware/validationMiddleware');

describe('Validation Middleware', () => {
  let mockReq;
  let mockRes;
  let mockNext;

  beforeEach(() => {
    jest.clearAllMocks();
    mockReq = {
      body: {},
      query: {},
      params: {},
      method: 'POST',
      originalUrl: '/api/test',
      ip: '127.0.0.1'
    };
    mockRes = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn()
    };
    mockNext = jest.fn();
  });

  describe('handleValidationErrors', () => {
    it('should call next when no errors', async () => {
      const mockValidationResult = { isEmpty: () => true, array: () => [] };
      jest.spyOn(require('express-validator'), 'validationResult').mockReturnValue(mockValidationResult);

      validationMiddleware.handleValidationErrors(mockReq, mockRes, mockNext);

      expect(mockNext).toHaveBeenCalled();
    });
  });

  describe('validateUUID', () => {
    it('should create validator for param', () => {
      const validator = validationMiddleware.validateUUID('id', 'param');
      expect(validator).toBeDefined();
    });

    it('should create validator for body', () => {
      const validator = validationMiddleware.validateUUID('product_id', 'body');
      expect(validator).toBeDefined();
    });

    it('should create validator for query', () => {
      const validator = validationMiddleware.validateUUID('filter_id', 'query');
      expect(validator).toBeDefined();
    });

    it('should default to param location', () => {
      const validator = validationMiddleware.validateUUID('id');
      expect(validator).toBeDefined();
    });
  });

  describe('validateEmail', () => {
    it('should create email validator', () => {
      const validator = validationMiddleware.validateEmail();
      expect(validator).toBeDefined();
    });

    it('should use custom field name', () => {
      const validator = validationMiddleware.validateEmail('user_email');
      expect(validator).toBeDefined();
    });
  });

  describe('validatePhone', () => {
    it('should create phone validator', () => {
      const validator = validationMiddleware.validatePhone();
      expect(validator).toBeDefined();
    });

    it('should use custom field name', () => {
      const validator = validationMiddleware.validatePhone('contact_phone');
      expect(validator).toBeDefined();
    });
  });

  describe('validatePassword', () => {
    it('should create password validator with defaults', () => {
      const validator = validationMiddleware.validatePassword();
      expect(validator).toBeDefined();
    });

    it('should create password validator with custom options', () => {
      const validator = validationMiddleware.validatePassword('password', {
        minLength: 10,
        requireUppercase: false,
        requireNumber: false
      });
      expect(validator).toBeDefined();
    });
  });

  describe('validatePagination', () => {
    it('should be an array of validators', () => {
      expect(Array.isArray(validationMiddleware.validatePagination)).toBe(true);
      expect(validationMiddleware.validatePagination.length).toBe(2);
    });
  });

  describe('validateCoordinates', () => {
    it('should create coordinate validators', () => {
      const validators = validationMiddleware.validateCoordinates();
      expect(Array.isArray(validators)).toBe(true);
      expect(validators.length).toBe(2);
    });

    it('should use custom field names', () => {
      const validators = validationMiddleware.validateCoordinates('lat', 'lng');
      expect(validators.length).toBe(2);
    });
  });

  describe('validatePrice', () => {
    it('should create required price validator', () => {
      const validator = validationMiddleware.validatePrice();
      expect(validator).toBeDefined();
    });

    it('should create optional price validator', () => {
      const validator = validationMiddleware.validatePrice('discount', { required: false });
      expect(validator).toBeDefined();
    });

    it('should use custom minimum value', () => {
      const validator = validationMiddleware.validatePrice('amount', { min: 100 });
      expect(validator).toBeDefined();
    });
  });

  describe('validateQuantity', () => {
    it('should create required quantity validator', () => {
      const validator = validationMiddleware.validateQuantity();
      expect(validator).toBeDefined();
    });

    it('should create optional quantity validator', () => {
      const validator = validationMiddleware.validateQuantity('stock', { required: false });
      expect(validator).toBeDefined();
    });

    it('should use custom min and max', () => {
      const validator = validationMiddleware.validateQuantity('count', { min: 1, max: 100 });
      expect(validator).toBeDefined();
    });
  });

  describe('validateDate', () => {
    it('should create required date validator', () => {
      const validator = validationMiddleware.validateDate('start_date');
      expect(validator).toBeDefined();
    });

    it('should create optional date validator', () => {
      const validator = validationMiddleware.validateDate('end_date', { required: false });
      expect(validator).toBeDefined();
    });

    it('should create query date validator', () => {
      const validator = validationMiddleware.validateDate('from', { location: 'query' });
      expect(validator).toBeDefined();
    });
  });

  describe('validateURL', () => {
    it('should create optional URL validator by default', () => {
      const validator = validationMiddleware.validateURL('website');
      expect(validator).toBeDefined();
    });

    it('should create required URL validator', () => {
      const validator = validationMiddleware.validateURL('callback_url', { required: true });
      expect(validator).toBeDefined();
    });

    it('should use custom protocols', () => {
      const validator = validationMiddleware.validateURL('image', { protocols: ['https'] });
      expect(validator).toBeDefined();
    });
  });

  describe('validateRating', () => {
    it('should create rating validator', () => {
      const validator = validationMiddleware.validateRating();
      expect(validator).toBeDefined();
    });

    it('should use custom field name', () => {
      const validator = validationMiddleware.validateRating('score');
      expect(validator).toBeDefined();
    });
  });

  describe('sanitizeString', () => {
    it('should create required string sanitizer', () => {
      const sanitizer = validationMiddleware.sanitizeString('name');
      expect(sanitizer).toBeDefined();
    });

    it('should create optional string sanitizer', () => {
      const sanitizer = validationMiddleware.sanitizeString('nickname', { required: false });
      expect(sanitizer).toBeDefined();
    });

    it('should use custom max length', () => {
      const sanitizer = validationMiddleware.sanitizeString('title', { maxLength: 200 });
      expect(sanitizer).toBeDefined();
    });

    it('should create query string sanitizer', () => {
      const sanitizer = validationMiddleware.sanitizeString('search', { location: 'query' });
      expect(sanitizer).toBeDefined();
    });
  });

  describe('sanitizeText', () => {
    it('should create required text sanitizer', () => {
      const sanitizer = validationMiddleware.sanitizeText('description');
      expect(sanitizer).toBeDefined();
    });

    it('should create optional text sanitizer', () => {
      const sanitizer = validationMiddleware.sanitizeText('notes', { required: false });
      expect(sanitizer).toBeDefined();
    });

    it('should use custom max length', () => {
      const sanitizer = validationMiddleware.sanitizeText('content', { maxLength: 50000 });
      expect(sanitizer).toBeDefined();
    });
  });

  describe('validateArray', () => {
    it('should create required array validator', () => {
      const validator = validationMiddleware.validateArray('items');
      expect(validator).toBeDefined();
    });

    it('should create optional array validator', () => {
      const validator = validationMiddleware.validateArray('tags', { required: false });
      expect(validator).toBeDefined();
    });

    it('should use custom min and max length', () => {
      const validator = validationMiddleware.validateArray('images', { minLength: 1, maxLength: 5 });
      expect(validator).toBeDefined();
    });
  });

  describe('validateBoolean', () => {
    it('should create optional boolean validator by default', () => {
      const validator = validationMiddleware.validateBoolean('is_active');
      expect(validator).toBeDefined();
    });

    it('should create required boolean validator', () => {
      const validator = validationMiddleware.validateBoolean('confirmed', { required: true });
      expect(validator).toBeDefined();
    });
  });

  describe('validateEnum', () => {
    it('should create required enum validator', () => {
      const validator = validationMiddleware.validateEnum('status', ['active', 'inactive', 'pending']);
      expect(validator).toBeDefined();
    });

    it('should create optional enum validator', () => {
      const validator = validationMiddleware.validateEnum('type', ['a', 'b'], { required: false });
      expect(validator).toBeDefined();
    });

    it('should create query enum validator', () => {
      const validator = validationMiddleware.validateEnum('sort', ['asc', 'desc'], { location: 'query' });
      expect(validator).toBeDefined();
    });
  });

  describe('Route-Specific Validation Chains', () => {
    describe('communityPostValidation', () => {
      it('should be an array of validators', () => {
        expect(Array.isArray(validationMiddleware.communityPostValidation)).toBe(true);
        expect(validationMiddleware.communityPostValidation.length).toBeGreaterThan(0);
      });
    });

    describe('logbookEntryValidation', () => {
      it('should be an array of validators', () => {
        expect(Array.isArray(validationMiddleware.logbookEntryValidation)).toBe(true);
        expect(validationMiddleware.logbookEntryValidation.length).toBeGreaterThan(0);
      });
    });

    describe('equipmentListingValidation', () => {
      it('should be an array of validators', () => {
        expect(Array.isArray(validationMiddleware.equipmentListingValidation)).toBe(true);
        expect(validationMiddleware.equipmentListingValidation.length).toBeGreaterThan(0);
      });
    });

    describe('equipmentBookingValidation', () => {
      it('should be an array of validators', () => {
        expect(Array.isArray(validationMiddleware.equipmentBookingValidation)).toBe(true);
      });
    });

    describe('cartAddValidation', () => {
      it('should be an array of validators', () => {
        expect(Array.isArray(validationMiddleware.cartAddValidation)).toBe(true);
      });
    });

    describe('cartUpdateValidation', () => {
      it('should be an array of validators', () => {
        expect(Array.isArray(validationMiddleware.cartUpdateValidation)).toBe(true);
      });
    });

    describe('reviewValidation', () => {
      it('should be an array of validators', () => {
        expect(Array.isArray(validationMiddleware.reviewValidation)).toBe(true);
      });
    });

    describe('technologyExperienceValidation', () => {
      it('should be an array of validators', () => {
        expect(Array.isArray(validationMiddleware.technologyExperienceValidation)).toBe(true);
      });
    });

    describe('schemeQueryValidation', () => {
      it('should be an array of validators', () => {
        expect(Array.isArray(validationMiddleware.schemeQueryValidation)).toBe(true);
      });
    });

    describe('validateIdParam', () => {
      it('should be an array of validators', () => {
        expect(Array.isArray(validationMiddleware.validateIdParam)).toBe(true);
        expect(validationMiddleware.validateIdParam.length).toBe(2);
      });
    });
  });

  describe('Module Exports', () => {
    it('should export handleValidationErrors', () => {
      expect(validationMiddleware.handleValidationErrors).toBeDefined();
    });

    it('should export all common validators', () => {
      expect(validationMiddleware.validateUUID).toBeDefined();
      expect(validationMiddleware.validateEmail).toBeDefined();
      expect(validationMiddleware.validatePhone).toBeDefined();
      expect(validationMiddleware.validatePassword).toBeDefined();
      expect(validationMiddleware.validatePagination).toBeDefined();
      expect(validationMiddleware.validateCoordinates).toBeDefined();
      expect(validationMiddleware.validatePrice).toBeDefined();
      expect(validationMiddleware.validateQuantity).toBeDefined();
      expect(validationMiddleware.validateDate).toBeDefined();
      expect(validationMiddleware.validateURL).toBeDefined();
      expect(validationMiddleware.validateRating).toBeDefined();
      expect(validationMiddleware.validateArray).toBeDefined();
      expect(validationMiddleware.validateBoolean).toBeDefined();
      expect(validationMiddleware.validateEnum).toBeDefined();
    });

    it('should export all sanitizers', () => {
      expect(validationMiddleware.sanitizeString).toBeDefined();
      expect(validationMiddleware.sanitizeText).toBeDefined();
    });

    it('should export all route-specific validation chains', () => {
      expect(validationMiddleware.communityPostValidation).toBeDefined();
      expect(validationMiddleware.logbookEntryValidation).toBeDefined();
      expect(validationMiddleware.equipmentListingValidation).toBeDefined();
      expect(validationMiddleware.equipmentBookingValidation).toBeDefined();
      expect(validationMiddleware.cartAddValidation).toBeDefined();
      expect(validationMiddleware.cartUpdateValidation).toBeDefined();
      expect(validationMiddleware.reviewValidation).toBeDefined();
      expect(validationMiddleware.technologyExperienceValidation).toBeDefined();
      expect(validationMiddleware.schemeQueryValidation).toBeDefined();
      expect(validationMiddleware.validateIdParam).toBeDefined();
    });
  });
});
