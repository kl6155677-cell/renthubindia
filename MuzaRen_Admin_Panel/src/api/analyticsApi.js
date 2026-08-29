import axiosClient from './axiosClient';

const BASE = '/api/admin/analytics';

export const analyticsApi = {
  getOverview:   (params) => axiosClient.get(`${BASE}/overview`,   { params }).then(r => r.data.data),
  getUsers:      (params) => axiosClient.get(`${BASE}/users`,      { params }).then(r => r.data.data),
  getListings:   (params) => axiosClient.get(`${BASE}/listings`,   { params }).then(r => r.data.data),
  getBookings:   (params) => axiosClient.get(`${BASE}/bookings`,   { params }).then(r => r.data.data),
  getRevenue:    (params) => axiosClient.get(`${BASE}/revenue`,    { params }).then(r => r.data.data),
  getEngagement: (params) => axiosClient.get(`${BASE}/engagement`, { params }).then(r => r.data.data),
  getGeography:  ()       => axiosClient.get(`${BASE}/geography`).then(r => r.data.data),
  getCategories: ()       => axiosClient.get(`${BASE}/categories`).then(r => r.data.data),
};
