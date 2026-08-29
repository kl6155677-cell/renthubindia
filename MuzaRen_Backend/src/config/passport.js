const passport = require('passport');
const GoogleStrategy = require('passport-google-oauth20').Strategy;

passport.use(
  new GoogleStrategy(
    {
      clientID: process.env.GOOGLE_CLIENT_ID,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET,
      callbackURL: '/api/auth/google/callback', // Note: Make sure this matches your route
    },
    async (accessToken, refreshToken, profile, done) => {
      try {
        // We handle user upserting via the strategy callback.
        // auth.service.js handles Google OAuth logic as well, but Passport verifies it.
        return done(null, profile);
      } catch (error) {
        return done(error, null);
      }
    }
  )
);

module.exports = passport;
