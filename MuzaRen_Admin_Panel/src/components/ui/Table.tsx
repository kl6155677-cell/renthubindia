import React from 'react';

export const Table = ({ children, className = '' }: any) => <table className={`table ${className}`}>{children}</table>;
export const Thead = ({ children, className = '' }: any) => <thead className={className}>{children}</thead>;
export const Tbody = ({ children, className = '' }: any) => <tbody className={className}>{children}</tbody>;
export const Tr = ({ children, className = '' }: any) => <tr className={className}>{children}</tr>;
export const Th = ({ children, align = 'left', className = '' }: any) => <th style={{ textAlign: align }} className={className}>{children}</th>;
export const Td = ({ children, align = 'left', colSpan, className = '' }: any) => <td style={{ textAlign: align }} colSpan={colSpan} className={className}>{children}</td>;
