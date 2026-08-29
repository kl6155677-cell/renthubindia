import { useState, useEffect, useCallback } from 'react';

export function useAnalytics(fetchFn, params = {}, deps = []) {
  const [data,      setData]      = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error,     setError]     = useState(null);

  const fetch = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const result = await fetchFn(params);
      setData(result);
    } catch (err) {
      setError(err.response?.data?.error || 'Failed to load data');
    } finally {
      setIsLoading(false);
    }
  }, deps);

  useEffect(() => { fetch(); }, [fetch]);

  return { data, isLoading, error, refetch: fetch };
}
