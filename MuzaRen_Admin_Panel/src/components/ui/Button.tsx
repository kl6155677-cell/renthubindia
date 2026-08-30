import React from 'react';

export const Button = ({ children, variant = 'primary', size = 'md', className = '', ...props }: any) => (
  <button className={`btn btn-${variant} btn-${size} ${className}`} {...props}>
    {children}
  </button>
);
