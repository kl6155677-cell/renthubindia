/**
 * Maps standard 2-letter ISO country codes to their corresponding default currencies
 */
const countryToCurrencyMap = {
  US: 'USD',
  IN: 'INR',
  SG: 'SGD',
  MY: 'MYR',
  GB: 'GBP',
  AU: 'AUD',
  CA: 'CAD',
  NZ: 'NZD',
  JP: 'JPY',
  CN: 'CNY',
  AE: 'AED',
  ZA: 'ZAR',
  FR: 'EUR',
  DE: 'EUR',
  IT: 'EUR',
  ES: 'EUR',
  CH: 'CHF',
  // You can extend this mapping as RentHubIndia scales to more regions
};

const getCurrencyFromCountry = (countryCode) => {
  if (!countryCode) return null;
  
  const upperCode = countryCode.toUpperCase();
  return countryToCurrencyMap[upperCode] || 'USD'; // Fallback to USD
};

module.exports = {
  getCurrencyFromCountry,
  countryToCurrencyMap,
};
