import { useSearchParams } from 'react-router-dom';
import { useCallback } from 'react';

interface UsePaginationReturn {
  page: number;
  limit: number;
  setPage: (page: number) => void;
  resetPagination: () => void;
}

/**
 * Hook to manage pagination state via URL search parameters.
 * 
 * @param defaultLimit Default number of items per page (default 50)
 */
export const usePagination = (defaultLimit: number = 50): UsePaginationReturn => {
  const [searchParams, setSearchParams] = useSearchParams();

  const page = Math.max(1, parseInt(searchParams.get('page') || '1', 10));
  const limit = Math.max(1, parseInt(searchParams.get('limit') || String(defaultLimit), 10));

  const setPage = useCallback(
    (newPage: number) => {
      const params = new URLSearchParams(searchParams);
      if (newPage <= 1) {
        params.delete('page');
      } else {
        params.set('page', newPage.toString());
      }
      setSearchParams(params, { replace: true });
    },
    [searchParams, setSearchParams]
  );

  const resetPagination = useCallback(() => {
    const params = new URLSearchParams(searchParams);
    params.delete('page');
    setSearchParams(params, { replace: true });
  }, [searchParams, setSearchParams]);

  return {
    page,
    limit,
    setPage,
    resetPagination,
  };
};
