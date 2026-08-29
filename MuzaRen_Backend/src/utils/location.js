/**
 * Utility for normalizing location strings (Countries, Cities).
 * Ensures consistency between search queries and database records.
 */

const countryMap = {
  'US': 'United States',
  'USA': 'United States',
  'UK': 'United Kingdom',
  'GB': 'United Kingdom',
  'UAE': 'United Arab Emirates',
  'IN': 'India',
  'FR': 'France',
  'DE': 'Germany',
  'IT': 'Italy',
  'ES': 'Spain',
  'CA': 'Canada',
  'AU': 'Australia',
  // Add more as needed, or use an external library in production
};

/**
 * Normalizes a country name or code into a standard full name.
 * @param {string} input 
 * @returns {string}
 */
function normalizeCountry(input) {
  if (!input) return null;
  const trimmed = input.trim();
  const upper = trimmed.toUpperCase();
  
  // Check if it's a known code
  if (countryMap[upper]) {
    return countryMap[upper];
  }
  
  // Otherwise, just return properly cased string (Title Case)
  return trimmed.split(' ').map(word => 
    word.charAt(0).toUpperCase() + word.slice(1).toLowerCase()
  ).join(' ');
}

/**
 * Normalizes a city name.
 * @param {string} input 
 * @returns {string}
 */
function normalizeCity(input) {
  if (!input) return null;
  return input.trim().split(' ').map(word => 
    word.charAt(0).toUpperCase() + word.slice(1).toLowerCase()
  ).join(' ');
}

module.exports = {
  normalizeCountry,
  normalizeCity
};
