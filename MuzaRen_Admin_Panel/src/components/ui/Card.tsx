import React from 'react';

export const Card = ({ children, className = '' }: any) => <div className={`card ${className}`}>{children}</div>;
export const CardHeader = ({ children, className = '' }: any) => <div className={`card-header ${className}`}>{children}</div>;
export const CardTitle = ({ children, className = '' }: any) => <h3 className={`card-title ${className}`}>{children}</h3>;
export const CardContent = ({ children, className = '' }: any) => <div className={`card-content ${className}`}>{children}</div>;
