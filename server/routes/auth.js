const express = require('express');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { authenticateToken } = require('../middleware/auth');
const emailService = require('../services/emailService');

const router = express.Router();

// Register new user
router.post('/register', async (req, res) => {
  try {
    const { email, password, firstName, lastName, emergencyContact, emergencyEmails } = req.body;

    // Validate required fields
    if (!email || !password || !firstName || !lastName) {
      return res.status(400).json({ 
        error: 'Email, password, first name, and last name are required' 
      });
    }

    // Validate emergency emails
    if (!emergencyEmails || !Array.isArray(emergencyEmails) || emergencyEmails.length !== 3) {
      return res.status(400).json({ 
        error: 'Exactly 3 emergency email addresses are required' 
      });
    }

    // Validate email format for each emergency email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    for (let i = 0; i < emergencyEmails.length; i++) {
      if (!emailRegex.test(emergencyEmails[i])) {
        return res.status(400).json({ 
          error: `Emergency email ${i + 1} is not in valid format` 
        });
      }
    }

    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ error: 'User already exists with this email' });
    }

    // Create new user
    const user = new User({
      email,
      password,
      firstName,
      lastName,
      emergencyContact,
      emergencyEmails
    });

    await user.save();

    // Generate JWT token
    const token = jwt.sign(
      { userId: user._id },
      process.env.JWT_SECRET || 'fallback_secret',
      { expiresIn: '7d' }
    );

    res.status(201).json({
      message: 'User registered successfully',
      token,
      user
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ error: 'Registration failed' });
  }
});

// Login user
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    // Find user by email
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    // Check password
    const isValidPassword = await user.comparePassword(password);
    if (!isValidPassword) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    // Update last login
    user.lastLogin = new Date();
    await user.save();

    // Generate JWT token
    const token = jwt.sign(
      { userId: user._id },
      process.env.JWT_SECRET || 'fallback_secret',
      { expiresIn: '7d' }
    );

    res.json({
      message: 'Login successful',
      token,
      user
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Login failed' });
  }
});

// Get current user profile
router.get('/profile', authenticateToken, async (req, res) => {
  try {
    res.json({ user: req.user });
  } catch (error) {
    console.error('Profile error:', error);
    res.status(500).json({ error: 'Failed to fetch profile' });
  }
});

// Update user profile
router.put('/profile', authenticateToken, async (req, res) => {
  try {
    const { firstName, lastName, emergencyContact } = req.body;
    
    const user = await User.findByIdAndUpdate(
      req.user._id,
      { firstName, lastName, emergencyContact },
      { new: true, runValidators: true }
    );
    
    res.json({
      message: 'Profile updated successfully',
      user
    });
  } catch (error) {
    console.error('Profile update error:', error);
    res.status(500).json({ error: 'Failed to update profile' });
  }
});

// Update emergency emails
router.put('/emergency-emails', authenticateToken, async (req, res) => {
  try {
    const { emergencyEmails } = req.body;

    // Validate emergency emails
    if (!emergencyEmails || !Array.isArray(emergencyEmails) || emergencyEmails.length !== 3) {
      return res.status(400).json({ 
        error: 'Exactly 3 emergency email addresses are required' 
      });
    }

    // Validate email format for each emergency email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    for (let i = 0; i < emergencyEmails.length; i++) {
      if (!emailRegex.test(emergencyEmails[i])) {
        return res.status(400).json({ 
          error: `Emergency email ${i + 1} is not in valid format` 
        });
      }
    }
    
    const user = await User.findByIdAndUpdate(
      req.user._id,
      { emergencyEmails },
      { new: true, runValidators: true }
    );
    
    res.json({
      message: 'Emergency emails updated successfully',
      user
    });
  } catch (error) {
    console.error('Emergency emails update error:', error);
    if (error.name === 'ValidationError') {
      return res.status(400).json({ error: error.message });
    }
    res.status(500).json({ error: 'Failed to update emergency emails' });
  }
});

// Get emergency emails
router.get('/emergency-emails', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user._id).select('emergencyEmails');
    
    res.json({
      emergencyEmails: user.emergencyEmails || []
    });
  } catch (error) {
    console.error('Get emergency emails error:', error);
    res.status(500).json({ error: 'Failed to fetch emergency emails' });
  }
});

// Test email functionality (for development/testing only)
router.post('/test-email', authenticateToken, async (req, res) => {
  try {
    const user = req.user;
    
    console.log('User object:', JSON.stringify(user, null, 2));
    console.log('User ID:', user._id);
    console.log('Emergency emails:', user.emergencyEmails);
    
    if (!user.emergencyEmails || user.emergencyEmails.length === 0) {
      return res.status(400).json({ 
        error: 'No emergency emails configured for this user',
        userInfo: {
          id: user._id,
          email: user.email,
          name: user.firstName + ' ' + user.lastName
        }
      });
    }

    // Send test emergency email
    await emailService.sendEmergencyAlert(user._id, {
      transcription: 'Test emergency alert from Postman',
      type: 'Test Alert',
      confidence: 0.95,
      keywords: ['test', 'emergency'],
      location: 'Test Location',
      timestamp: new Date().toISOString()
    });

    res.json({
      message: 'Test emergency email sent successfully',
      sentTo: user.emergencyEmails,
      user: user.firstName + ' ' + user.lastName
    });
  } catch (error) {
    console.error('Test email error:', error);
    res.status(500).json({ 
      error: 'Failed to send test email',
      details: error.message 
    });
  }
});

// Simple email test (for debugging SMTP)
router.post('/test-smtp', async (req, res) => {
  try {
    const { testEmail } = req.body || {};
    
    // Use a default test email if none provided
    const emailToTest = testEmail || 'test@example.com';
    
    if (!emailToTest) {
      return res.status(400).json({ 
        error: 'testEmail is required in request body',
        example: { testEmail: 'your-email@gmail.com' }
      });
    }

    await emailService.sendTestEmail(emailToTest);
    
    res.json({
      message: 'Test email sent successfully',
      sentTo: emailToTest
    });
  } catch (error) {
    console.error('SMTP test error:', error);
    res.status(500).json({ 
      error: 'Failed to send test email',
      details: error.message 
    });
  }
});

module.exports = router;