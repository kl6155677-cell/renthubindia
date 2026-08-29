import React from 'react';
import { ChevronLeft, ChevronRight } from 'lucide-react';

interface PaginationProps {
  total: number;
  page: number;
  totalPages: number;
  from: number;
  to: number;
  onPageChange: (page: number) => void;
}

const Pagination: React.FC<PaginationProps> = ({
  total,
  page,
  totalPages,
  from,
  to,
  onPageChange,
}) => {
  if (totalPages <= 1) return null;

  const renderPageNumbers = () => {
    const pages = [];
    const maxVisible = 5;
    
    let startPage = Math.max(1, page - Math.floor(maxVisible / 2));
    let endPage = Math.min(totalPages, startPage + maxVisible - 1);
    
    if (endPage - startPage + 1 < maxVisible) {
      startPage = Math.max(1, endPage - maxVisible + 1);
    }

    for (let i = startPage; i <= endPage; i++) {
      pages.push(
        <button
          key={i}
          className={`pagination-btn ${page === i ? 'active' : ''}`}
          onClick={() => onPageChange(i)}
        >
          {i}
        </button>
      );
    }
    return pages;
  };

  return (
    <div className="pagination-container">
      <div className="pagination-info">
        Showing <b>{from}</b> to <b>{to}</b> of <b>{total}</b> results
      </div>

      <div className="pagination-controls">
        <button
          className="pagination-btn pagination-arrow"
          disabled={page === 1}
          onClick={() => onPageChange(page - 1)}
          title="Previous Page"
        >
          <ChevronLeft size={16} />
          <span>Previous</span>
        </button>

        <div className="pagination-numbers">
          {renderPageNumbers()}
        </div>

        <button
          className="pagination-btn pagination-arrow"
          disabled={page === totalPages}
          onClick={() => onPageChange(page + 1)}
          title="Next Page"
        >
          <span>Next</span>
          <ChevronRight size={16} />
        </button>
      </div>
    </div>
  );
};

export default Pagination;
